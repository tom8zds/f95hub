import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/pages/home_shell.dart';
import 'package:f95hub/pages/settings_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

({Widget widget, ProviderContainer container}) _scopeWith(
  Widget child, {
  FakeConfigStore? store,
}) {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
      libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
      libraryDatabaseProvider.overrideWithValue(db),
      configStoreProvider.overrideWithValue(
        store ??
            FakeConfigStore(
              toLoad: const Config(downloadDir: r'C:\games'),
            ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (
    widget: UncontrolledProviderScope(container: container, child: child),
    container: container,
  );
}

Widget _scope(Widget child, {FakeConfigStore? store}) =>
    _scopeWith(child, store: store).widget;

/// Pumps the shell inside a scope whose config has been loaded (so the shell's
/// theme toggle has a config to write to).
Future<ProviderContainer> _pumpLoadedShell(
  WidgetTester tester, {
  required FakeConfigStore store,
}) async {
  final scoped = _scopeWith(_shell(), store: store);
  await tester.pumpWidget(scoped.widget);
  await scoped.container.read(configProvider.notifier).load();
  await tester.pump();
  return scoped.container;
}

Widget _shell() => const MaterialApp(home: HomeShell());

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('uses a hamburger drawer when narrow', (tester) async {
    _setSize(tester, const Size(800, 600));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('uses an inline navigation drawer as the sidebar when wide', (
    tester,
  ) async {
    _setSize(tester, const Size(1200, 800));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the inline sidebar switches to the Library tab when wide', (
    tester,
  ) async {
    _setSize(tester, const Size(1200, 800));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    await tester.tap(find.text('Library').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('No games in your library yet'), findsOneWidget);
  });

  testWidgets('drawer opens, selects Settings, and closes when narrow', (
    tester,
  ) async {
    _setSize(tester, const Size(800, 600));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    expect(find.byType(NavigationDrawer), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('narrow drawer hosts the light/dark toggle and persists it',
      (tester) async {
    _setSize(tester, const Size(800, 600));
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );

    await _pumpLoadedShell(tester, store: store);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final toggle = find.descendant(
      of: find.byType(NavigationDrawer),
      matching: find.byKey(const ValueKey('theme_mode_toggle')),
    );
    expect(toggle, findsOneWidget);
    expect(find.byType(Switch), findsNothing);

    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();

    expect(store.saved?.themeMode, AppThemeMode.dark);
    expect(store.saved?.downloadDir, r'C:\games');
    // The drawer stays open: the toggle is not a navigation destination.
    expect(find.byType(NavigationDrawer), findsOneWidget);
  });

  testWidgets('wide sidebar footer toggle flips and persists themeMode',
      (tester) async {
    _setSize(tester, const Size(1200, 800));
    final store = FakeConfigStore(
      toLoad: const Config(downloadDir: r'C:\games'),
    );

    await _pumpLoadedShell(tester, store: store);

    // The toggle rides in the drawer's footer slot as a single icon button.
    final toggle = find.byKey(const ValueKey('theme_mode_toggle'));
    expect(toggle, findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(
      find.descendant(of: toggle, matching: find.byIcon(Icons.dark_mode)),
      findsOneWidget,
    );

    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();

    expect(store.saved?.themeMode, AppThemeMode.dark);
    expect(
      find.descendant(of: toggle, matching: find.byIcon(Icons.light_mode)),
      findsOneWidget,
    );
  });

  testWidgets('settings destination shows the settings page', (tester) async {
    _setSize(tester, const Size(1200, 800));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    await tester.tap(find.text('Settings').last);
    await tester.pump();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Storage directory'), findsOneWidget);
  });

  testWidgets('narrow shell golden', (tester) async {
    _setSize(tester, const Size(800, 600));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    await expectLater(
      find.byType(HomeShell),
      matchesGoldenFile('goldens/home_shell_narrow.png'),
    );
  });

  testWidgets('wide shell golden', (tester) async {
    _setSize(tester, const Size(1200, 800));

    await tester.pumpWidget(_scope(_shell()));
    await tester.pump();

    await expectLater(
      find.byType(HomeShell),
      matchesGoldenFile('goldens/home_shell_wide.png'),
    );
  });
}
