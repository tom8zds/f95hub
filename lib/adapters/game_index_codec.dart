import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'library_database.dart';

/// A full game-index snapshot: every [GameIndexRow] of a built cache plus the
/// bookkeeping needed to make a seeded index look "complete" (pages + the
/// moment the snapshot was taken).
class GameIndexSnapshot {
  const GameIndexSnapshot({
    required this.rows,
    required this.snapshotAt,
    required this.totalPages,
  });

  final List<GameIndexRow> rows;

  /// When the source cache was last fully updated — becomes the seeded
  /// index's `lastUpdated`.
  final DateTime snapshotAt;

  /// Total catalogue pages the source build saw.
  final int totalPages;
}

/// The on-disk format version of the encoded snapshot. Bump when the row
/// layout changes; [decodeGameIndexSnapshot] rejects other versions.
const int kGameIndexSnapshotFormatVersion = 1;

/// Encodes [snapshot] as a gzipped JSON document.
///
/// Rows are positional arrays (not objects) to keep the bundle small: with a
/// full catalogue the object keys would dominate the file.
Uint8List encodeGameIndexSnapshot(GameIndexSnapshot snapshot) {
  final dynamic data = <String, dynamic>{
    'v': kGameIndexSnapshotFormatVersion,
    'ts': snapshot.snapshotAt.toIso8601String(),
    'pages': snapshot.totalPages,
    'rows': [
      for (final row in snapshot.rows)
        <dynamic>[
          row.threadId,
          row.title,
          row.normalizedTitle,
          row.compactTitle,
          row.creator,
          row.latestVersion,
          row.cover ?? '',
          row.screens,
          row.tags,
          row.prefixes,
          row.rating,
          row.views,
          row.likes,
          row.ts,
          row.cachedAt.toIso8601String(),
        ],
    ],
  };
  return Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(data))));
}

/// Decodes a snapshot produced by [encodeGameIndexSnapshot].
///
/// Throws [FormatException] on an unknown format version.
GameIndexSnapshot decodeGameIndexSnapshot(List<int> bytes) {
  final dynamic data = jsonDecode(utf8.decode(gzip.decode(bytes)));
  final version = data['v'] as int?;
  if (version != kGameIndexSnapshotFormatVersion) {
    throw FormatException('Unknown game-index snapshot version: $version');
  }
  final rawRows = data['rows'] as List<dynamic>;
  return GameIndexSnapshot(
    snapshotAt: DateTime.parse(data['ts'] as String),
    totalPages: data['pages'] as int? ?? 0,
    rows: [
      for (final dynamic raw in rawRows)
        GameIndexRow(
          threadId: raw[0] as int,
          title: raw[1] as String,
          normalizedTitle: raw[2] as String,
          compactTitle: raw[3] as String? ?? '',
          creator: raw[4] as String? ?? '',
          latestVersion: raw[5] as String? ?? '',
          cover: (raw[6] as String).isEmpty ? null : raw[6] as String?,
          screens: raw[7] as String? ?? '[]',
          tags: raw[8] as String? ?? '[]',
          prefixes: raw[9] as String? ?? '[]',
          rating: (raw[10] as num?)?.toDouble() ?? 0,
          views: raw[11] as int? ?? 0,
          likes: raw[12] as int? ?? 0,
          ts: raw[13] as int? ?? 0,
          cachedAt: DateTime.parse(raw[14] as String),
        ),
    ],
  );
}
