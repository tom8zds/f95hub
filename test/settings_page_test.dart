import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/pages/settings_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/state/session.dart';
import 'package:f95hub/widgets/theme_swatch_picker.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';
import 'support/fake_session_store.dart';

/// An in-memory database for the settings page's cache section.
LibraryDatabase _memoryDatabase() {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Future<void> _golden(WidgetTester tester, Widget widget, String name) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: widget)),
    ),
  );
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('StorageDirSection golden (set)', (tester) async {
    await _golden(
      tester,
      StorageDirSection(
        value: r'D:\library',
        fallback: r'C:\games',
        onBrowse: () {},
      ),
      'settings_storage_dir_section',
    );
  });

  testWidgets('StorageDirSection golden (unset fallback)', (tester) async {
    await _golden(
      tester,
      StorageDirSection(
        value: null,
        fallback: r'C:\games',
        onBrowse: () {},
      ),
      'settings_storage_dir_section_unset',
    );
  });

  testWidgets('LoginSection golden', (tester) async {
    await _golden(
      tester,
      LoginSection(session: null, onLogin: (_) async {}, onLogout: () {}),
      'settings_login_section',
    );
  });

  testWidgets('LoginSection golden (logged in)', (tester) async {
    await _golden(
      tester,
      LoginSection(
        session: 'xf_user=abc; cf_clearance=xyz',
        onLogin: (_) async {},
        onLogout: () {},
      ),
      'settings_login_section_logged_in',
    );
  });

  testWidgets('LoginSection offers only a cookie input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginSection(
            session: null,
            onLogin: (_) async {},
            onLogout: () {},
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Session cookie'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('ThemeSection golden', (tester) async {
    await _golden(
      tester,
      ThemeSection(value: ThemePreset.blue, onChanged: (_) {}),
      'settings_theme_section',
    );
  });

  testWidgets('ThemeSection renders one swatch per preset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemeSection(value: ThemePreset.material, onChanged: (_) {}),
        ),
      ),
    );
    expect(find.byType(ThemeSwatch), findsNWidgets(5));
    for (final preset in ThemePreset.values) {
      expect(
        find.byKey(ValueKey('theme_swatch_${preset.name}')),
        findsOneWidget,
      );
    }
    // The active preset is the only one with a check badge.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(RadioListTile<ThemePreset>), findsNothing);
  });

  testWidgets('SettingsPage golden', (tester) async {
    final store = FakeConfigStore(
      toLoad: const Config(
        downloadDir: r'C:\games',
        storageDir: r'D:\library',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryDatabaseProvider.overrideWithValue(_memoryDatabase()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await container.read(configProvider.notifier).load();
    await tester.pump();

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('goldens/settings_page.png'),
    );
  });

  testWidgets('browsing a storage dir persists it and repoints the library root',
      (tester) async {
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryDatabaseProvider.overrideWithValue(_memoryDatabase()),
        directoryPickerProvider
            .overrideWith((ref) => () async => r'D:\library'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await container.read(configProvider.notifier).load();
    await tester.pump();

    // Before: library root falls back to the download dir.
    expect(container.read(libraryRootProvider), r'C:\games');

    await tester.tap(find.text('Browse'));
    await tester.pump();
    await tester.pump();

    // The picked storage dir is persisted immediately and becomes the root.
    expect(store.saved, isNotNull);
    expect(store.saved!.storageDir, r'D:\library');
    expect(store.saved!.downloadDir, r'C:\games');
    expect(container.read(libraryRootProvider), r'D:\library');
  });

  testWidgets('login and logout drive the session provider', (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final sessionStore = FakeSessionStore();
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        sessionStoreProvider.overrideWithValue(sessionStore),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryDatabaseProvider.overrideWithValue(_memoryDatabase()),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await container.read(configProvider.notifier).load();
    await tester.pump();

    expect(container.read(sessionProvider), isNull);

    // Log in via a pasted cookie (login section's cookie field).
    await tester.enterText(find.byType(TextFormField).at(1), 'xf_user=abc');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump();

    expect(container.read(sessionProvider), 'xf_user=abc');
    expect(sessionStore.cookie, 'xf_user=abc');

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(container.read(sessionProvider), isNull);
    expect(sessionStore.cookie, isNull);
  });

  testWidgets('selecting a theme persists it through the config store',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryDatabaseProvider.overrideWithValue(_memoryDatabase()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await container.read(configProvider.notifier).load();
    await tester.pump();

    // Default theme is material.
    expect(container.read(configProvider).config?.theme, ThemePreset.material);

    await tester.tap(find.byKey(const ValueKey('theme_swatch_red')));
    await tester.pump();

    // The selection is written through immediately and reflects in state.
    expect(store.saved?.theme, ThemePreset.red);
    expect(store.saved?.downloadDir, r'C:\games');
    expect(container.read(configProvider).config?.theme, ThemePreset.red);
  });

  testWidgets('the fetch interval is edited in seconds and persisted in ms',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryDatabaseProvider.overrideWithValue(_memoryDatabase()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await container.read(configProvider.notifier).load();
    await tester.pump();

    // The interval field is the first one on the page (network section).
    expect(find.text('Fetch interval (seconds)'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '1.5');
    await tester.pump();

    expect(store.saved?.requestIntervalMs, 1500);
    expect(container.read(configProvider).config?.requestIntervalMs, 1500);
  });
}
