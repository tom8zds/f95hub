import 'package:drift/drift.dart';

import '../domain/title_similarity.dart';

part 'library_database.g.dart';

/// A library game row.
///
/// Mirrors the domain [Game] model. `threadId` is the unique key linking back
/// to f95zone metadata; list fields (`screens`/`tags`/`tagIds`/`prefixIds`) are
/// JSON-encoded strings (the app has no need to query inside them).
@DataClassName('GameRow')
class Games extends Table {
  IntColumn get threadId => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get creator => text().withDefault(const Constant(''))();
  TextColumn get version => text().withDefault(const Constant(''))();
  TextColumn get latestVersion => text().withDefault(const Constant(''))();
  TextColumn get cover => text().nullable()();
  TextColumn get screens => text().withDefault(const Constant('[]'))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get tagIds => text().withDefault(const Constant('[]'))();
  TextColumn get prefixIds => text().withDefault(const Constant('[]'))();
  TextColumn get engine => text().withDefault(const Constant(''))();
  TextColumn get developer => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get installPath => text().nullable()();
  TextColumn get launchPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {threadId};
}

/// A download task row, keyed by the aria2 gid.
///
/// Only the columns needed for persistence are modelled here; the download
/// engine's richer life cycle is exercised in ticket 10.
@DataClassName('DownloadRow')
class Downloads extends Table {
  TextColumn get gid => text()();
  IntColumn get threadId => integer()();
  TextColumn get status => text()();
  RealColumn get progress => real()();
  TextColumn get targetDir => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {gid};
}

/// A released version of a game, kept as free text.
@DataClassName('VersionRow')
class Versions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get threadId => integer()();
  TextColumn get value => text()();
  DateTimeColumn get releasedAt => dateTime().nullable()();
}

/// One cached f95zone listing row: the local full-catalogue index (ticket 29).
///
/// Unlike [Games] this mirrors the *remote* listing, so it can be rebuilt from
/// scratch at any time. `normalizedTitle` is the domain title normalizer
/// (`normalizeThreadTitle`) applied at insert time and lower-cased, so local
/// search is a plain `LIKE` scan, and `compactTitle` is that same form with
/// everything but lowercase alphanumerics removed, so a folder name that lost
/// its spaces or gained a date still matches (ticket 56). The list columns hold
/// JSON: `screens` is a list of URLs, `tags`/`prefixes` are numeric f95zone ids
/// (resolvable through the static tag table). `ts` is the listing's Unix-epoch
/// timestamp (the row's last-activity time) and `cachedAt` is when this app
/// wrote the row.
@DataClassName('GameIndexRow')
class GameIndex extends Table {
  IntColumn get threadId => integer()();
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get compactTitle => text().withDefault(const Constant(''))();
  TextColumn get creator => text().withDefault(const Constant(''))();
  TextColumn get latestVersion => text().withDefault(const Constant(''))();
  TextColumn get cover => text().nullable()();
  TextColumn get screens => text().withDefault(const Constant('[]'))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get prefixes => text().withDefault(const Constant('[]'))();
  RealColumn get rating => real().withDefault(const Constant(0))();
  IntColumn get views => integer().withDefault(const Constant(0))();
  IntColumn get likes => integer().withDefault(const Constant(0))();
  IntColumn get ts => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {threadId};
}

/// Key/value bookkeeping for the game index (currently just `lastUpdated`).
@DataClassName('IndexMetaRow')
class IndexMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One recorded play session of a library game (ticket 54).
///
/// A row is inserted when the game process starts; [endedAt] and
/// [durationSeconds] stay null until it exits. Rows are deleted together with
/// their game, so a removed entry never leaves playtime behind.
@DataClassName('PlaySessionRow')
class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get threadId => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
}

/// The drift database backing [DriftLibraryStore] and [GameIndexStore].
@DriftDatabase(tables: [Games, Downloads, Versions, GameIndex, IndexMeta, PlaySessions])
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Every step is guarded by an existence check (ticket 59): an upgrade
        // interrupted part-way can leave columns/tables in place without the
        // `user_version` bump that records them, and an unguarded
        // `ADD COLUMN` / `CREATE TABLE` then throws on the next open, so the
        // database never opens and both the cache and the library look empty.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            if (!await _tableExists(gameIndex.actualTableName)) {
              await m.createTable(gameIndex);
            }
            if (!await _tableExists(indexMeta.actualTableName)) {
              await m.createTable(indexMeta);
            }
          }
          if (from < 3) {
            if (!await _columnExists(
              games.actualTableName,
              games.launchPath.name,
            )) {
              await m.addColumn(games, games.launchPath);
            }
            if (!await _tableExists(playSessions.actualTableName)) {
              await m.createTable(playSessions);
            }
          }
          if (from < 4) {
            if (!await _tableExists(gameIndex.actualTableName)) {
              await m.createTable(gameIndex);
            }
            if (!await _columnExists(
              gameIndex.actualTableName,
              gameIndex.compactTitle.name,
            )) {
              await m.addColumn(gameIndex, gameIndex.compactTitle);
            }
          }

          // Recomputing the compact form is idempotent, and every cached row
          // needs it derived from the stored title — including rows whose
          // column was added by an upgrade that never got to backfill them.
          // Skipped only when there is no cache table to fill.
          if (await _tableExists(gameIndex.actualTableName) &&
              await _columnExists(
                gameIndex.actualTableName,
                gameIndex.compactTitle.name,
              )) {
            await _backfillCompactTitles();
          }
        },
      );

  /// Whether [name] is a table in the current schema.
  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Whether [table] currently has a column named [column].
  Future<bool> _columnExists(String table, String column) async {
    // A PRAGMA target cannot be a bound variable; both arguments come from
    // generated table metadata, never from user input.
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((row) => row.read<String>('name') == column);
  }


  /// Fills `compactTitle` for rows written before the column existed (ticket
  /// 56). One `UPDATE` per row: the compaction is Dart logic (Unicode aware),
  /// not something SQLite can express, and the index is a cache — a slow first
  /// open after the upgrade is acceptable for correctness.
  Future<void> _backfillCompactTitles() async {
    final rows = await customSelect(
      'SELECT thread_id, title FROM game_index',
    ).get();
    for (final row in rows) {
      await customStatement(
        'UPDATE game_index SET compact_title = ? WHERE thread_id = ?',
        [compactTitle(row.read<String>('title')), row.read<int>('thread_id')],
      );
    }
  }
}
