import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/config.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/pages/games_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/widgets/filter_drawer.dart';
import 'package:f95hub/widgets/game_card.dart';
import 'package:f95hub/widgets/search_field.dart';
import 'package:f95hub/widgets/page_frame.dart';
import 'package:f95hub/widgets/sort_sheet.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

Widget _scope(FakeMetadataSource source, Widget child) {
  return ProviderScope(
    overrides: [metadataSourceProvider.overrideWithValue(source)],
    child: child,
  );
}

/// Asserts the pagination chips show [page] / [total].
void expectPage(WidgetTester tester, int page, int total) {
  Text chip(String key) =>
      tester.widget<Chip>(find.byKey(Key(key))).label as Text;
  expect(chip('page-current').data, '$page');
  expect(chip('page-total').data, '$total');
}

void main() {
  testWidgets('GamesPage renders the loaded grid of cards', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    // Settle the initial load (microtask + resolved future).
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameCard), findsNWidgets(6));

    await expectLater(
      find.byType(GamesPage),
      matchesGoldenFile('goldens/games_page.png'),
    );
  });

  testWidgets('shows the page loading bar while the listing loads', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    )..listGate = Completer<void>();

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageLoadingBar), findsOneWidget);

    source.listGate!.complete();
    source.listGate = null;
    await tester.pump();
    await tester.pump();

    expect(find.byType(PageLoadingBar), findsNothing);
    expect(find.byType(GameCard), findsNWidgets(6));
  });

  testWidgets('GamesPage shows an error state with a retry button', (
    tester,
  ) async {
    final source = FakeMetadataSource(const [])..fail = true;

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to load games'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('AppBar hosts the search field and filter/sort buttons', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Search field is the AppBar title (no inline TextField in the body).
    expect(find.byType(SearchField), findsOneWidget);
    expect(find.byKey(const Key('games-refresh-button')), findsOneWidget);
    expect(find.byKey(const Key('games-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('games-sort-button')), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byIcon(Icons.sort), findsOneWidget);
  });

  testWidgets('typing in the search field filters the grid locally', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameCard), findsNWidgets(6));

    await tester.enterText(
      find.byType(SearchField),
      'Sample Game 2',
    );
    await tester.pump();

    expect(find.byType(GameCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GameCard),
        matching: find.text('Sample Game 2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('filter button opens an end drawer hosting GameFilters', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
      tagTable: makeTagTable(),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FilterDrawer), findsNothing);

    await tester.tap(find.byKey(const Key('games-filter-button')));
    await tester.pumpAndSettle();

    expect(find.byType(FilterDrawer), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    // The tags live inside the multi-select field; the placeholder ("All") is
    // what renders, one per section.
    expect(find.text('All'), findsNWidgets(3));
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('selecting a tag in the filter dropdown flows into the list '
      'state', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
      tagTable: makeTagTable(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [metadataSourceProvider.overrideWithValue(source)],
        child: const MaterialApp(home: GamesPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('games-filter-button')));
    await tester.pumpAndSettle();

    expect(source.lastTags, isNull);

    await tester.tap(find.byKey(const ValueKey('filter-section-Category')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'rpg'));
    await tester.pumpAndSettle();

    expect(source.lastTags, [45]);
  });

  testWidgets('filter drawer closes on 应用', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
      tagTable: makeTagTable(),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('games-filter-button')));
    await tester.pumpAndSettle();
    expect(find.byType(FilterDrawer), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-apply')));
    await tester.pumpAndSettle();

    expect(find.byType(FilterDrawer), findsNothing);
  });

  testWidgets('sort button opens a sheet with each sort option', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(SortSheet), findsNothing);

    await tester.tap(find.byKey(const Key('games-sort-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SortSheet), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);
    for (final label in ['Date', 'Likes', 'Views', 'Title', 'Rating']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('choosing a sort option flows into the list state and closes', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('games-sort-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expect(source.lastSort, SortOrder.likes);
    expect(find.byType(SortSheet), findsNothing);
  });

  testWidgets('shows a throttle notice while backing off', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Rate limited, retrying'), findsNothing);

    source.setThrottled(true);
    await tester.pumpAndSettle();
    expect(find.text('Rate limited, retrying'), findsOneWidget);

    source.setThrottled(false);
    await tester.pumpAndSettle();
    expect(find.text('Rate limited, retrying'), findsNothing);
  });

  testWidgets('page controls navigate and disable at boundaries', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expectPage(tester, 1, 2);
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-prev'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('page-next')));
    await tester.pump();
    await tester.pump();

    expectPage(tester, 2, 2);
    expect(source.lastPage, 2);
    // Page 2 content replaces page 1: the second page's first card shows.
    expect(find.text('Sample Game 30'), findsOneWidget);

    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-next'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('page-prev')));
    await tester.pump();
    await tester.pump();

    expectPage(tester, 1, 2);
    expect(source.lastPage, 1);
    expect(find.text('Sample Game 0'), findsOneWidget);
  });

  testWidgets('the AppBar refresh button re-fetches the current page', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('page-next')));
    await tester.pump();
    await tester.pump();
    expectPage(tester, 2, 2);

    await tester.tap(find.byKey(const Key('games-refresh-button')));
    await tester.pump();
    await tester.pump();

    expect(source.clearCacheCalls, 1);
    expect(source.lastPage, 2);
    expectPage(tester, 2, 2);
    expect(find.text('Sample Game 30'), findsOneWidget);
  });

  testWidgets('the refresh button is disabled while the listing loads', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    )..listGate = Completer<void>();

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();

    IconButton refreshButton() => tester.widget<IconButton>(
      find.byKey(const Key('games-refresh-button')),
    );

    expect(refreshButton().onPressed, isNull);

    source.listGate!.complete();
    source.listGate = null;
    await tester.pump();
    await tester.pump();
    expect(refreshButton().onPressed, isNotNull);

    // A refresh in flight disables the button again.
    source.listGate = Completer<void>();
    await tester.tap(find.byKey(const Key('games-refresh-button')));
    await tester.pump();
    expect(refreshButton().onPressed, isNull);

    source.listGate!.complete();
    source.listGate = null;
    await tester.pump();
    await tester.pump();
    expect(refreshButton().onPressed, isNotNull);
  });

  testWidgets('changing sort resets to page 1', (tester) async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('page-next')));
    await tester.pump();
    await tester.pump();
    expectPage(tester, 2, 2);

    await tester.tap(find.byKey(const Key('games-sort-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expectPage(tester, 1, 2);
    expect(source.lastSort, SortOrder.likes);
    expect(source.lastPage, 1);
  });

  testWidgets('paging resets the grid scroll to the top', (tester) async {
    final source = FakeMetadataSource(
      List.generate(60, (i) => makeGame(i, title: 'Sample Game $i')),
    );

    await tester.pumpWidget(
      _scope(
        source,
        const MaterialApp(
          home: SizedBox(width: 900, height: 600, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expectPage(tester, 1, 2);

    final grid = find.byType(GridView);
    await tester.drag(grid, const Offset(0, -500));
    await tester.pump();
    expect(tester.widget<GridView>(grid).controller!.offset, greaterThan(0));

    await tester.tap(find.byKey(const Key('page-next')));
    await tester.pumpAndSettle();

    expect(tester.widget<GridView>(grid).controller!.offset, 0);
  });

  testWidgets('switching the theme keeps the loaded listing', (tester) async {
    final source = FakeMetadataSource(
      List.generate(6, (i) => makeGame(i, title: 'Sample Game $i')),
    );
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(source),
        configStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(configProvider.notifier).load();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GamesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Sample Game 0'), findsOneWidget);

    await container.read(configProvider.notifier).save(
      container.read(configProvider).config!.copyWith(theme: ThemePreset.red),
    );
    await tester.pump();
    await tester.pump();

    // The listing survived the theme write (the source was not recreated).
    expect(find.text('Sample Game 0'), findsOneWidget);
    expect(find.text('Sample Game 5'), findsOneWidget);
  });
}
