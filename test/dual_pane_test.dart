import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/pages/games_page.dart';
import 'package:f95hub/pages/library_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/detail_tabs.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/detail_pane.dart';
import 'package:f95hub/widgets/game_card.dart';
import 'package:f95hub/pages/library_detail_page.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

void main() {
  group('DetailTabsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    Game game(int id, String title) => Game(
      threadId: id,
      title: title,
      creator: 'dev',
      createdAt: DateTime(2026, 10, 25),
      updatedAt: DateTime(2026, 10, 25),
    );

    DetailTabsController controller() =>
        container.read(detailTabsProvider(DetailPaneScope.games).notifier);

    test('open appends and activates; reopening activates without duplicating',
        () {
      controller().open(game(1, 'One'));
      controller().open(game(2, 'Two'));

      var state = container.read(detailTabsProvider(DetailPaneScope.games));
      expect(state.tabs.map((t) => t.threadId), [1, 2]);
      expect(state.activeThreadId, 2);

      controller().open(game(1, 'One'));
      state = container.read(detailTabsProvider(DetailPaneScope.games));
      expect(state.tabs, hasLength(2));
      expect(state.activeThreadId, 1);
    });

    test('closing the active tab activates its left neighbour', () {
      controller()
        ..open(game(1, 'One'))
        ..open(game(2, 'Two'))
        ..open(game(3, 'Three'));
      controller().close(3);

      final state = container.read(detailTabsProvider(DetailPaneScope.games));
      expect(state.tabs.map((t) => t.threadId), [1, 2]);
      expect(state.activeThreadId, 2);
    });

    test('closing the last tab empties the pane; closeAll collapses', () {
      controller()
        ..open(game(1, 'One'))
        ..open(game(2, 'Two'));
      controller().closeAll();

      expect(
        container.read(detailTabsProvider(DetailPaneScope.games)).isEmpty,
        isTrue,
      );

      controller().open(game(9, 'Nine'));
      controller().close(9);
      expect(
        container.read(detailTabsProvider(DetailPaneScope.games)).activeThreadId,
        isNull,
      );
    });

    test('scopes keep independent tab sets', () {
      controller().open(game(1, 'One'));
      container
          .read(detailTabsProvider(DetailPaneScope.library).notifier)
          .open(game(5, 'Five'));

      expect(
        container
            .read(detailTabsProvider(DetailPaneScope.games))
            .tabs
            .map((t) => t.threadId),
        [1],
      );
      expect(
        container
            .read(detailTabsProvider(DetailPaneScope.library))
            .tabs
            .map((t) => t.threadId),
        [5],
      );
    });
  });

  Widget gamesScopeWidget(FakeMetadataSource source) {
    return ProviderScope(
      overrides: [metadataSourceProvider.overrideWithValue(source)],
      child: const MaterialApp(
        home: SizedBox(width: 1280, height: 800, child: GamesPage()),
      ),
    );
  }

  testWidgets('wide games page opens detail tabs instead of routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final source = FakeMetadataSource([
      makeGame(1, title: 'Alpha Game'),
      makeGame(2, title: 'Beta Game'),
    ]);

    await tester.pumpWidget(gamesScopeWidget(source));
    await tester.pump();
    await tester.pump();

    // Two cards open two tabs; no route is pushed.
    await tester.tap(find.text('Alpha Game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameCard), findsNWidgets(2));
    expect(find.byType(DetailTabsPane), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-tab-chip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-tab-chip-2')), findsOneWidget);
    // Beta is the active tab: its title renders inside the pane's content.
    expect(
      tester.widget<Text>(find.descendant(
        of: find.byType(DetailTabsPane),
        matching: find.text('Beta Game'),
      )),
      isNotNull,
    );

    // Switching to the first chip activates Alpha's tab.
    await tester.tap(find.byKey(const ValueKey('detail-tab-chip-1')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DetailTabsPane),
        matching: find.text('Alpha Game'),
      ),
      findsWidgets,
    );

    // Closing both tabs collapses the pane.
    await tester.tap(find.byKey(const Key('detail-pane-close-all')));
    await tester.pumpAndSettle();
    expect(find.byType(DetailTabsPane), findsNothing);
  });

  testWidgets('narrow games page keeps pushing the detail route', (
    tester,
  ) async {
    final source = FakeMetadataSource(
      [makeGame(1, title: 'Alpha Game')],
      threadDetails: {1: makeThreadDetail(1, title: 'Alpha Game')},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [metadataSourceProvider.overrideWithValue(source)],
        child: const MaterialApp(home: GamesPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Alpha Game'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailTabsPane), findsNothing);
    expect(find.text('Alpha Game'), findsWidgets);
  });

  testWidgets('wide library page opens pane tabs instead of a route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftLibraryStore(db).upsertGame(
      Game(
        threadId: 7,
        title: 'Kunoichi Sensei',
        creator: 'NTRNoob',
        version: 'v0.0.1',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
          libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
          libraryDatabaseProvider.overrideWithValue(db),
          configStoreProvider.overrideWithValue(
            FakeConfigStore(toLoad: const Config(downloadDir: r'C:\games')),
          ),
        ],
        child: const MaterialApp(
          home: SizedBox(width: 1280, height: 800, child: LibraryPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Kunoichi Sensei'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryDetailPage), findsNothing);
    expect(find.byType(DetailTabsPane), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-tab-chip-7')), findsOneWidget);
  });
}
