import 'dart:async';

import 'models.dart';

export 'models.dart';

/// Sort orders accepted by the f95zone `cmd=list` endpoint.
enum SortOrder { date, likes, views, title, rating }

/// f95zone login credentials: a pasted session cookie string.
class LoginCredentials {
  const LoginCredentials({this.cookie});

  /// Raw session cookie (e.g. `xf_user` + `cf_clearance`).
  final String? cookie;
}

/// One page of the game listing.
class GameListPage {
  const GameListPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });

  final List<Game> items;

  /// 1-based current page.
  final int page;

  /// Total pages (`ceil(totalCount / 30)`).
  final int totalPages;

  /// Total matching threads.
  final int totalCount;
}

/// Port: f95zone metadata source (listings, thread details, tag table, login).
///
/// Implemented by an adapter that wraps `latest_data.php` and the thread pages.
abstract class MetadataSource {
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  });

  Future<ThreadDetail> getThread(int threadId);

  Future<TagTable> getTagTable();

  /// Drops any in-memory caches (listings, tag table) so the next call goes
  /// back to the network. Called by an explicit user refresh.
  void clearCache();

  /// A signal that the source is backing off from an HTTP 429 and will retry.
  ///
  /// Emits `true` when a retry backoff begins and `false` once it completes,
  /// so the list UI can surface a "被限流，正在重试" notice.
  Stream<bool> get throttled;

  /// Logs in with [credentials] and returns the raw session cookie header
  /// value (e.g. `xf_user=...; cf_clearance=...`).
  ///
  /// The cookie is held in memory only and must never be persisted to disk,
  /// the database, or the repository.
  Future<String> login(LoginCredentials credentials);
}

/// Thrown when a [MetadataSource] gives up because HTTP 429 (rate limit)
/// retries were exhausted.
///
/// The transport-specific failure (e.g. dio's) is kept in [cause]. Long
/// operations that can resume later — the index build — catch this signal
/// instead of depending on the HTTP adapter's error type.
class RateLimitedException implements Exception {
  const RateLimitedException([this.cause]);

  /// The underlying transport error, if any.
  final Object? cause;

  @override
  String toString() => 'RateLimitedException: rate limit retries exhausted';
}

/// Port: local library persistence (SQLite in the real adapter).
abstract class LibraryStore {
  // Games
  Future<List<Game>> listGames();
  Future<Game?> getGame(int threadId);
  Future<void> upsertGame(Game game);
  Future<void> removeGame(int threadId);

  // Versions
  Future<List<Version>> listVersions(int threadId);
  Future<void> addVersion(int threadId, Version version);

  // Downloads
  Future<List<Download>> listDownloads();
  Future<Download?> getDownload(String gid);
  Future<void> upsertDownload(Download download);
  Future<void> removeDownload(String gid);

  // Play sessions
  /// Inserts a new session (open until [finishSession]) and returns its id.
  Future<int> addSession(PlaySession session);

  /// Closes [sessionId] at [endedAt], storing the elapsed whole seconds.
  Future<void> finishSession(int sessionId, DateTime endedAt);

  /// The game's sessions, newest first.
  Future<List<PlaySession>> sessionsFor(int threadId);

  /// Summed playtime of all completed sessions of [threadId].
  Future<Duration> totalDuration(int threadId);

  /// Aggregated playtime across every library game.
  Future<LibraryPlaytime> playtime();
}
