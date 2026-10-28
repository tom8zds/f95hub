import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/app_launcher.dart';
import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/pages/library_detail_page.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/cover_image.dart';
import 'package:f95hub/widgets/library_actions.dart';
import 'package:f95hub/widgets/library_detail.dart';
import 'package:f95hub/widgets/screenshot_gallery.dart';

import 'support/fake_app_launcher.dart';
import 'support/fake_cache_manager.dart';
import 'support/fake_metadata_source.dart';
import 'support/fake_process_runner.dart';

Game _game({String? installPath, String? launchPath}) => Game(
  threadId: 7,
  title: 'Kunoichi Sensei',
  creator: 'NTRNoob',
  version: 'v0.0.1',
  latestVersion: 'v0.0.2',
  installPath: installPath,
  launchPath: launchPath,
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 24),
);

/// A game with every scraped metadata field the dialog renders.
Game _fullGame() => Game(
  threadId: 7,
  title: 'Kunoichi Sensei',
  creator: 'NTRNoob',
  version: 'v0.0.1',
  latestVersion: 'v0.0.2',
  cover: 'https://preview.f95zone.to/cover.png',
  screens: const [
    'https://preview.f95zone.to/screen1.png',
    'https://preview.f95zone.to/screen2.png',
  ],
  tags: const ['rpg', '3dcg'],
  description: 'A description scraped from the thread page.',
  installPath: r'C:\games\game7',
  launchPath: r'C:\games\game7\Game.exe',
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 24),
);

PlayStats _stats() => PlayStats(
  total: const Duration(hours: 1, minutes: 30),
  sessions: [
    PlaySession(
      id: 2,
      threadId: 7,
      startedAt: DateTime(2026, 10, 24, 20),
      endedAt: DateTime(2026, 10, 24, 21, 30),
      durationSeconds: 90 * 60,
    ),
    PlaySession(
      id: 1,
      threadId: 7,
      startedAt: DateTime(2026, 10, 23, 18),
      endedAt: DateTime(2026, 10, 23, 18, 5),
      durationSeconds: 300,
    ),
  ],
);

Widget _host({
  required LibraryDatabase db,
  required Game game,
  AppLauncher? launcher,
  ProcessRunner? runner,
  LaunchEntryScanner? scanner,
  BaseCacheManager? cacheManager,
}) {
  return ProviderScope(
    overrides: [
      metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
      libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
      if (launcher != null) appLauncherProvider.overrideWithValue(launcher),
      if (runner != null) processRunnerProvider.overrideWithValue(runner),
      if (scanner != null) launchEntryScannerProvider.overrideWithValue(scanner),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LibraryDetailPage(
                  game: game,
                  cacheManager: cacheManager,
                ),
              ),
            ),
            child: const Text('open detail'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDetail(
  WidgetTester tester, {
  required LibraryDatabase db,
  required Game game,
  AppLauncher? launcher,
  ProcessRunner? runner,
  LaunchEntryScanner? scanner,
  BaseCacheManager? cacheManager,
}) async {
  await tester.pumpWidget(
    _host(
      db: db,
      game: game,
      launcher: launcher,
      runner: runner,
      scanner: scanner,
      cacheManager: cacheManager,
    ),
  );
  await tester.tap(find.text('open detail'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('LibraryDetailView renders versions, playtime and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: LibraryDetailView(
              game: _game(
                installPath: r'C:\games\game7',
                launchPath: r'C:\games\game7\Game.exe',
              ),
              stats: _stats(),
              onPickLaunchEntry: () {},
              onOpenFolder: () {},
              onLaunch: () {},
              onEditVersion: () {},
              onRemove: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Kunoichi Sensei'), findsOneWidget);
    expect(find.text('NTRNoob'), findsOneWidget);
    expect(find.text('v0.0.1'), findsOneWidget);
    expect(find.text('v0.0.2'), findsOneWidget);
    expect(find.text('Different'), findsOneWidget);
    expect(find.text('Play time'), findsOneWidget);
    expect(find.text('Total: 1h 30m'), findsOneWidget);
    expect(find.text('Game.exe'), findsOneWidget);
    expect(find.text('2026-10-24 20:00'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('5m 00s'), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('Launch game'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await expectLater(
      find.byType(LibraryDetailView),
      matchesGoldenFile('goldens/library_detail_view.png'),
    );
  });

  testWidgets('LibraryDetailView stacks a single column below the breakpoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 1100,
            child: LibraryDetailView(
              game: _fullGame(),
              stats: _stats(),
              cacheManager: FakeCacheManager(),
              onPickLaunchEntry: () {},
              onOpenFolder: () {},
              onLaunch: () {},
              onEditVersion: () {},
              onRemove: () {},
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(LibraryDetailView),
      matchesGoldenFile('goldens/library_detail_view_narrow.png'),
    );
  });

  testWidgets('LibraryDetailView shows the empty session state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryDetailView(
            game: _game(),
            onOpenFolder: () {},
            onLaunch: () {},
            onEditVersion: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(find.text('No play sessions yet'), findsOneWidget);
    expect(find.text('Not selected'), findsOneWidget);
    expect(find.text('Total: 0s'), findsOneWidget);
  });

  testWidgets('the detail page renders the complete detail including images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = FakeCacheManager();
    await _openDetail(
      tester,
      db: db,
      game: _fullGame(),
      cacheManager: cache,
    );

    expect(find.byType(LibraryDetailPage), findsOneWidget);
    expect(find.text('Kunoichi Sensei'), findsOneWidget);
    expect(find.text('NTRNoob'), findsOneWidget);
    expect(find.byType(CoverImage), findsOneWidget);
    expect(find.byType(ScreenshotGallery), findsOneWidget);
    expect(find.text('Screenshots'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('rpg'), findsOneWidget);
    expect(find.text('3dcg'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(
      find.text('A description scraped from the thread page.'),
      findsOneWidget,
    );
    expect(find.text('v0.0.1'), findsOneWidget);
    expect(find.text('v0.0.2'), findsOneWidget);
    expect(find.text('Play time'), findsOneWidget);
    expect(find.text('Game.exe'), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('Launch game'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await expectLater(
      find.byType(LibraryDetailPage),
      matchesGoldenFile('goldens/library_detail_page.png'),
    );
  });

  testWidgets('the back button pops the detail page', (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openDetail(tester, db: db, game: _game());

    expect(find.byType(LibraryDetailPage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryDetailPage), findsNothing);
  });

  testWidgets('removing the game pops the page', (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftLibraryStore(db);
    final game = _game();
    await store.upsertGame(game);
    await _openDetail(tester, db: db, game: game);

    await tester.ensureVisible(find.byType(LibraryActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep files'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryDetailPage), findsNothing);
    expect(await store.getGame(7), isNull);
  });

  testWidgets('editing the local version persists it and refreshes the view',
      (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftLibraryStore(db);
    final game = _game();
    await store.upsertGame(game);
    await _openDetail(tester, db: db, game: game);

    expect(find.text('Different'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit version'));
    await tester.pumpAndSettle();

    expect(find.text('Edit local version'), findsOneWidget);
    final field = find.byType(TextField);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'v0.0.1',
    );

    await tester.enterText(field, 'v0.0.2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect((await store.getGame(7))!.version, 'v0.0.2');
    expect(find.text('v0.0.2'), findsNWidgets(2));
    expect(find.text('Different'), findsNothing);
  });

  testWidgets('打开目录 routes through the controller to the launcher', (
    tester,
  ) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final launcher = FakeAppLauncher();
    await _openDetail(
      tester,
      db: db,
      game: _game(installPath: r'C:\games\game7'),
      launcher: launcher,
    );

    await tester.ensureVisible(find.byType(LibraryActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open folder'));
    await tester.pump();

    expect(launcher.openedFolders, [r'C:\games\game7']);
  });

  testWidgets('启动游戏 launches the remembered entry through the runner', (
    tester,
  ) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final runner = FakeProcessRunner();
    await _openDetail(
      tester,
      db: db,
      game: _game(
        installPath: r'C:\games\game7',
        launchPath: r'C:\games\game7\Game.exe',
      ),
      runner: runner,
    );

    await tester.ensureVisible(find.byType(LibraryActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Launch game'));
    await tester.pumpAndSettle();

    expect(runner.started, [r'C:\games\game7\Game.exe']);
  });

  testWidgets('picking a launch entry remembers it before launching', (
    tester,
  ) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final runner = FakeProcessRunner();
    const entry = r'C:\games\game7\bin\Launcher.exe';
    await _openDetail(
      tester,
      db: db,
      game: _game(installPath: r'C:\games\game7'),
      runner: runner,
      scanner: (_) async => [entry, r'C:\games\game7\Game.exe'],
    );

    await tester.ensureVisible(find.byType(LibraryActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Launch game'));
    await tester.pumpAndSettle();

    expect(find.text('Choose launch entry'), findsWidgets);
    await tester.tap(find.text('Launcher.exe'));
    await tester.pumpAndSettle();

    expect(runner.started, [entry]);
    final store = DriftLibraryStore(db);
    expect((await store.getGame(7))!.launchPath, entry);
    expect(await store.sessionsFor(7), hasLength(1));
  });

  testWidgets('与工具一同启动.bat is selected without showing the picker', (
    tester,
  ) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final runner = FakeProcessRunner();
    const bat = r'C:\games\game7\与工具一同启动.bat';
    await _openDetail(
      tester,
      db: db,
      game: _game(installPath: r'C:\games\game7'),
      runner: runner,
      scanner: (_) async => [r'C:\games\game7\Game.exe', bat],
    );

    await tester.ensureVisible(find.byType(LibraryActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Launch game'));
    await tester.pumpAndSettle();

    expect(find.text('Choose launch entry'), findsNothing);
    expect(runner.started, [bat]);
    final store = DriftLibraryStore(db);
    final stored = await store.getGame(7);
    expect(stored!.launchPath, bat);
    expect(await store.sessionsFor(7), hasLength(1));
  });
}
