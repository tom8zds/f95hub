import 'dart:async';
import 'dart:math';

import 'package:f95hub/domain/ports.dart';

/// In-memory [MetadataSource] for widget/state tests.
///
/// Serves [games] in pages of [pageSize] (default 30, matching the endpoint),
/// records the last requested [lastSort] / [lastPage], and fails only when
/// [fail] is set (to exercise error states).
class FakeMetadataSource implements MetadataSource {
  FakeMetadataSource(
    this.games, {
    this.pageSize = 30,
    this.fail = false,
    this.tagTable,
    this.threadDetails = const {},
  });

  final List<Game> games;
  final int pageSize;
  bool fail;

  /// Pages whose `listGames` throws [RateLimitedException], simulating a run
  /// that exhausted its 429 retries mid-build. Mutable so tests can clear a
  /// page and resume.
  final Set<int> rateLimitedPages = {};

  /// Static table served by [getTagTable]; defaults to an empty table.
  final TagTable? tagTable;

  /// Thread details keyed by thread id, served by [getThread].
  final Map<int, ThreadDetail> threadDetails;

  SortOrder? lastSort;
  int? lastPage;
  int listCalls = 0;
  List<int>? lastTags;
  List<int>? lastPrefixes;
  int? lastDate;

  /// Every page number requested through [listGames], in call order.
  final List<int> requestedPages = [];

  /// How many times [clearCache] was called.
  int clearCacheCalls = 0;

  /// How many times [getTagTable] was called.
  int tagTableCalls = 0;

  final StreamController<bool> _throttled = StreamController<bool>.broadcast();

  /// Test hook: emits a throttle/retry signal to subscribers.
  void setThrottled(bool value) => _throttled.add(value);

  /// When set, [listGames] waits for it before answering, so a test can hold
  /// the listing in its loading state.
  Completer<void>? listGate;

  /// When set, [getThread] waits for it before answering, so a test can hold
  /// the detail in its loading state.
  Completer<void>? threadGate;

  @override
  Stream<bool> get throttled => _throttled.stream;

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    listCalls++;
    lastSort = sort;
    lastPage = page;
    requestedPages.add(page);
    lastTags = tags;
    lastPrefixes = prefixes;
    lastDate = date;
    final listGate = this.listGate;
    if (listGate != null) {
      await listGate.future;
    }
    if (fail) {
      throw Exception('boom');
    }
    if (rateLimitedPages.contains(page)) {
      throw const RateLimitedException();
    }
    final totalPages = (games.length / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final end = min(start + pageSize, games.length);
    final items = start >= games.length
        ? <Game>[]
        : games.sublist(start, end).toList(growable: false);
    return GameListPage(
      items: items,
      page: page,
      totalPages: totalPages,
      totalCount: games.length,
    );
  }

  @override
  Future<ThreadDetail> getThread(int threadId) async {
    final gate = threadGate;
    if (gate != null) await gate.future;
    if (fail) {
      throw Exception('boom');
    }
    final thread = threadDetails[threadId];
    if (thread == null) {
      throw Exception('no thread $threadId');
    }
    return thread;
  }

  @override
  Future<TagTable> getTagTable() async {
    tagTableCalls++;
    if (fail) {
      throw Exception('boom');
    }
    return tagTable ?? const TagTable(tags: {}, prefixes: {});
  }

  @override
  void clearCache() => clearCacheCalls++;

  /// Every cookie passed to [login], in call order.
  final List<String?> loginCookies = [];

  @override
  Future<String> login(LoginCredentials credentials) async {
    final cookie = credentials.cookie;
    loginCookies.add(cookie);
    if (cookie == null || cookie.isEmpty) {
      throw Exception('fake login requires a cookie');
    }
    return cookie;
  }
}

/// Builds a [Game] for tests.
Game makeGame(
  int threadId, {
  String? title,
  String? version,
  List<int>? tagIds,
  List<int>? prefixIds,
  DateTime? updatedAt,
  String? cover,
  List<String>? screens,
  double rating = 0,
  int views = 0,
  int likes = 0,
}) => Game(
  threadId: threadId,
  title: title ?? 'Game $threadId',
  creator: 'Creator $threadId',
  latestVersion: version ?? 'v0.0.$threadId',
  cover: cover,
  screens: screens ?? const [],
  tagIds: tagIds ?? const [],
  prefixIds: prefixIds ?? const [],
  rating: rating,
  views: views,
  likes: likes,
  createdAt: updatedAt ?? DateTime(2026, 10, 24),
  updatedAt: updatedAt ?? DateTime(2026, 10, 24),
);

/// Builds a [ThreadDetail] for tests.
ThreadDetail makeThreadDetail(
  int threadId, {
  String? title,
  String description = '',
}) =>
    ThreadDetail(
      threadId: threadId,
      title: title ?? 'Game $threadId',
      description: description,
    );

/// Builds a small [TagTable] for tests: a few tags plus `games` prefix groups
/// ("Other" → `VN`/`Collection`, "Engine" → `Unity`/`Ren'Py`, "Status" →
/// `Completed`/`Onhold`/`Abandoned`).
TagTable makeTagTable() => TagTable(
  tags: const {45: 'rpg', 107: '3dcg', 1507: '2dcg'},
  prefixes: {
    GameCategory.games: const [
      PrefixGroup(id: 3, name: 'Other', prefixes: [
        Prefix(id: 13, name: 'VN'),
        Prefix(id: 19, name: 'Collection'),
        Prefix(id: 23, name: 'SiteRip'),
      ]),
      PrefixGroup(id: 1, name: 'Engine', prefixes: [
        Prefix(id: 3, name: 'Unity'),
        Prefix(id: 7, name: "Ren'Py"),
      ]),
      PrefixGroup(id: 4, name: 'Status', prefixes: [
        Prefix(id: 18, name: 'Completed'),
        Prefix(id: 20, name: 'Onhold'),
        Prefix(id: 22, name: 'Abandoned'),
      ]),
    ],
  },
);
