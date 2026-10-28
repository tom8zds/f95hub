import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/f95zone_metadata_source.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

void main() {
  ProviderContainer makeContainer(FakeMetadataSource source) {
    final container = ProviderContainer(
      overrides: [metadataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('load populates the first page and hasMore', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();

    final state = container.read(gameListProvider);
    expect(state.games, hasLength(30));
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(source.lastSort, SortOrder.date);
    expect(source.lastPage, 1);
  });

  test('load resolves tag ids to names via the tag table', () async {
    final source = FakeMetadataSource(
      [
        makeGame(0, tagIds: const [45, 107]),
        makeGame(1),
      ],
      tagTable: makeTagTable(),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();

    final state = container.read(gameListProvider);
    expect(state.games[0].tags, ['rpg', '3dcg']);
    expect(state.games[1].tags, isEmpty);
  });

  test('goToPage resolves tag ids on subsequent pages', () async {
    final source = FakeMetadataSource(
      [
        makeGame(0, tagIds: const [1507]),
        makeGame(1, tagIds: const [45]),
      ],
      pageSize: 1,
      tagTable: makeTagTable(),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.goToPage(2);

    final state = container.read(gameListProvider);
    expect(state.page, 2);
    expect(state.games.single.tags, ['rpg']);
  });

  test('nextPage replaces content and tracks page/totalPages', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    final firstPage = container.read(gameListProvider);
    expect(firstPage.games, hasLength(30));
    expect(firstPage.page, 1);
    expect(firstPage.totalPages, 2);
    expect(firstPage.hasMore, isTrue);

    await notifier.nextPage();

    var state = container.read(gameListProvider);
    expect(state.games, hasLength(30)); // replaced, not appended
    expect(state.games.first.threadId, 30); // page 2 starts at item 30
    expect(state.page, 2);
    expect(state.hasMore, isFalse);
  });

  test('nextPage is a no-op at the last page and prevPage at the first', () async {
    final source = FakeMetadataSource(
      List.generate(30, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    expect(container.read(gameListProvider).totalPages, 1);

    // At the only page: prev is already disabled and next does nothing.
    await notifier.prevPage();
    expect(container.read(gameListProvider).page, 1);

    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 1);
    expect(source.lastPage, 1);
  });

  test('prevPage returns to the previous page', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);

    await notifier.prevPage();

    var state = container.read(gameListProvider);
    expect(state.page, 1);
    expect(state.games.first.threadId, 0);
    expect(source.lastPage, 1);
  });

  test('goToPage out of range is a no-op', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();

    await notifier.goToPage(0);
    expect(container.read(gameListProvider).page, 1);

    await notifier.goToPage(99);
    expect(container.read(gameListProvider).page, 1);
  });

  test('setSort resets to page one and reloads with the new sort', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);

    await notifier.setSort(SortOrder.rating);

    final state = container.read(gameListProvider);
    expect(state.sort, SortOrder.rating);
    expect(state.games, hasLength(30)); // reset to first page only
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(source.lastSort, SortOrder.rating);
  });

  test('setQuery filters games by title locally', () async {
    final source = FakeMetadataSource(
      List.generate(10, (i) => makeGame(i, title: 'Alpha $i')),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    notifier.setQuery('alpha 3');

    expect(container.read(gameListProvider).filteredGames, hasLength(1));
    expect(container.read(gameListProvider).filteredGames.single.title, 'Alpha 3');
  });

  test('setQuery with empty query returns all loaded games', () async {
    final source = FakeMetadataSource(
      List.generate(10, (i) => makeGame(i, title: 'Alpha $i')),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    notifier.setQuery('');

    expect(container.read(gameListProvider).filteredGames, hasLength(10));
  });

  test('setQuery resets to page one when paginated', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i, title: 'Alpha $i')),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);

    notifier.setQuery('Alpha 3');
    await pumpEventQueue();

    final state = container.read(gameListProvider);
    expect(state.page, 1);
    expect(state.filteredGames.single.title, 'Alpha 3');
    expect(source.lastPage, 1);
  });

  test('setTags resets to page one when paginated', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);

    await notifier.setTags(const {45});

    final state = container.read(gameListProvider);
    expect(state.page, 1);
    expect(state.games, hasLength(30));
    expect(source.lastPage, 1);
  });

  test('a failed load surfaces the error', () async {
    final source = FakeMetadataSource([])..fail = true;
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();

    final state = container.read(gameListProvider);
    expect(state.error, isNotNull);
    expect(state.loading, isFalse);
    expect(state.games, isEmpty);
  });

  test('load passes the tag/prefix/date filters to listGames', () async {
    final source = FakeMetadataSource(List.generate(10, (i) => makeGame(i)));
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.setTags(const {45, 107});
    await notifier.setPrefixes(const {3, 18});
    await notifier.setDate(7);

    expect(source.lastTags, [45, 107]);
    expect(source.lastPrefixes, [3, 18]);
    expect(source.lastDate, 7);
  });

  test('clearing filters sends null to listGames', () async {
    final source = FakeMetadataSource(List.generate(10, (i) => makeGame(i)));
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.setTags(const {45});
    await notifier.setPrefixes(const {});
    await notifier.setDate(null);

    expect(source.lastTags, [45]);
    expect(source.lastPrefixes, isNull);
    expect(source.lastDate, isNull);
  });

  test('refresh clears the cache and re-fetches the current page', () async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);
    source.requestedPages.clear();

    await notifier.refresh();

    final state = container.read(gameListProvider);
    expect(source.clearCacheCalls, 1);
    expect(source.requestedPages, [2]);
    expect(state.page, 2);
    expect(state.games, hasLength(30));
    expect(state.games.first.threadId, 30);
  });

  test('refresh keeps the sort and server-side filters', () async {
    final source = FakeMetadataSource(
      List.generate(90, (i) => makeGame(i)),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.setTags(const {45});
    await notifier.setPrefixes(const {3});
    await notifier.setDate(7);
    await notifier.setSort(SortOrder.likes);
    await notifier.nextPage();
    expect(container.read(gameListProvider).page, 2);

    await notifier.refresh();

    final state = container.read(gameListProvider);
    expect(state.page, 2);
    expect(state.sort, SortOrder.likes);
    expect(state.selectedTags, {45});
    expect(state.selectedPrefixes, {3});
    expect(state.date, 7);
    expect(source.lastPage, 2);
    expect(source.lastSort, SortOrder.likes);
    expect(source.lastTags, [45]);
    expect(source.lastPrefixes, [3]);
    expect(source.lastDate, 7);
  });

  test('refresh also re-fetches the tag table', () async {
    final source = FakeMetadataSource(
      [makeGame(0, tagIds: const [45])],
      tagTable: makeTagTable(),
    );
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.load();
    final callsAfterLoad = source.tagTableCalls;

    await notifier.refresh();

    expect(source.tagTableCalls, callsAfterLoad + 1);
    expect(container.read(gameListProvider).games.single.tags, ['rpg']);
  });

  test('refresh before the first load fetches page 1', () async {
    final source = FakeMetadataSource(List.generate(30, (i) => makeGame(i)));
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);

    await notifier.refresh();

    final state = container.read(gameListProvider);
    expect(source.requestedPages, [1]);
    expect(state.page, 1);
    expect(state.games, hasLength(30));
  });

  test('refresh is a no-op while a load is in flight', () async {
    final source = FakeMetadataSource(List.generate(30, (i) => makeGame(i)));
    final container = makeContainer(source);
    final notifier = container.read(gameListProvider.notifier);
    await notifier.load();

    source.listGate = Completer<void>();
    final inFlight = notifier.refresh();
    await pumpEventQueue();

    await notifier.refresh();
    expect(source.clearCacheCalls, 1);
    expect(source.listCalls, 2); // load + the single in-flight refresh

    source.listGate!.complete();
    source.listGate = null;
    await inFlight;
  });

  test('a throttle signal flips the throttled flag', () async {
    final source = FakeMetadataSource(List.generate(10, (i) => makeGame(i)));
    final container = makeContainer(source);
    await container.read(gameListProvider.notifier).load();

    source.setThrottled(true);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(gameListProvider).throttled, isTrue);

    source.setThrottled(false);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(gameListProvider).throttled, isFalse);
  });

  test('metadataSourceProvider paces with the configured interval', () async {
    final store = FakeConfigStore(
      toLoad: const Config(requestIntervalMs: 750),
    );
    final container = ProviderContainer(
      overrides: [configStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final source = container.read(metadataSourceProvider);
    expect(source, isA<F95zoneMetadataSource>());
    // Before the config loads, the default applies.
    expect(
      (source as F95zoneMetadataSource).requestInterval,
      const Duration(milliseconds: Config.defaultRequestIntervalMs),
    );

    await container.read(configProvider.notifier).load();

    expect(
      (container.read(metadataSourceProvider) as F95zoneMetadataSource)
          .requestInterval,
      const Duration(milliseconds: 750),
    );
  });
}
