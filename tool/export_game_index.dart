// Exports the game-index cache from a f95hub database into the bundled
// snapshot asset (`assets/game_index.json.gz`), so fresh installs can seed
// their empty cache instead of crawling the whole catalogue.
//
// Usage (from the repo root):
//   fvm dart run tool:export_game_index
//   fvm dart run tool:export_game_index --db <path-to-f95hub.db> --out <file>
//
// Defaults: db = %APPDATA%/com.example/f95hub/f95hub.db (the app's live
// database, copied to a temp file first so a running app is never touched),
// out = assets/game_index.json.gz.
//
// Regenerate after schema changes bump kGameIndexSnapshotFormatVersion.
//
// CLI status output is the tool's product, so print() is fine here.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:drift/native.dart';
import 'package:f95hub/adapters/game_index_codec.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final dbPath = _option(args, 'db') ??
      p.join(
        Platform.environment['APPDATA'] ?? '',
        'com.example',
        'f95hub',
        'f95hub.db',
      );
  final outPath =
      _option(args, 'out') ?? p.join('assets', 'game_index.json.gz');

  final source = File(dbPath);
  if (!source.existsSync()) {
    stderr.writeln('database not found: $dbPath');
    exitCode = 2;
    return;
  }

  // Copy the db (plus its WAL/SHM siblings) so a running app keeps working
  // and we read a consistent checkpointed view.
  final tempDir = await Directory.systemTemp.createTemp('f95hub-export');
  final copyPath = p.join(tempDir.path, 'f95hub.db');
  await source.copy(copyPath);
  for (final suffix in ['-wal', '-shm']) {
    final side = File('$dbPath$suffix');
    if (side.existsSync()) {
      await side.copy('$copyPath$suffix');
    }
  }

  final db = LibraryDatabase(NativeDatabase.createInBackground(File(copyPath)));
  try {
    final rows = await db.select(db.gameIndex).get();
    final meta = {
      for (final row in await db.select(db.indexMeta).get()) row.key: row.value,
    };
    final totalPages = int.tryParse(meta['totalPages'] ?? '') ?? 0;
    final lastUpdatedSeconds = int.tryParse(meta['lastUpdated'] ?? '');
    final snapshotAt = lastUpdatedSeconds == null
        ? source.lastModifiedSync()
        : DateTime.fromMillisecondsSinceEpoch(lastUpdatedSeconds * 1000);

    final snapshot = GameIndexSnapshot(
      rows: rows,
      snapshotAt: snapshotAt,
      totalPages: totalPages,
    );
    final bytes = encodeGameIndexSnapshot(snapshot);

    final outFile = File(outPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(bytes, flush: true);

    // A sanity echo of what landed in the asset.
    final decoded = decodeGameIndexSnapshot(bytes);
    print('rows: ${decoded.rows.length}');
    print('totalPages: ${decoded.totalPages}');
    print('snapshotAt: ${decoded.snapshotAt.toIso8601String()}');
    print('file: $outPath (${bytes.length} bytes)');
  } finally {
    await db.close();
    // Best effort: leaving a temp dir behind is harmless.
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }
}

String? _option(List<String> args, String name) {
  for (var i = 0; i + 1 < args.length; i++) {
    if (args[i] == '--$name') {
      return args[i + 1];
    }
  }
  return null;
}
