import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../domain/ports.dart';
import '../domain/title_similarity.dart';
import 'game_index_codec.dart';
import 'library_database.dart';

/// Progress sink for the long catalogue operations: the page just written, the
/// total number of pages this run will visit, and the number of rows cached
/// after that page landed.
typedef GameIndexProgress = void Function(int page, int total, int count);

/// Returns true once the caller wants the running operation to stop.
typedef GameIndexCancelCheck = bool Function();

/// Thrown internally when the [GameIndexStore] cancel signal wins the race
/// with an in-flight request. The public build/refresh methods swallow it and
/// stop the run, so callers never see it.
class BuildCancelled implements Exception {
  const BuildCancelled();

  @override
  String toString() => 'BuildCancelled';
}

/// The local, searchable index of the f95zone *listing* (ticket 29).
///
/// Unlike the user's library this is a cache of the whole catalogue: it can be
/// rebuilt from scratch, refreshed page-by-page by recency, cleared, and
/// searched offline. Rows live in [GameIndex]; bookkeeping (the last refresh
/// time) lives in [IndexMeta].
class GameIndexStore {
  GameIndexStore(
    this._db,
    this._source, {
    this.incrementalPages = 10,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LibraryDatabase _db;
  final MetadataSource _source;

  /// How many newest pages a incremental refresh walks (1 page = 30 games).
  final int incrementalPages;

  /// Injectable wall clock, so tests can pin `cachedAt`/`lastUpdated`.
  final DateTime Function() _clock;

  static const _lastUpdatedKey = 'lastUpdated';
  static const _lastBuiltPageKey = 'lastBuiltPage';
  static const _totalPagesKey = 'totalPages';

  /// Pages through the whole catalogue in title order and upserts every row.
  ///
  /// Resumable: the last fully written page and the total page count live in
  /// [IndexMeta], so a run that was cancelled or rate-limited continues from
  /// `lastBuiltPage + 1` instead of starting over. Page 1 is always fetched
  /// (its response carries `totalPages`), but only written when no earlier
  /// page has been stored yet.
  ///
  /// [onProgress] fires after each page lands with the last written page
  /// (1-based), the current total and the rows cached so far; [isCancelled] is
  /// polled before fetching the next page, and [cancelSignal] aborts even an
  /// in-flight request: completing it wins the race against `listGames` and the
  /// run stops immediately.
  ///
  /// A [RateLimitedException] (429 retries exhausted) stops the run
  /// gracefully: progress is kept and the current row count is returned
  /// instead of throwing, so the caller can resume later. Other errors
  /// propagate. `lastUpdated` is only recorded when every page was written.
  Future<int> buildAll({
    GameIndexProgress? onProgress,
    GameIndexCancelCheck? isCancelled,
    Future<void>? cancelSignal,
  }) async {
    final resumeFrom = await lastBuiltPage();
    final GameListPage first;
    try {
      first = await _raceCancel(
        _source.listGames(GameCategory.games, sort: SortOrder.title),
        cancelSignal,
      );
    } on RateLimitedException {
      return count();
    } on BuildCancelled {
      return count();
    }

    final total = max(first.totalPages, 1);
    await _setMeta(_totalPagesKey, '$total');

    var written = resumeFrom;
    if (resumeFrom < 1) {
      await _upsert(first.items);
      written = 1;
      await _setMeta(_lastBuiltPageKey, '1');
    }
    onProgress?.call(written, total, await count());

    var interrupted = false;
    for (var page = written + 1; page <= total; page++) {
      if (isCancelled?.call() ?? false) {
        interrupted = true;
        break;
      }
      final GameListPage data;
      try {
        data = await _raceCancel(
          _source.listGames(
            GameCategory.games,
            sort: SortOrder.title,
            page: page,
          ),
          cancelSignal,
        );
      } on RateLimitedException {
        interrupted = true;
        break;
      } on BuildCancelled {
        interrupted = true;
        break;
      }
      await _upsert(data.items);
      written = page;
      await _setMeta(_lastBuiltPageKey, '$page');
      onProgress?.call(page, total, await count());
    }

    if (!interrupted) {
      await _setMeta(_lastBuiltPageKey, '$total');
      await _setLastUpdated(_clock());
    }
    return count();
  }

  /// Bulk-inserts a bundled [GameIndexSnapshot] into an empty index, marking
  /// the build complete as of the snapshot's time over its page count.
  ///
  /// Fresh installs seed from the snapshot shipped inside the app this way —
  /// the alternative is crawling every catalogue page before the cache is
  /// usable. A non-empty index is left untouched (the user's own cache always
  /// wins), and afterwards `refreshIncremental` catches up as usual. Returns
  /// the row count after seeding.
  Future<int> seed(GameIndexSnapshot snapshot) async {
    if (await count() > 0 || snapshot.rows.isEmpty) {
      return count();
    }
    const chunkSize = 1000;
    for (var start = 0; start < snapshot.rows.length; start += chunkSize) {
      final end = min(start + chunkSize, snapshot.rows.length);
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.gameIndex,
          [
            for (final row in snapshot.rows.sublist(start, end))
              GameIndexCompanion(
                threadId: Value(row.threadId),
                title: Value(row.title),
                normalizedTitle: Value(row.normalizedTitle),
                compactTitle: Value(row.compactTitle),
                creator: Value(row.creator),
                latestVersion: Value(row.latestVersion),
                cover: Value(row.cover),
                screens: Value(row.screens),
                tags: Value(row.tags),
                prefixes: Value(row.prefixes),
                rating: Value(row.rating),
                views: Value(row.views),
                likes: Value(row.likes),
                ts: Value(row.ts),
                cachedAt: Value(row.cachedAt),
              ),
          ],
        );
      });
    }
    await _setMeta(_totalPagesKey, '${snapshot.totalPages}');
    await _setMeta(_lastBuiltPageKey, '${snapshot.totalPages}');
    await _setLastUpdated(snapshot.snapshotAt);
    return count();
  }

  /// Walks the [incrementalPages] newest pages (date order) and upserts the
  /// rows that are newer than what the index already holds.
  ///
  /// A row is written when it is missing locally or its listing `ts` is newer
  /// than the stored `ts` *and* newer than `lastUpdated` — the latter keeps a
  /// refresh from rewriting rows a previous full build already has. Returns
  /// the number of rows written; records `lastUpdated` unless cancelled.
  /// [cancelSignal] aborts an in-flight request immediately.
  Future<int> refreshIncremental({
    GameIndexProgress? onProgress,
    GameIndexCancelCheck? isCancelled,
    Future<void>? cancelSignal,
  }) async {
    final lastUpdated = await this.lastUpdated();
    var written = 0;
    var total = incrementalPages;
    var cancelled = false;

    for (var page = 1; page <= total; page++) {
      if (page > 1 && (isCancelled?.call() ?? false)) {
        cancelled = true;
        break;
      }
      final GameListPage data;
      try {
        data = await _raceCancel(
          _source.listGames(
            GameCategory.games,
            sort: SortOrder.date,
            page: page,
          ),
          cancelSignal,
        );
      } on BuildCancelled {
        cancelled = true;
        break;
      }
      total = min(incrementalPages, max(data.totalPages, 1));
      written += await _mergeNewer(data.items, lastUpdated);
      onProgress?.call(page, total, await count());
      if (page == total) {
        break;
      }
    }

    if (!cancelled) {
      await _setLastUpdated(_clock());
    }
    return written;
  }

  /// Empties the index and forgets `lastUpdated` plus the build resume point.
  ///
  /// Rows and bookkeeping are removed in one transaction. A crash between the
  /// two deletes would otherwise leave `lastBuiltPage` pointing at pages that
  /// no longer exist, and the next build would skip them as already cached —
  /// a "complete" cache that is silently empty.
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.gameIndex).go();
      await (_db.delete(_db.indexMeta)
            ..where((m) => m.key.isIn(const [
                  _lastUpdatedKey,
                  _lastBuiltPageKey,
                  _totalPagesKey,
                ])))
          .go();
    });
  }

  /// The last page a full build finished writing (`0` when never built or
  /// after [clear]).
  Future<int> lastBuiltPage() => _readInt(_lastBuiltPageKey);

  /// The total page count seen by the last full build (`0` when unknown).
  Future<int> totalPages() => _readInt(_totalPagesKey);

  /// Number of cached rows.
  Future<int> count() async {
    final expr = _db.gameIndex.threadId.count();
    final row = await (_db.selectOnly(_db.gameIndex)..addColumns([expr]))
        .getSingle();
    return row.read(expr) ?? 0;
  }

  /// When the index was last built/refreshed, or null when never built.
  Future<DateTime?> lastUpdated() async {
    final row = await (_db.select(_db.indexMeta)
          ..where((m) => m.key.equals(_lastUpdatedKey)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final seconds = int.tryParse(row.value);
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// The first [limit] rows in title order.
  ///
  /// Used for the empty-query state of the import search: the cache itself is
  /// the browsing surface, so there is no network round-trip to open a dialog.
  Future<List<GameIndexRow>> browse({int limit = 50}) async {
    return (_db.select(_db.gameIndex)
          ..orderBy([(t) => OrderingTerm(expression: t.title)])
          ..limit(limit))
        .get();
  }

  /// Finds cached rows for a folder name or a typed query.
  ///
  /// Two tiers, strongest first:
  ///
  /// 1. Every whitespace token of the query must occur in `normalizedTitle`
  ///    (AND, word order irrelevant), so `care secret` and the partial
  ///    `secr caf` both find `Secret Care Cafe [v0.9.5] [Rare Alex]`. This is
  ///    the old behaviour and returns title-ordered rows.
  /// 2. When no row contains every token, the compact forms of the query and
  ///    the tokens become an SQL prefilter (`compactTitle LIKE '%token%'`,
  ///    OR-ed) and each candidate is scored by its LCS similarity to the
  ///    compact query. Rows at or above [similarityThreshold] are returned,
  ///    best score first — an exact compact match therefore leads. This is what
  ///    absorbs a missing space (`DevotedWife`), an author prefix
  ///    (`Koshinohi Magical Academy Dropout`) and a date suffix
  ///    (`… Trap Dungeon 2025 11 14`).
  ///
  /// A trailing number that is not a date stays content (ticket 55): `Game 61`
  /// must not degrade into a hit for `Game 1`, so the number has to occur in
  /// the candidate title. A blank query returns nothing.
  Future<List<GameIndexRow>> search(String query, {int limit = 50}) async {
    final compactQuery = compactTitle(query);
    if (compactQuery.isEmpty) {
      return const [];
    }
    final tokens = _tokens(query);
    if (tokens.isNotEmpty) {
      final rows = await _searchTokens(tokens, limit);
      if (rows.isNotEmpty) {
        return rows;
      }
    }
    return _searchCompact(compactQuery, tokens, limit);
  }

  /// Minimum LCS similarity for the compact tier — low enough that an author
  /// prefix or a date suffix still fits, high enough that a shared generic word
  /// (`Unknown Game` vs `Other Game`) does not.
  static const similarityThreshold = 0.6;

  /// Rows whose `normalizedTitle` contains every token in [tokens], title
  /// ordered and capped at [limit].
  Future<List<GameIndexRow>> _searchTokens(
    List<String> tokens,
    int limit,
  ) async {
    final statement = _db.select(_db.gameIndex);
    _whereTokens(statement, tokens);
    return (statement
          ..orderBy([(t) => OrderingTerm(expression: t.title)])
          ..limit(limit))
        .get();
  }

  /// Candidates prefiltered on [compactQuery] and the compact [tokens], scored
  /// by LCS similarity and returned best-first, capped at [limit].
  Future<List<GameIndexRow>> _searchCompact(
    String compactQuery,
    List<String> tokens,
    int limit,
  ) async {
    final needles = <String>{
      compactQuery,
      for (final token in tokens) compactTitle(token),
    }..removeWhere((needle) => needle.isEmpty);
    if (needles.isEmpty) {
      return const [];
    }
    final requiredNumber = _requiredNumber(compactQuery);

    final statement = _db.select(_db.gameIndex)
      ..where((t) {
        var any = _contains(t.compactTitle, needles.first) |
            _within(t.compactTitle, compactQuery);
        for (final needle in needles.skip(1)) {
          any = any | _contains(t.compactTitle, needle);
        }
        if (requiredNumber != null) {
          any = any & _contains(t.compactTitle, requiredNumber);
        }
        return any;
      });

    final scored = <({GameIndexRow row, double score})>[
      for (final row in await statement.get())
        (row: row, score: lcsSimilarity(compactQuery, row.compactTitle)),
    ].where((hit) => hit.score >= similarityThreshold).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.row.title.compareTo(b.row.title);
      });
    return [for (final hit in scored.take(limit)) hit.row];
  }

  /// `column LIKE '%value%'`, with LIKE wildcards in [value] taken literally.
  static Expression<bool> _contains(
    Expression<String> column,
    String value,
  ) =>
      column.like('%${_escapeLike(value)}%', escapeChar: r'\');

  /// The mirror of [_contains]: whether the row's compact title occurs inside
  /// [value], i.e. `value LIKE '%' || compactTitle || '%'`.
  ///
  /// A folder name that glues an author prefix, the title and a date into one
  /// word (`KoshinohiAmeliaAnd…Dungeon2025`) leaves no query token that is a
  /// substring of the stored title, so the forward prefilter alone would drop
  /// the very row the similarity score is looking for.
  static Expression<bool> _within(Expression<String> column, String value) =>
      Constant<String>(value).likeExp(
        const Constant<String>('%') + column + const Constant<String>('%'),
      );

  /// The latest version f95zone reports for [threadId], or null when the
  /// thread is not cached (or the cached row carries no version).
  ///
  /// Used by the local library to flag games whose installed `Game.version`
  /// differs from the catalogue's latest (ticket 53).
  Future<String?> latestVersionFor(int threadId) async {
    final row = await (_db.select(_db.gameIndex)
          ..where((t) => t.threadId.equals(threadId)))
        .getSingleOrNull();
    final version = row?.latestVersion;
    return version == null || version.isEmpty ? null : version;
  }

  /// The best cached row for [title], or null when nothing matches.
  ///
  /// Matching uses the same normalization and token rules as [search]; an
  /// exact `normalizedTitle == needle` row wins over the first token match in
  /// title order. Used by the import flows to associate a folder name with
  /// the catalogue without an extra picker round-trip.
  Future<GameIndexRow?> matchTitle(String title) async {
    final needle = normalizeTitle(title);
    if (needle.isEmpty) {
      return null;
    }
    final exact = await (_db.select(_db.gameIndex)
          ..where((t) => t.normalizedTitle.equals(needle))
          ..limit(1))
        .getSingleOrNull();
    if (exact != null) {
      return exact;
    }
    final matches = await search(title, limit: 1);
    return matches.isEmpty ? null : matches.first;
  }

  /// Awaits [fetch] but stops waiting when [cancelSignal] completes.
  ///
  /// The abandoned request is explicitly ignored, so its late result — or its
  /// error — never surfaces as an unhandled asynchronous error.
  static Future<T> _raceCancel<T>(
    Future<T> fetch,
    Future<void>? cancelSignal,
  ) {
    if (cancelSignal == null) {
      return fetch;
    }
    fetch.ignore();
    return Future.any<T>([
      fetch,
      cancelSignal.then<T>((_) => throw const BuildCancelled()),
    ]);
  }

  /// Writes the rows whose listing timestamp moved past what is stored.
  Future<int> _mergeNewer(List<Game> games, DateTime? lastUpdated) async {
    if (games.isEmpty) {
      return 0;
    }
    final ids = games.map((g) => g.threadId).toList(growable: false);
    final stored = await (_db.select(_db.gameIndex)
          ..where((t) => t.threadId.isIn(ids)))
        .get();
    final storedTs = {for (final row in stored) row.threadId: row.ts};
    final int? updatedTs = lastUpdated == null ? null : _seconds(lastUpdated);

    final changed = games
        .where((game) {
          final existing = storedTs[game.threadId];
          final ts = _seconds(game.updatedAt);
          if (existing == null) {
            return true;
          }
          return ts > existing && (updatedTs == null || ts > updatedTs);
        })
        .toList(growable: false);

    await _upsert(changed);
    return changed.length;
  }

  Future<void> _upsert(List<Game> games) async {
    if (games.isEmpty) {
      return;
    }
    final cachedAt = _clock();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.gameIndex,
        games.map((game) => _companion(game, cachedAt)).toList(growable: false),
      );
    });
  }

  GameIndexCompanion _companion(Game game, DateTime cachedAt) {
    return GameIndexCompanion(
      threadId: Value(game.threadId),
      title: Value(game.title),
      normalizedTitle: Value(normalizeTitle(game.title)),
      compactTitle: Value(compactTitle(game.title)),
      creator: Value(game.creator),
      latestVersion: Value(game.latestVersion),
      cover: Value(game.cover),
      screens: Value(_encode(game.screens)),
      tags: Value(_encode(game.tagIds)),
      prefixes: Value(_encode(game.prefixIds)),
      rating: Value(game.rating),
      views: Value(game.views),
      likes: Value(game.likes),
      ts: Value(_seconds(game.updatedAt)),
      cachedAt: Value(cachedAt),
    );
  }

  Future<void> _setLastUpdated(DateTime at) async {
    await _setMeta(_lastUpdatedKey, '${_seconds(at)}');
  }

  /// Persists one [IndexMeta] entry, overwriting any previous value.
  Future<void> _setMeta(String key, String value) async {
    await _db.into(_db.indexMeta).insertOnConflictUpdate(
          IndexMetaCompanion(
            key: Value(key),
            value: Value(value),
          ),
        );
  }

  /// Reads one [IndexMeta] value as an int, defaulting to `0`.
  Future<int> _readInt(String key) async {
    final row = await (_db.select(_db.indexMeta)
          ..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row == null ? 0 : int.tryParse(row.value) ?? 0;
  }

  /// Normalizes a title for storage/search: bracket groups and category
  /// prefixes stripped, whitespace collapsed, then lower-cased. See
  /// [normalizedSearchTitle].
  static String normalizeTitle(String title) => normalizedSearchTitle(title);

  /// The whitespace-separated tokens of a normalized query. Empty for a
  /// blank query.
  static List<String> _tokens(String query) {
    final normalized = normalizeTitle(query);
    if (normalized.isEmpty) {
      return const [];
    }
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  /// Narrows [statement] to rows whose `normalizedTitle` contains every
  /// token (AND). LIKE wildcards in a token match literally.
  static void _whereTokens(
    SimpleSelectStatement<$GameIndexTable, GameIndexRow> statement,
    List<String> tokens,
  ) {
    for (final token in tokens) {
      final pattern = '%${_escapeLike(token)}%';
      statement.where((t) => t.normalizedTitle.like(pattern, escapeChar: r'\'));
    }
  }

  /// The trailing digit run of [compactQuery] when it is *content*, not a date
  /// suffix — the number a compact match has to find literally.
  ///
  /// The run is read off the compact query, so a date glued to the title
  /// (`…Dungeon2025 11 14` → `…dungeon20251114`) is still recognized by its
  /// year. Without this guard a numbered title would match a different number:
  /// `Game 61` scores 0.83 against `Game 1`, which is a wrong game, not a
  /// fuzzy hit.
  static String? _requiredNumber(String compactQuery) {
    final run = RegExp(r'\d+$').firstMatch(compactQuery)?[0];
    if (run == null) {
      return null;
    }
    return _yearInDigits.hasMatch(run) ? null : run;
  }

  /// A calendar year anywhere inside a digit run.
  static final _yearInDigits = RegExp(r'(?:19|20)\d{2}');

  static final _likeSpecials = RegExp(r'[\\%_]');

  static String _escapeLike(String token) =>
      token.replaceAllMapped(_likeSpecials, (match) => '\\${match[0]}');

  static int _seconds(DateTime? at) =>
      at == null ? 0 : at.millisecondsSinceEpoch ~/ 1000;

  static String _encode(List<Object?> values) => jsonEncode(values);
}
