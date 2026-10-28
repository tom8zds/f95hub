import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/pages/game_detail_page.dart';
import 'package:f95hub/pages/games_page.dart';
import 'package:f95hub/pages/home_shell.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/game_card.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

Widget _scope(FakeMetadataSource source, Widget child) {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      metadataSourceProvider.overrideWithValue(source),
      libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
      libraryDatabaseProvider.overrideWithValue(db),
      configStoreProvider.overrideWithValue(
        FakeConfigStore(toLoad: const Config(downloadDir: r'C:\games')),
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(container: container, child: child);
}

void main() {
  testWidgets('right-clicking a games card opens a menu; 详情 pushes detail', (
    tester,
  ) async {
    final source = FakeMetadataSource([makeGame(7, title: 'Kunoichi Sensei')]);

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

    await tester.tap(find.byType(GameCard), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(find.text('View detail'), findsOneWidget);
    expect(find.text('Add to library'), findsOneWidget);

    await tester.tap(find.text('View detail'));
    await tester.pumpAndSettle();

    expect(find.byType(GameDetailPage), findsOneWidget);
  });

  testWidgets('Ctrl+F focuses the games search field', (tester) async {
    final source = FakeMetadataSource([makeGame(7)]);

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

    expect(find.byType(TextField), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();

    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('the games filter button shows an active-filter count', (
    tester,
  ) async {
    final source = FakeMetadataSource([makeGame(7)]);
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(source),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        libraryDatabaseProvider.overrideWithValue(db),
        configStoreProvider.overrideWithValue(
          FakeConfigStore(toLoad: const Config(downloadDir: r'C:\games')),
        ),
      ],
    );
    addTearDown(container.dispose);
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

    // No filters yet: badge label hidden.
    var badge = tester.widget<Badge>(find.byType(Badge).first);
    expect(badge.isLabelVisible, isFalse);

    await container.read(gameListProvider.notifier).setTags(const {45});
    await tester.pump();

    badge = tester.widget<Badge>(find.byType(Badge).first);
    expect(badge.isLabelVisible, isTrue);
  });

  testWidgets('wide shells host the navigation drawer inline as the sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _scope(
        FakeMetadataSource(const []),
        const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();

    // The official drawer is the permanent sidebar; the rail is gone.
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    // Its footer (theme toggle) is part of the drawer.
    expect(find.byKey(const ValueKey('theme_mode_toggle')), findsOneWidget);
  });

  testWidgets('narrow shells open the drawer from the hamburger instead', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _scope(
        FakeMetadataSource(const []),
        const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();

    // Sidebar not inline on narrow windows; opened via the hamburger.
    expect(find.byType(NavigationDrawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);
  });
}
