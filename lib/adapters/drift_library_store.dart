import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/ports.dart';
import 'library_database.dart';

/// [LibraryStore] backed by drift/SQLite.
///
/// The real adapter opens a file-backed database; tests inject
/// `LibraryDatabase(NativeDatabase.memory())` directly (see
/// `test/library_store_test.dart`) so no fake store is ever needed.
class DriftLibraryStore implements LibraryStore {
  DriftLibraryStore(this._db);

  final LibraryDatabase _db;

  @override
  Future<List<Game>> listGames() async {
    final rows = await _db.select(_db.games).get();
    return rows.map(_gameFromRow).toList(growable: false);
  }

  @override
  Future<Game?> getGame(int threadId) async {
    final row = await (_db.select(_db.games)
          ..where((g) => g.threadId.equals(threadId)))
        .getSingleOrNull();
    return row == null ? null : _gameFromRow(row);
  }

  @override
  Future<void> upsertGame(Game game) async {
    await _db.into(_db.games).insertOnConflictUpdate(
      GamesCompanion(
        threadId: Value(game.threadId),
        title: Value(game.title),
        creator: Value(game.creator),
        version: Value(game.version),
        latestVersion: Value(game.latestVersion),
        cover: Value(game.cover),
        screens: Value(_encode(game.screens)),
        tags: Value(_encode(game.tags)),
        tagIds: Value(_encode(game.tagIds)),
        prefixIds: Value(_encode(game.prefixIds)),
        engine: Value(game.engine),
        developer: Value(game.developer),
        description: Value(game.description),
        installPath: Value(game.installPath),
        launchPath: Value(game.launchPath),
        createdAt: Value(game.createdAt),
        updatedAt: Value(game.updatedAt),
      ),
    );
  }

  @override
  Future<void> removeGame(int threadId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.playSessions)
            ..where((s) => s.threadId.equals(threadId)))
          .go();
      await (_db.delete(_db.games)
            ..where((g) => g.threadId.equals(threadId)))
          .go();
    });
  }

  @override
  Future<int> addSession(PlaySession session) async {
    return _db.into(_db.playSessions).insert(
          PlaySessionsCompanion.insert(
            threadId: session.threadId,
            startedAt: session.startedAt,
            endedAt: Value(session.endedAt),
            durationSeconds: Value(session.durationSeconds),
          ),
        );
  }

  @override
  Future<void> finishSession(int sessionId, DateTime endedAt) async {
    final row = await (_db.select(_db.playSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
    if (row == null || row.endedAt != null) {
      return;
    }
    var seconds = endedAt.difference(row.startedAt).inSeconds;
    if (seconds < 0) {
      seconds = 0;
    }
    await (_db.update(_db.playSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
          PlaySessionsCompanion(
            endedAt: Value(endedAt),
            durationSeconds: Value(seconds),
          ),
        );
  }

  @override
  Future<List<PlaySession>> sessionsFor(int threadId) async {
    final rows = await (_db.select(_db.playSessions)
          ..where((s) => s.threadId.equals(threadId))
          ..orderBy([
            (s) => OrderingTerm.desc(s.startedAt),
            (s) => OrderingTerm.desc(s.id),
          ]))
        .get();
    return rows.map(_sessionFromRow).toList(growable: false);
  }

  @override
  Future<Duration> totalDuration(int threadId) async {
    final rows = await (_db.select(_db.playSessions)
          ..where((s) => s.threadId.equals(threadId)))
        .get();
    var seconds = 0;
    for (final row in rows) {
      seconds += row.durationSeconds ?? 0;
    }
    return Duration(seconds: seconds);
  }

  @override
  Future<LibraryPlaytime> playtime() async {
    final rows = await _db.select(_db.playSessions).get();
    var seconds = 0;
    final games = <int>{};
    for (final row in rows) {
      seconds += row.durationSeconds ?? 0;
      games.add(row.threadId);
    }
    return LibraryPlaytime(
      total: Duration(seconds: seconds),
      gamesPlayed: games.length,
    );
  }

  @override
  Future<List<Version>> listVersions(int threadId) async {
    final rows = await (_db.select(_db.versions)
          ..where((v) => v.threadId.equals(threadId))
          ..orderBy([(v) => OrderingTerm.asc(v.id)]))
        .get();
    return rows
        .map(
          (v) => Version(value: v.value, releasedAt: v.releasedAt),
        )
        .toList(growable: false);
  }

  @override
  Future<void> addVersion(int threadId, Version version) async {
    await _db.into(_db.versions).insert(
      VersionsCompanion(
        threadId: Value(threadId),
        value: Value(version.value),
        releasedAt: Value(version.releasedAt),
      ),
    );
  }

  @override
  Future<List<Download>> listDownloads() async {
    final rows = await _db.select(_db.downloads).get();
    return rows.map(_downloadFromRow).toList(growable: false);
  }

  @override
  Future<Download?> getDownload(String gid) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) => d.gid.equals(gid)))
        .getSingleOrNull();
    return row == null ? null : _downloadFromRow(row);
  }

  @override
  Future<void> upsertDownload(Download download) async {
    await _db.into(_db.downloads).insertOnConflictUpdate(
      DownloadsCompanion(
        gid: Value(download.gid),
        threadId: Value(download.threadId),
        status: Value(download.status.name),
        progress: Value(download.progress),
        targetDir: Value(download.targetDir),
        createdAt: Value(download.createdAt),
        updatedAt: Value(download.updatedAt),
      ),
    );
  }

  @override
  Future<void> removeDownload(String gid) async {
    await (_db.delete(_db.downloads)..where((d) => d.gid.equals(gid))).go();
  }

  Game _gameFromRow(GameRow row) => Game(
        threadId: row.threadId,
        title: row.title,
        creator: row.creator,
        version: row.version,
        latestVersion: row.latestVersion,
        cover: row.cover,
        screens: _decodeStrings(row.screens),
        tags: _decodeStrings(row.tags),
        tagIds: _decodeInts(row.tagIds),
        prefixIds: _decodeInts(row.prefixIds),
        engine: row.engine,
        developer: row.developer,
        description: row.description,
        installPath: row.installPath,
        launchPath: row.launchPath,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  PlaySession _sessionFromRow(PlaySessionRow row) => PlaySession(
        id: row.id,
        threadId: row.threadId,
        startedAt: row.startedAt,
        endedAt: row.endedAt,
        durationSeconds: row.durationSeconds,
      );

  Download _downloadFromRow(DownloadRow row) => Download(
        gid: row.gid,
        threadId: row.threadId,
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == row.status,
          orElse: () => DownloadStatus.error,
        ),
        progress: row.progress,
        targetDir: row.targetDir,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static String _encode(List<Object?> values) => jsonEncode(values);

  static List<String> _decodeStrings(String raw) =>
      (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .toList(growable: false);

  static List<int> _decodeInts(String raw) => (jsonDecode(raw) as List<dynamic>)
      .whereType<num>()
      .map((e) => e.toInt())
      .toList(growable: false);
}
