import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';

import 'support/fake_metadata_source.dart';

/// Regression tests for ticket 43: the catalogue build resume point must
/// survive an application restart, i.e. closing and reopening the *same*
/// file-backed database (the app keeps it in
/// `getApplicationSupportDirectory()/f95hub.db`). Unlike the in-memory tests
/// in `game_index_store_test.dart`, these go through real SQLite storage, so a
/// missing commit, an unsafe write order or a migration that drops
/// `IndexMeta` would be caught here.
void main() {
  late Directory dir;
  late File dbFile;
  final now = DateTime(2026, 10, 21);

  setUp(() {
    // Reopening the same file necessarily instantiates the drift class twice;
    // that is exactly what a restart looks like.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('f95hub_restart_');
    dbFile = File(p.join(dir.path, 'f95hub.db'));
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  /// Opens a fresh connection to the file and registers its close, so a
  /// failing expectation can never leave a lock behind (Windows refuses to
  /// delete an open database file).
  LibraryDatabase open() {
    final db = LibraryDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);
    return db;
  }

  List<Game> manyGames(int count) => List.generate(
        count,
        (i) => makeGame(
          i + 1,
          title: 'Game ${i + 1}',
          updatedAt: DateTime(2026, 10, 20),
        ),
      );

  test('resume point and cached rows survive closing and reopening the db',
      () async {
    final games = manyGames(95); // 4 pages of 30
    final firstDb = open();
    final firstSource = FakeMetadataSource(games, pageSize: 30)
      ..rateLimitedPages.add(3);

    // First launch: page 3 is rate-limited, so the build stops after page 2.
    final firstStore = GameIndexStore(firstDb, firstSource, clock: () => now);
    final firstCount = await firstStore.buildAll();

    expect(firstCount, 60);
    expect(await firstStore.lastBuiltPage(), 2);
    expect(await firstStore.totalPages(), 4);
    expect(await firstStore.lastUpdated(), isNull);

    // Closing is what the app's provider does on dispose; nothing else is
    // allowed to flush the state afterwards.
    await firstDb.close();
    expect(dbFile.existsSync(), isTrue);

    // Second launch: a brand-new connection to the same file.
    final secondDb = open();
    final secondSource = FakeMetadataSource(games, pageSize: 30);
    final secondStore =
        GameIndexStore(secondDb, secondSource, clock: () => now);

    expect(await secondStore.lastBuiltPage(), 2);
    expect(await secondStore.totalPages(), 4);
    expect(await secondStore.count(), 60);
    expect(await secondStore.lastUpdated(), isNull);

    // Pages 1-2 are on disk (games 1..60), page 3 (games 61..90) is not: the
    // run stopped before reaching it.
    expect((await secondStore.search('Game 30')).single.threadId, 30);
    expect((await secondStore.search('Game 60')).single.threadId, 60);
    expect(await secondStore.search('Game 61'), isEmpty);

    // Changing the source for an already-written page proves the resumed run
    // does not rewrite stored pages: page 1 is only fetched for its
    // `totalPages`, then the walk continues from `lastBuiltPage + 1`.
    games[0] = makeGame(
      1,
      title: 'Game 1 (changed)',
      updatedAt: DateTime(2026, 10, 20),
    );

    final resumedCount = await secondStore.buildAll();

    expect(resumedCount, 95);
    expect(secondSource.requestedPages, [1, 3, 4]);
    expect(await secondStore.lastBuiltPage(), 4);
    expect(await secondStore.totalPages(), 4);
    expect(await secondStore.lastUpdated(), now);
    final storedFirst = await (secondDb.select(secondDb.gameIndex)
          ..where((t) => t.threadId.equals(1)))
        .getSingle();
    expect(
      storedFirst.title,
      'Game 1',
      reason: 'the resumed run must not rewrite the already-built page 1',
    );
    expect(await secondStore.search('Game 95'), isNotEmpty);

    await secondDb.close();
  });

  test('a completed build stays complete across a restart', () async {
    final games = manyGames(65); // 3 pages
    final firstDb = open();
    final firstStore = GameIndexStore(
      firstDb,
      FakeMetadataSource(games, pageSize: 30),
      clock: () => now,
    );
    expect(await firstStore.buildAll(), 65);
    expect(await firstStore.lastBuiltPage(), 3);
    expect(await firstStore.lastUpdated(), now);
    await firstDb.close();

    final secondDb = open();
    final secondSource = FakeMetadataSource(games, pageSize: 30);
    final secondStore =
        GameIndexStore(secondDb, secondSource, clock: () => now);

    expect(await secondStore.lastBuiltPage(), 3);
    expect(await secondStore.totalPages(), 3);
    expect(await secondStore.lastUpdated(), now);

    // A re-run after restart only probes page 1 for the total and writes
    // nothing: the cache is already complete.
    final progress = <String>[];
    expect(
      await secondStore.buildAll(
        onProgress: (page, total, count) => progress.add('$page/$total'),
      ),
      65,
    );
    expect(secondSource.requestedPages, [1]);
    expect(progress, ['3/3']);
    expect(await secondStore.lastBuiltPage(), 3);

    await secondDb.close();
  });

  test('clear() resets the resume point for the next launch', () async {
    final games = manyGames(65);
    final firstDb = open();
    final firstStore = GameIndexStore(
      firstDb,
      FakeMetadataSource(games, pageSize: 30),
      clock: () => now,
    );
    await firstStore.buildAll();
    await firstStore.clear();
    await firstDb.close();

    final secondDb = open();
    final secondStore = GameIndexStore(
      secondDb,
      FakeMetadataSource(games, pageSize: 30),
      clock: () => now,
    );
    expect(await secondStore.lastBuiltPage(), 0);
    expect(await secondStore.totalPages(), 0);
    expect(await secondStore.count(), 0);

    await secondDb.close();
  });

  test('upgrading from schema 3 backfills compactTitle on cached rows',
      () async {
    final firstDb = open();
    final firstStore = GameIndexStore(
      firstDb,
      FakeMetadataSource([makeGame(1, title: 'Devoted Wife')]),
      clock: () => now,
    );
    await firstStore.buildAll();

    // Rewind the file to the pre-ticket-56 shape: the column is gone and
    // drift migrates 3 → 4 the next time the file is opened.
    await firstDb.customStatement(
      'ALTER TABLE game_index DROP COLUMN compact_title',
    );
    await firstDb.customStatement('PRAGMA user_version = 3');
    await firstDb.close();

    final secondDb = open();
    final secondStore = GameIndexStore(
      secondDb,
      FakeMetadataSource(const []),
      clock: () => now,
    );

    final row = await secondDb.select(secondDb.gameIndex).getSingle();
    expect(row.compactTitle, 'devotedwife');
    // A spaceless folder name only matches through the compact column, so a
    // hit here proves the backfill reached the existing row.
    expect(
      (await secondStore.search('DevotedWife')).map((r) => r.threadId),
      [1],
    );

    await secondDb.close();
  });
}
