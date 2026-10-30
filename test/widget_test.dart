import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/main.dart';
import 'package:f95hub/pages/dashboard_page.dart';
import 'package:f95hub/pages/home_shell.dart';
import 'package:f95hub/pages/library_page.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/theme/app_theme.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

Widget _scope(Widget child) {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
      libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
      libraryDatabaseProvider.overrideWithValue(db),
      configStoreProvider.overrideWithValue(
        FakeConfigStore(
          toLoad: const Config(downloadDir: r'C:\games'),
        ),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('App boots into the shell with a hamburger menu', (
    tester,
  ) async {
    await tester.pumpWidget(_scope(const App()));
    await tester.pump();

    expect(find.byType(App), findsOneWidget);
    expect(find.byType(HomeShell), findsOneWidget);
    // The shell boots onto the dashboard; games stays one tap away.
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shell switches to the Library tab', (tester) async {
    await tester.pumpWidget(_scope(const App()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.text('No games in your library yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeShell golden', (tester) async {
    await tester.pumpWidget(_scope(const App()));
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byType(HomeShell),
      matchesGoldenFile('goldens/home_shell.png'),
    );
  });

  testWidgets('light/dark toggle rebuilds MaterialApp and persists themeMode',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        libraryDatabaseProvider.overrideWithValue(db),
        configStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );
    await tester.pump();

    ThemeMode modeOf() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    // Defaults to following the platform.
    expect(modeOf(), ThemeMode.system);
    expect(
      Theme.of(tester.element(find.byType(HomeShell))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme_mode_toggle')));
    await tester.pumpAndSettle();

    expect(store.saved?.themeMode, AppThemeMode.dark);
    expect(store.saved?.downloadDir, r'C:\games');
    expect(modeOf(), ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(HomeShell))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaterialApp themeMode follows the persisted config',
      (tester) async {
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        libraryDatabaseProvider.overrideWithValue(db),
        configStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );
    await tester.pump();

    await container.read(configProvider.notifier).save(
          const Config(
            downloadDir: r'C:\games',
            themeMode: AppThemeMode.dark,
          ),
        );
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).darkTheme!.brightness,
      Brightness.dark,
    );
  });

  testWidgets('MaterialApp theme follows the persisted config theme',
      (tester) async {
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        libraryDatabaseProvider.overrideWithValue(db),
        configStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );
    await tester.pump();

    ThemeData themeOf() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;

    // Default theme is the material preset.
    expect(
      themeOf().colorScheme,
      buildThemes(ThemePreset.material).light.colorScheme,
    );

    // Switching the persisted theme updates the MaterialApp immediately.
    await container.read(configProvider.notifier).save(
          const Config(downloadDir: r'C:\games', theme: ThemePreset.blue),
        );
    await tester.pump();

    expect(
      themeOf().colorScheme,
      buildThemes(ThemePreset.blue).light.colorScheme,
    );
  });
}
