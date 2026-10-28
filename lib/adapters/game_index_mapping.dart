import 'dart:convert';

import '../domain/models.dart';
import 'library_database.dart';

/// Rebuilds the listing-shaped [Game] from a cached [GameIndexRow].
///
/// The index stores the same listing fields the online source returns (plus a
/// normalized title for searching); this is the inverse of the encoding
/// `GameIndexStore` performs on upsert. Callers need a [Game] because the
/// import flow hands the selection to `scrapeAndStore`, which fetches the
/// thread/tag table online for whatever fields the listing does not carry.
///
/// Malformed JSON in a cached row degrades to an empty list rather than
/// failing the whole search.
Game gameFromIndexRow(GameIndexRow row) {
  final updatedAt = DateTime.fromMillisecondsSinceEpoch(row.ts * 1000);
  return Game(
    threadId: row.threadId,
    title: row.title,
    creator: row.creator,
    latestVersion: row.latestVersion,
    cover: row.cover,
    screens: _strings(row.screens),
    tagIds: _ints(row.tags),
    prefixIds: _ints(row.prefixes),
    rating: row.rating,
    views: row.views,
    likes: row.likes,
    // The index only keeps the listing `ts`; both timestamps drive nothing but
    // ordering here, so the same value is good enough for both.
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

List<String> _strings(String encoded) {
  final decoded = _decode(encoded);
  return [
    for (final value in decoded)
      if (value is String) value,
  ];
}

List<int> _ints(String encoded) {
  final decoded = _decode(encoded);
  return [
    for (final value in decoded)
      if (value is int) value,
  ];
}

List<Object?> _decode(String encoded) {
  try {
    final decoded = jsonDecode(encoded);
    return decoded is List ? decoded : const [];
  } on FormatException {
    return const [];
  }
}
