import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/title_similarity.dart';

import 'support/fake_metadata_source.dart';

/// Regression tests for ticket 59: opening a database whose *structure* is
/// already at the latest shape but whose `user_version` is stale (a partial
/// upgrade added columns/tables without bumping the version) used to throw
/// "duplicate column name" inside `onUpgrade`, so the database never opened and
/// both the cached index and the library looked empty.
///
/// Every upgrade path is exercised against a real file, because the failure is
/// a SQLite error, not something a memory database would hide differently.
void main() {
  late Directory dir;
  late File dbFile;
  final now = DateTime(2026, 10, 25);

  setUp(() {
    // Each test deliberately reopens the same file with a fresh instance.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('f95hub_migration_');
    dbFile = File(p.join(dir.path, 'f95hub.db'));
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  LibraryDatabase open() {
    final db = LibraryDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);
    return db;
  }

  Future<int> userVersion(LibraryDatabase db) async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }

  Future<Set<String>> tableNames(LibraryDatabase db) async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  Future<Set<String>> columnNames(LibraryDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  /// Seeds the *current* (schema 4) shape with two library games and three
  /// cached listing rows, then closes the file.
  ///
  /// Older shapes are produced by [rewind], which undoes individual steps —
  /// exactly the kind of partial upgrade that leaves a database stranded at an
  /// old `user_version`. [staleCompact] simulates rows written before the
  /// column was introduced (or before its backfill ran), so the upgrade's
  /// backfill has something to repair.
  Future<void> seed({bool staleCompact = false}) async {
    final db = open();
    final store = DriftLibraryStore(db);
    for (final id in [1, 2]) {
      await store.upsertGame(makeGame(id, title: 'Library $id'));
    }

    const cache = <(int, String)>[
      (1, 'Devoted Wife'),
      (2, 'Another Game'),
      (3, 'Third Entry'),
    ];
    for (final (threadId, title) in cache) {
      await db.into(db.gameIndex).insert(
            GameIndexCompanion.insert(
              threadId: Value(threadId),
              title: title,
              normalizedTitle: title.toLowerCase(),
              compactTitle:
                  Value(staleCompact ? '' : compactTitle(title)),
              cachedAt: now,
            ),
          );
    }
    await db.close();
  }

  /// Applies [statements] to the seeded file and forces `user_version` to
  /// [version], leaving the disk in the shape a broken install has.
  Future<void> rewind(int version, List<String> statements) async {
    final db = open();
    await db.customSelect('SELECT 1').get();
    for (final sql in statements) {
      await db.customStatement(sql);
    }
    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
  }

  /// Asserts the data survived and the compact form is filled for every row.
  Future<void> expectIntact(LibraryDatabase db) async {
    expect(await userVersion(db), 4);
    expect(await DriftLibraryStore(db).listGames(), hasLength(2));

    final rows = await db.select(db.gameIndex).get();
    expect(rows, hasLength(3));
    for (final row in rows) {
      expect(
        row.compactTitle,
        compactTitle(row.title),
        reason: 'the backfill must reach every cached row',
      );
    }

    // The whole point of the repair: a spaceless folder name still matches.
    final index = GameIndexStore(db, FakeMetadataSource(const []));
    expect(
      (await index.search('DevotedWife')).map((r) => r.threadId),
      [1],
    );
  }

  test('structure present but user_version 2: opens, keeps data, backfills',
      () async {
    await seed(staleCompact: true);
    // Nothing to undo: the previous partial upgrade already added every
    // column and table, it just never bumped the version.
    await rewind(2, const []);

    final db = open();
    // Opening is lazy; the first query is what runs onUpgrade.
    await db.customSelect('SELECT 1').get();

    await expectIntact(db);

    // Opening again must stay a no-op (the file is now at version 4).
    await db.close();
    final reopened = open();
    await expectIntact(reopened);
  });

  test('upgrading from schema 2 adds the missing column and table', () async {
    await seed(staleCompact: true);
    await rewind(2, const [
      'ALTER TABLE game_index DROP COLUMN compact_title',
      'ALTER TABLE games DROP COLUMN launch_path',
      'DROP TABLE play_sessions',
    ]);

    final db = open();
    await db.customSelect('SELECT 1').get();

    expect(await tableNames(db), contains('play_sessions'));
    expect(await columnNames(db, 'games'), contains('launch_path'));
    expect(await columnNames(db, 'game_index'), contains('compact_title'));
    await expectIntact(db);
  });

  test('upgrading from schema 1 creates the index tables and backfills',
      () async {
    await seed();
    await rewind(1, const [
      'DROP TABLE game_index',
      'DROP TABLE index_meta',
      'DROP TABLE play_sessions',
      'ALTER TABLE games DROP COLUMN launch_path',
    ]);

    final db = open();
    await db.customSelect('SELECT 1').get();

    expect(
      await tableNames(db),
      containsAll(['game_index', 'index_meta', 'play_sessions']),
    );
    expect(await columnNames(db, 'games'), contains('launch_path'));
    expect(await columnNames(db, 'game_index'), contains('compact_title'));
    expect(await userVersion(db), 4);
    // The library games predate the migration and must still be there; the
    // cache was dropped with its table, so only the new empty index remains.
    expect(await DriftLibraryStore(db).listGames(), hasLength(2));
    expect(await db.select(db.gameIndex).get(), isEmpty);
  });

  test('upgrading from schema 3 backfills compact titles', () async {
    await seed(staleCompact: true);
    await rewind(3, const [
      'ALTER TABLE game_index DROP COLUMN compact_title',
    ]);

    final db = open();
    await db.customSelect('SELECT 1').get();

    await expectIntact(db);
  });

  test('an already migrated database opens and stays at version 4', () async {
    await seed();

    final db = open();
    await db.customSelect('SELECT 1').get();

    await expectIntact(db);
  });
}
