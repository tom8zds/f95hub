import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/game_index_mapping.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/state/game_index.dart';

import 'support/fake_metadata_source.dart';

/// A source whose every listing request takes [delay] to settle, so a cancel
/// can be exercised while a request is genuinely in flight.
class _SlowMetadataSource extends FakeMetadataSource {
  _SlowMetadataSource(
    super.games, {
    super.pageSize,
    this.delay = const Duration(seconds: 5),
  });

  final Duration delay;

  /// Pages whose request has started (recorded before the simulated wait).
  final List<int> startedPages = [];

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    startedPages.add(page);
    await Future<void>.delayed(delay);
    return super.listGames(
      cat,
      tags: tags,
      prefixes: prefixes,
      sort: sort,
      date: date,
      page: page,
    );
  }
}

/// A source whose in-flight request fails long after it was abandoned.
class _SlowFailingSource extends FakeMetadataSource {
  _SlowFailingSource(super.games, {this.delay = const Duration(milliseconds: 100)});

  final Duration delay;

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    await Future<void>.delayed(delay);
    throw Exception('late failure after cancel');
  }
}

/// A source whose listing request for a chosen page blocks until released, so
/// a test can observe state while a run is genuinely mid-flight.
class _GatedMetadataSource extends FakeMetadataSource {
  _GatedMetadataSource(super.games, {super.pageSize});

  final Map<int, Completer<void>> _gates = {};

  /// Makes the request for [page] wait until [release] is called.
  void gate(int page) => _gates[page] = Completer<void>();

  void release(int page) => _gates[page]!.complete();

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    final gate = _gates[page];
    if (gate != null) {
      await gate.future;
    }
    return super.listGames(
      cat,
      tags: tags,
      prefixes: prefixes,
      sort: sort,
      date: date,
      page: page,
    );
  }
}

void main() {
  late LibraryDatabase db;
  late DateTime now;

  setUp(() {
    db = LibraryDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 21);
  });

  tearDown(() => db.close());

  GameIndexStore storeFor(FakeMetadataSource source) =>
      GameIndexStore(db, source, clock: () => now);

  List<Game> manyGames(int count) => List.generate(
        count,
        (i) => makeGame(
          i + 1,
          title: 'Game ${i + 1}',
          updatedAt: DateTime(2026, 10, 20),
        ),
      );

  group('buildAll', () {
    test('pages through the catalogue, upserts every row and reports progress',
        () async {
      final source = FakeMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      final progress = <String>[];
      final counts = <int>[];

      final count = await store.buildAll(
        onProgress: (page, total, count) {
          progress.add('$page/$total');
          counts.add(count);
        },
      );

      expect(count, 65);
      expect(progress, ['1/3', '2/3', '3/3']);
      // The reported count grows with every written page.
      expect(counts, [30, 60, 65]);
      expect(source.lastSort, SortOrder.title);
      expect(await db.select(db.gameIndex).get(), hasLength(65));
      expect(await store.lastUpdated(), now);
    });

    test('stores the listing fields, normalized title and ts', () async {
      final source = FakeMetadataSource([
        makeGame(
          7,
          title: 'Secret Care Cafe [v0.9.5] [Rare Alex]',
          version: 'v0.9.5',
          tagIds: const [45, 107],
          prefixIds: const [3],
          rating: 4.5,
          views: 1234,
          likes: 56,
          updatedAt: DateTime(2026, 10, 20, 8, 30),
        ),
      ]);
      final store = storeFor(source);

      await store.buildAll();

      final row = (await db.select(db.gameIndex).get()).single;
      expect(row.threadId, 7);
      expect(row.title, 'Secret Care Cafe [v0.9.5] [Rare Alex]');
      expect(row.normalizedTitle, 'secret care cafe');
      expect(row.latestVersion, 'v0.9.5');
      expect(row.creator, 'Creator 7');
      expect(row.rating, 4.5);
      expect(row.views, 1234);
      expect(row.likes, 56);
      expect(row.tags, '[45,107]');
      expect(row.prefixes, '[3]');
      expect(
        row.ts,
        DateTime(2026, 10, 20, 8, 30).millisecondsSinceEpoch ~/ 1000,
      );
      expect(row.cachedAt, now);
    });

    test('stops after the current page when cancelled and keeps no lastUpdated',
        () async {
      final source = FakeMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      final progress = <String>[];

      final count = await store.buildAll(
        onProgress: (page, total, count) => progress.add('$page/$total'),
        isCancelled: () => true,
      );

      expect(count, 30);
      expect(progress, ['1/3']);
      expect(await store.lastUpdated(), isNull);
      // The written page is the resume point for the next run.
      expect(await store.lastBuiltPage(), 1);
      expect(await store.totalPages(), 3);
    });

    test('429 exhaustion stops gracefully and keeps the resume point',
        () async {
      final source = FakeMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      source.rateLimitedPages.add(2);
      final progress = <String>[];

      final count = await store.buildAll(
        onProgress: (page, total, count) => progress.add('$page/$total'),
      );

      expect(count, 30);
      expect(progress, ['1/3']);
      expect(await store.lastBuiltPage(), 1);
      expect(await store.totalPages(), 3);
      expect(await store.lastUpdated(), isNull);
    });

    test('a later build resumes from lastBuiltPage + 1', () async {
      final games = manyGames(65);
      final source = FakeMetadataSource(games, pageSize: 30);
      final store = storeFor(source);
      source.rateLimitedPages.add(2);
      await store.buildAll();

      // Page 1 is already stored; mutating it must not be re-written by the
      // resumed run, which starts at page 2.
      games[0] = makeGame(
        1,
        title: 'Game 1 (changed)',
        updatedAt: DateTime(2026, 10, 20),
      );
      source.rateLimitedPages.clear();
      source.requestedPages.clear();
      final progress = <String>[];
      final counts = <int>[];

      final count = await store.buildAll(
        onProgress: (page, total, count) {
          progress.add('$page/$total');
          counts.add(count);
        },
      );

      expect(count, 65);
      // Page 1 is fetched once for its totalPages, then 2..3 continue.
      expect(source.requestedPages, [1, 2, 3]);
      expect(progress, ['1/3', '2/3', '3/3']);
      // The resumed start reports what is already cached (page 1).
      expect(counts, [30, 60, 65]);
      expect(await store.lastBuiltPage(), 3);
      expect(await store.lastUpdated(), now);

      final rows = await db.select(db.gameIndex).get();
      final byId = {for (final row in rows) row.threadId: row};
      expect(byId[1]!.title, 'Game 1');
    });

    test('a completed build re-run fetches only page 1', () async {
      final source = FakeMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      await store.buildAll();

      source.requestedPages.clear();
      final progress = <String>[];
      await store.buildAll(
        onProgress: (page, total, count) => progress.add('$page/$total'),
      );

      expect(source.requestedPages, [1]);
      expect(progress, ['3/3']);
      expect(await store.lastBuiltPage(), 3);
    });

    test('resumes against a grown catalogue using the new total', () async {
      final games = manyGames(65);
      final source = FakeMetadataSource(games, pageSize: 30);
      final store = storeFor(source);
      source.rateLimitedPages.add(2);
      await store.buildAll();

      // The catalogue grew to four pages before the resume.
      games.addAll(
        List.generate(
          30,
          (i) => makeGame(
            100 + i,
            title: 'New ${100 + i}',
            updatedAt: DateTime(2026, 10, 20),
          ),
        ),
      );
      source.rateLimitedPages.clear();

      final count = await store.buildAll();

      expect(count, 95);
      expect(await store.lastBuiltPage(), 4);
      expect(await store.totalPages(), 4);
      expect(await store.lastUpdated(), now);
    });

    test('propagates errors other than 429', () async {
      final source = FakeMetadataSource(manyGames(65), pageSize: 30)
        ..fail = true;
      final store = storeFor(source);

      await expectLater(store.buildAll(), throwsException);
      expect(await store.lastBuiltPage(), 0);
    });
  });

  group('refreshIncremental', () {
    test('merges only rows newer than lastUpdated and inserts new ones',
        () async {
      final games = [
        makeGame(1, title: 'Alpha', updatedAt: DateTime(2026, 10, 20)),
        makeGame(2, title: 'Beta', updatedAt: DateTime(2026, 10, 20)),
      ];
      final source = FakeMetadataSource(games);
      final store = storeFor(source);
      await store.buildAll();

      // Refresh happens a day later; only game 1 moved after the build.
      now = DateTime(2026, 10, 22);
      games[0] = makeGame(
        1,
        title: 'Alpha (updated)',
        updatedAt: DateTime(2026, 10, 21, 6),
      );
      // Same timestamp: this change must NOT win over the cache.
      games[1] = makeGame(
        2,
        title: 'Beta (stale)',
        updatedAt: DateTime(2026, 10, 20),
      );
      // A row missing locally is inserted even with an old timestamp.
      games.add(
        makeGame(3, title: 'Gamma', updatedAt: DateTime(2026, 10, 19)),
      );

      final progress = <String>[];
      final written = await store.refreshIncremental(
        onProgress: (page, total, count) => progress.add('$page/$total'),
      );

      expect(written, 2);
      expect(progress, ['1/1']);
      expect(source.lastSort, SortOrder.date);

      final rows = await db.select(db.gameIndex).get();
      final byId = {for (final row in rows) row.threadId: row};
      expect(byId[1]!.title, 'Alpha (updated)');
      expect(byId[2]!.title, 'Beta');
      expect(byId[3]!.title, 'Gamma');
      expect(await store.lastUpdated(), now);
    });

    test('walks at most incrementalPages pages', () async {
      final source = FakeMetadataSource(manyGames(90), pageSize: 30);
      final store = GameIndexStore(
        db,
        source,
        incrementalPages: 2,
        clock: () => now,
      );

      final progress = <String>[];
      final counts = <int>[];
      await store.refreshIncremental(
        onProgress: (page, total, count) {
          progress.add('$page/$total');
          counts.add(count);
        },
      );

      expect(progress, ['1/2', '2/2']);
      expect(counts, [30, 60]);
      expect(await store.count(), 60);
    });

    test('stops on cancel without recording lastUpdated', () async {
      final source = FakeMetadataSource(manyGames(90), pageSize: 30);
      final store = storeFor(source);

      await store.refreshIncremental(isCancelled: () => true);

      expect(await store.count(), 30);
      expect(await store.lastUpdated(), isNull);
    });
  });

  test('clear empties the index and forgets lastUpdated and the resume point',
      () async {
    final source = FakeMetadataSource(manyGames(65), pageSize: 30);
    final store = storeFor(source);
    source.rateLimitedPages.add(2);
    await store.buildAll();
    expect(await store.count(), 30);
    expect(await store.lastBuiltPage(), 1);
    expect(await store.totalPages(), 3);

    await store.clear();

    expect(await store.count(), 0);
    expect(await store.lastUpdated(), isNull);
    expect(await store.lastBuiltPage(), 0);
    expect(await store.totalPages(), 0);
    expect(await store.search('game'), isEmpty);
  });

  group('browse', () {
    test('lists title-ordered rows and honours the limit', () async {
      final store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Zeta'),
          makeGame(2, title: 'Alpha'),
          makeGame(3, title: 'Mid'),
        ]),
      );
      await store.buildAll();

      expect(
        (await store.browse()).map((row) => row.title),
        ['Alpha', 'Mid', 'Zeta'],
      );
      expect(await store.browse(limit: 2), hasLength(2));
      expect(await store.browse(limit: 0), isEmpty);
    });

    test('an empty index browses to nothing', () async {
      final store = storeFor(FakeMetadataSource(const []));
      expect(await store.browse(), isEmpty);
    });
  });

  test('gameFromIndexRow rebuilds the listing-shaped Game', () async {
    final store = storeFor(
      FakeMetadataSource([
        makeGame(
          7,
          title: 'Secret Care Cafe [v0.9.5] [Rare Alex]',
          version: 'v0.9.5',
          tagIds: const [45, 107],
          prefixIds: const [3],
          cover: 'https://preview.f95zone.to/cover.png',
          screens: const ['https://preview.f95zone.to/a.png'],
          rating: 4.5,
          views: 12,
          likes: 3,
          updatedAt: DateTime(2026, 10, 20, 8, 30),
        ),
      ]),
    );
    await store.buildAll();

    final game = gameFromIndexRow((await store.browse()).single);

    expect(game.threadId, 7);
    expect(game.title, 'Secret Care Cafe [v0.9.5] [Rare Alex]');
    expect(game.creator, 'Creator 7');
    expect(game.latestVersion, 'v0.9.5');
    expect(game.cover, 'https://preview.f95zone.to/cover.png');
    expect(game.screens, ['https://preview.f95zone.to/a.png']);
    expect(game.tagIds, [45, 107]);
    expect(game.prefixIds, [3]);
    expect(game.rating, 4.5);
    expect(game.views, 12);
    expect(game.likes, 3);
    expect(game.updatedAt, DateTime(2026, 10, 20, 8, 30));
  });

  group('search', () {
    late GameIndexStore store;

    setUp(() async {
      store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Secret Care Cafe [v0.9.5] [Rare Alex]'),
          makeGame(2, title: 'Others - Secret Care Cafe 2'),
          makeGame(3, title: 'Something Else'),
        ]),
      );
      await store.buildAll();
    });

    test('matches by normalized title, case-insensitively', () async {
      final hits = await store.search('secret care cafe');

      // Title-ordered: "Others - …" sorts before "Secret Care …".
      expect(hits.map((r) => r.threadId), [2, 1]);
    });

    test('normalizes the query the same way as stored titles', () async {
      expect(
        (await store.search('Secret Care Cafe [v0.9.5]')).map((r) => r.threadId),
        [2, 1],
      );
      expect(
        (await store.search("Ren'Py - Secret Care Cafe")).map((r) => r.threadId),
        [2, 1],
      );
    });

    test('honours the limit and ignores blank queries', () async {
      expect(await store.search('secret', limit: 1), hasLength(1));
      expect(await store.search('   '), isEmpty);
      expect(await store.search('no such game'), isEmpty);
    });

    test('matches tokens in any order (AND across tokens)', () async {
      expect(
        (await store.search('care secret')).map((r) => r.threadId),
        [2, 1],
      );
      expect(
        (await store.search('cafe secret care')).map((r) => r.threadId),
        [2, 1],
      );
    });

    test('matches partial tokens', () async {
      expect(
        (await store.search('secr caf')).map((r) => r.threadId),
        [2, 1],
      );
    });

    test('requires every token to match', () async {
      // Neither token is present, so no relaxation level produces a hit.
      expect(await store.search('secret zzzz'), isEmpty);
    });

    test('treats LIKE wildcards literally', () async {
      expect(await store.search('%'), isEmpty);
      expect(await store.search('_'), isEmpty);
    });
  });

  group('search tolerant of folder-name noise', () {
    late GameIndexStore store;

    setUp(() async {
      store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Magical Academy Dropout'),
          makeGame(2, title: 'Amelia and the Erotic Tentacle Trap Dungeon'),
          makeGame(3, title: 'Secret Care Cafe'),
          makeGame(4, title: 'Care Cafe Nights'),
          makeGame(5, title: 'Game 1'),
          makeGame(6, title: 'Other Game'),
        ]),
      );
      await store.buildAll();
    });

    test('drops a leading author prefix when nothing else matches', () async {
      expect(
        (await store.search('Koshinohi Magical Academy Dropout'))
            .map((row) => row.threadId),
        [1],
      );
    });

    test('drops a trailing date when nothing else matches', () async {
      expect(
        (await store.search(
          'Amelia and the Erotic Tentacle Trap Dungeon 2025 11 14',
        ))
            .map((row) => row.threadId),
        [2],
      );
    });

    test('drops an author prefix and a date together', () async {
      expect(
        (await store.search(
          'Koshinohi Amelia and the Erotic Tentacle Trap Dungeon 2025 11 14',
        ))
            .map((row) => row.threadId),
        [2],
      );
    });

    test('a full match wins over a relaxed one (no false positive)', () async {
      // "care cafe" alone would also hit "Care Cafe Nights"; the full query
      // matches thread 3 outright, so that weaker level is never reached.
      expect(
        (await store.search('Secret Care Cafe')).map((row) => row.threadId),
        [3],
      );
    });

    test('does not relax a two-word query to one generic word', () async {
      // "game" alone would hit "Other Game"; a bare leading drop to a single
      // token is never attempted.
      expect(await store.search('Unknown Game'), isEmpty);
    });

    test('keeps a trailing number that is not a date', () async {
      // No year in the trailing run, so "61" is title content, not noise.
      expect(await store.search('Game 61'), isEmpty);
      expect(
        (await store.search('Game 1')).map((row) => row.threadId),
        [5],
      );
    });

    test('strips a lone trailing year', () async {
      expect(
        (await store.search('Magical Academy Dropout 2025'))
            .map((row) => row.threadId),
        [1],
      );
    });
  });

  group('search by compact title (ticket 56)', () {
    late GameIndexStore store;

    setUp(() async {
      store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Devoted Wife'),
          makeGame(2, title: 'Magical Academy Dropout'),
          makeGame(3, title: 'Amelia and the Erotic Tentacle Trap Dungeon'),
          makeGame(4, title: 'Secret Care Cafe [v0.9.5] [Rare Alex]'),
          makeGame(6, title: 'Other Game'),
        ]),
      );
      await store.buildAll();
    });

    test('finds a spaced title from a folder name without spaces', () async {
      expect(
        (await store.search('DevotedWife')).map((row) => row.threadId),
        [1],
      );
    });

    test('tolerates a leading author prefix', () async {
      expect(
        (await store.search('Koshinohi Magical Academy Dropout'))
            .map((row) => row.threadId),
        [2],
      );
    });

    test('tolerates a trailing date', () async {
      expect(
        (await store.search(
          'Amelia and the Erotic Tentacle Trap Dungeon 2025 11 14',
        ))
            .map((row) => row.threadId),
        [3],
      );
    });

    test('tolerates author, missing spaces and a date together', () async {
      expect(
        (await store.search(
          'KoshinohiAmeliaAndTheEroticTentacleTrapDungeon2025 11 14',
        ))
            .map((row) => row.threadId),
        [3],
      );
    });

    test('ignores the version brackets the stored title carries', () async {
      // The compact form drops the bracket groups, so the version tag never
      // dilutes the score of a spaceless query.
      expect(
        (await store.search('SecretCareCafe')).map((row) => row.threadId),
        [4],
      );
    });

    test('an exact compact match ranks above a looser one', () async {
      final otherDb = LibraryDatabase(NativeDatabase.memory());
      addTearDown(otherDb.close);
      final ranked = GameIndexStore(
        otherDb,
        FakeMetadataSource([
          makeGame(10, title: 'Hidden Gem X'),
          makeGame(11, title: 'Hidden Gem'),
        ]),
        clock: () => now,
      );
      await ranked.buildAll();

      final hits = await ranked.search('HiddenGem');

      expect(hits.map((row) => row.threadId), [11, 10]);
    });

    test('a generic query does not match every title', () async {
      expect(await store.search('Favourite'), isEmpty);
      expect(await store.search('Unknown Game'), isEmpty);
    });

    test('honours the limit in the compact tier', () async {
      expect(await store.search('DevotedWife', limit: 1), hasLength(1));
    });
  });

  group('matchTitle', () {
    late GameIndexStore store;

    setUp(() async {
      store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Secret Care Cafe [v0.9.5] [Rare Alex]'),
          makeGame(2, title: 'Others - Secret Care Cafe 2'),
          makeGame(3, title: 'Something Else'),
        ]),
      );
      await store.buildAll();
    });

    test('prefers the exact normalized title', () async {
      final hit = await store.matchTitle('Secret Care Cafe');

      // Thread 2 sorts first by raw title, so an exact hit proves exactness
      // outranks the title-ordered contains fallback.
      expect(hit?.threadId, 1);
    });

    test('falls back to the first token match in title order', () async {
      final hit = await store.matchTitle('secret care');

      expect(hit?.threadId, 2);
    });

    test('falls back to a token match in any word order', () async {
      expect((await store.matchTitle('cafe secret'))?.threadId, 2);
    });

    test('returns null when nothing matches or the query is blank', () async {
      expect(await store.matchTitle('no such game'), isNull);
      expect(await store.matchTitle('   '), isNull);
    });
  });

  group('latestVersionFor', () {
    late GameIndexStore store;

    setUp(() async {
      store = storeFor(
        FakeMetadataSource([
          makeGame(1, title: 'Kunoichi Sensei', version: 'v1.2.0'),
          makeGame(2, title: 'Versionless', version: ''),
        ]),
      );
      await store.buildAll();
    });

    test('returns the cached latestVersion for a thread', () async {
      expect(await store.latestVersionFor(1), 'v1.2.0');
    });

    test('returns null for an unknown thread', () async {
      expect(await store.latestVersionFor(999), isNull);
    });

    test('returns null when the cached row has no version', () async {
      expect(await store.latestVersionFor(2), isNull);
    });
  });

  group('cancel signal', () {
    test('buildAll stops immediately while the first page is in flight',
        () async {
      final source = _SlowMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      final cancel = Completer<void>();
      final stopwatch = Stopwatch()..start();

      final run = store.buildAll(cancelSignal: cancel.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      cancel.complete();

      final count = await run.timeout(const Duration(seconds: 1));
      stopwatch.stop();

      expect(count, 0);
      expect(source.listCalls, 0);
      expect(await store.lastUpdated(), isNull);
      expect(await store.lastBuiltPage(), 0);
      // Five-second requests would blow far past this.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('buildAll stops immediately on a later page', () async {
      final source = _SlowMetadataSource(
        manyGames(65),
        pageSize: 30,
        delay: const Duration(milliseconds: 200),
      );
      final store = storeFor(source);
      final cancel = Completer<void>();

      final run = store.buildAll(cancelSignal: cancel.future);
      // Page 1 completes, then page 2 is in flight when the cancel lands.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      cancel.complete();

      final count = await run.timeout(const Duration(seconds: 1));

      expect(count, 30);
      expect(source.startedPages, [1, 2]);
      // The abandoned second request never got past its delay.
      expect(source.listCalls, 1);
      expect(await store.lastUpdated(), isNull);
      expect(await store.lastBuiltPage(), 1);
    });

    test('refreshIncremental stops immediately on cancel', () async {
      final source = _SlowMetadataSource(manyGames(65), pageSize: 30);
      final store = storeFor(source);
      final cancel = Completer<void>();

      final run = store.refreshIncremental(cancelSignal: cancel.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      cancel.complete();

      final written = await run.timeout(const Duration(seconds: 1));

      expect(written, 0);
      expect(await store.lastUpdated(), isNull);
    });

    test('an abandoned in-flight request raises no unhandled error', () async {
      final source = _SlowFailingSource(
        manyGames(10),
        delay: const Duration(milliseconds: 100),
      );
      final store = storeFor(source);
      final cancel = Completer<void>();

      final run = store.buildAll(cancelSignal: cancel.future);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cancel.complete();
      await run.timeout(const Duration(seconds: 1));

      // Let the abandoned request fail; an unhandled async error would fail
      // this test.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    test('the controller cancel aborts an in-flight build promptly', () async {
      final source = _SlowMetadataSource(
        manyGames(65),
        pageSize: 30,
        delay: const Duration(seconds: 5),
      );
      final store = storeFor(source);
      final container = ProviderContainer(
        overrides: [gameIndexStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(gameIndexProvider.notifier);

      final run = controller.buildAll();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(gameIndexProvider).busy, isTrue);

      controller.cancel();

      await run.timeout(const Duration(seconds: 1));
      expect(container.read(gameIndexProvider).busy, isFalse);
      expect(container.read(gameIndexProvider).error, isNull);
      expect(source.listCalls, 0);
    });
  });

  test('controller state.count grows while the build runs', () async {
    final source = _GatedMetadataSource(manyGames(65), pageSize: 30)
      ..gate(2);
    final store = storeFor(source);
    final container = ProviderContainer(
      overrides: [gameIndexStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(gameIndexProvider.notifier);

    final run = controller.buildAll();
    // Page 1 is written and the run is blocked on page 2.
    await pumpEventQueue();

    var state = container.read(gameIndexProvider);
    expect(state.busy, isTrue);
    expect(state.page, 1);
    expect(state.total, 3);
    expect(state.count, 30);

    source.release(2);
    await run;

    state = container.read(gameIndexProvider);
    expect(state.count, 65);
    expect(state.busy, isFalse);
  });
}
