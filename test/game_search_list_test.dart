import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/widgets/game_search_list.dart';
import 'package:f95hub/widgets/game_search_results.dart';

import 'support/fake_cache_manager.dart';
import 'support/fake_metadata_source.dart';

void main() {
  late LibraryDatabase db;
  late GameIndexStore store;

  // Covers in these tests carry URLs but no fake manager: route the default
  // manager to a fake so load attempts fail fast instead of pending forever
  // (which the animated loading placeholder would expose as a settle timeout).
  setUp(() {
    CachedNetworkImageProvider.defaultCacheManager = FakeCacheManager();
  });

  setUp(() {
    db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = GameIndexStore(
      db,
      FakeMetadataSource([
        makeGame(
          42,
          title: 'Secret Care Cafe [v0.9.5] [Rare Alex]',
          cover: 'https://preview.f95zone.to/secret.png',
          screens: const ['https://preview.f95zone.to/a.png'],
        ),
        makeGame(7, title: 'Another Game'),
        makeGame(9, title: 'Zeta Project'),
      ]),
    );
  });

  Future<void> pumpSearch(
    WidgetTester tester, {
    required GameIndexStore index,
    ValueChanged<Game>? onSelect,
    int? busyThreadId,
    String? initialQuery,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameIndexStoreProvider.overrideWithValue(index)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 420,
              child: GameSearchList(
                onSelect: onSelect ?? (_) {},
                busyThreadId: busyThreadId,
                initialQuery: initialQuery,
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The busy tile's spinner never settles; give the index query time to
      // complete with a couple of fixed pumps instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('empty query lists the index slice in title order', (
    tester,
  ) async {
    await store.buildAll();

    await pumpSearch(tester, index: store);

    expect(find.text('Another Game'), findsOneWidget);
    expect(find.text('Secret Care Cafe [v0.9.5] [Rare Alex]'), findsOneWidget);
    expect(find.text('Zeta Project'), findsOneWidget);
  });

  testWidgets('typing searches the normalized local index after the debounce', (
    tester,
  ) async {
    await store.buildAll();
    await pumpSearch(tester, index: store);

    await tester.enterText(find.byType(TextField), 'secret care cafe');
    await tester.pump(GameSearchList.searchDebounce);
    await tester.pumpAndSettle();

    expect(find.text('Secret Care Cafe [v0.9.5] [Rare Alex]'), findsOneWidget);
    expect(find.text('Another Game'), findsNothing);
    expect(find.text('Zeta Project'), findsNothing);
  });

  testWidgets('initialQuery is pre-filled and searched immediately', (
    tester,
  ) async {
    await store.buildAll();

    await pumpSearch(
      tester,
      index: store,
      initialQuery: 'Secret Care Cafe',
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Secret Care Cafe',
    );
    expect(find.text('Secret Care Cafe [v0.9.5] [Rare Alex]'), findsOneWidget);
    expect(find.text('Another Game'), findsNothing);
  });

  testWidgets('initialQuery exact match is floated to the top and highlighted', (
    tester,
  ) async {
    final index = GameIndexStore(
      db,
      FakeMetadataSource([
        makeGame(2, title: 'Others - Secret Care Cafe 2'),
        makeGame(1, title: 'Secret Care Cafe [v0.9.5] [Rare Alex]'),
      ]),
    );
    await index.buildAll();

    await pumpSearch(
      tester,
      index: index,
      initialQuery: 'Secret Care Cafe',
    );

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles, hasLength(2));
    // Exact normalized hit first, even though "Others - …" sorts first by
    // raw title.
    expect((tiles.first.title! as Text).data, 'Secret Care Cafe [v0.9.5] [Rare Alex]');
    expect(tiles.first.selected, isTrue);
    expect(tiles.last.selected, isFalse);
  });

  testWidgets('selecting a cached row returns a listing-shaped Game', (
    tester,
  ) async {
    await store.buildAll();
    Game? selected;

    await pumpSearch(tester, index: store, onSelect: (game) => selected = game);
    await tester.tap(find.text('Secret Care Cafe [v0.9.5] [Rare Alex]'));
    await tester.pump();

    expect(selected?.threadId, 42);
    expect(selected?.title, 'Secret Care Cafe [v0.9.5] [Rare Alex]');
    expect(selected?.cover, 'https://preview.f95zone.to/secret.png');
    expect(selected?.screens, ['https://preview.f95zone.to/a.png']);
  });

  testWidgets('empty index shows the build-the-cache hint', (tester) async {
    // Index never built: count == 0.
    await pumpSearch(tester, index: store);

    expect(find.byType(GameIndexEmptyHint), findsOneWidget);
    expect(find.text('Game index is empty'), findsOneWidget);
    expect(find.textContaining('Settings'), findsOneWidget);
    expect(find.text('No matches'), findsNothing);
  });

  testWidgets('no matches for a query against a populated index', (
    tester,
  ) async {
    await store.buildAll();
    await pumpSearch(tester, index: store);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pump(GameSearchList.searchDebounce);
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(find.byType(GameIndexEmptyHint), findsNothing);
  });

  testWidgets('busyThreadId disables the list while importing', (tester) async {
    await store.buildAll();
    var taps = 0;

    await pumpSearch(
      tester,
      index: store,
      busyThreadId: 42,
      onSelect: (_) => taps++,
      settle: false,
    );

    await tester.tap(
      find.text('Secret Care Cafe [v0.9.5] [Rare Alex]'),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(taps, 0);
  });
}
