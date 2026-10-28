import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/state/library_view.dart';

import 'support/fake_app_launcher.dart';
import 'support/fake_clock.dart';
import 'support/fake_metadata_source.dart';
import 'support/fake_process_runner.dart';

void main() {
  late DriftLibraryStore store;
  late FakeAppLauncher launcher;
  late FakeProcessRunner runner;
  late FakeClock clock;
  late Directory tempRoot;
  late ProviderContainer container;
  late Map<int, String?> latestVersions;

  Game game({
    int threadId = 7,
    String? version = 'v0.0.1',
    String? latestVersion = 'v0.0.2',
    String? installPath,
    String? launchPath,
  }) => Game(
    threadId: threadId,
    title: 'Game $threadId',
    creator: 'Creator $threadId',
    version: version ?? '',
    latestVersion: latestVersion ?? '',
    installPath: installPath,
    launchPath: launchPath,
    createdAt: DateTime(2026, 10, 24),
    updatedAt: DateTime(2026, 10, 24),
  );

  LibraryController buildController() {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = DriftLibraryStore(db);
    container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(store),
        appLauncherProvider.overrideWithValue(launcher),
        processRunnerProvider.overrideWithValue(runner),
        clockProvider.overrideWithValue(clock.call),
        libraryRootProvider.overrideWithValue(tempRoot.path),
        latestVersionLookupProvider.overrideWithValue(
          (threadId) async => latestVersions[threadId],
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(libraryProvider.notifier);
  }

  setUp(() async {
    launcher = FakeAppLauncher();
    runner = FakeProcessRunner();
    clock = FakeClock(DateTime(2026, 10, 24, 20));
    latestVersions = {};
    tempRoot = await Directory.systemTemp.createTemp('f95hub_ctrl_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('openFolder routes through the AppLauncher', () async {
    final controller = buildController();
    await controller.openFolder(game(installPath: r'C:\games\game7'));

    expect(launcher.openedFolders, [r'C:\games\game7']);
  });

  test('openFolder ignores a game with no install path', () async {
    final controller = buildController();
    await controller.openFolder(game());

    expect(launcher.openedFolders, isEmpty);
  });

  test('launch starts the remembered entry and records a session on exit',
      () async {
    final controller = buildController();
    final entry = game(launchPath: r'C:\games\game7\Game.exe');

    final handle = await controller.launch(entry);

    expect(handle, isNotNull);
    expect(runner.started, [r'C:\games\game7\Game.exe']);

    var sessions = await store.sessionsFor(7);
    expect(sessions, hasLength(1));
    expect(sessions.single.startedAt, DateTime(2026, 10, 24, 20));
    expect(sessions.single.endedAt, isNull);
    expect(sessions.single.durationSeconds, isNull);

    clock.advance(const Duration(minutes: 90));
    runner.complete(0);
    await handle!.done;

    sessions = await store.sessionsFor(7);
    expect(sessions.single.endedAt, DateTime(2026, 10, 24, 21, 30));
    expect(sessions.single.durationSeconds, 90 * 60);
    expect(await store.totalDuration(7), const Duration(minutes: 90));
  });

  test('launch does nothing when the game has no launch entry', () async {
    final controller = buildController();

    expect(await controller.launch(game()), isNull);
    expect(runner.started, isEmpty);
    expect(await store.sessionsFor(7), isEmpty);
  });

  test('setLaunchPath persists the remembered entry', () async {
    final controller = buildController();
    final entry = game();
    await store.upsertGame(entry);

    await controller.setLaunchPath(entry, r'C:\games\game7\Game.exe');

    expect(
      (await store.getGame(7))!.launchPath,
      r'C:\games\game7\Game.exe',
    );
    expect(controller.state.games.single.launchPath, r'C:\games\game7\Game.exe');
  });

  test('setVersion persists free text and refreshes the library state',
      () async {
    final controller = buildController();
    await store.upsertGame(game());

    await controller.setVersion(7, ' v0.1.0 Build 5 ');

    expect((await store.getGame(7))!.version, ' v0.1.0 Build 5 ');
    expect(controller.state.games.single.version, ' v0.1.0 Build 5 ');
  });

  test('setVersion with an empty string clears the local version', () async {
    final controller = buildController();
    await store.upsertGame(game());

    await controller.setVersion(7, '');

    expect((await store.getGame(7))!.version, isEmpty);
    expect(controller.state.games.single.version, isEmpty);
  });

  test('setVersion ignores a thread that is not in the library', () async {
    final controller = buildController();

    await controller.setVersion(99, 'v1');

    expect(await store.getGame(99), isNull);
    expect(controller.state.games, isEmpty);
  });

  test('editing the version recomputes the hasUpdate flag', () async {
    final controller = buildController();
    await store.upsertGame(game(version: 'v0.0.1', latestVersion: 'v0.0.2'));
    latestVersions[7] = 'v0.0.2';
    await controller.refresh();
    final sub = container.listen(libraryEntriesProvider, (_, __) {});
    addTearDown(sub.close);

    var entries = await container.read(libraryEntriesProvider.future);
    expect(entries.single.hasUpdate, isTrue);

    await controller.setVersion(7, 'v0.0.2');

    entries = await container.read(libraryEntriesProvider.future);
    expect(entries.single.hasUpdate, isFalse);
  });

  test('remove with keepFiles removes the entry but keeps files', () async {
    final target = Directory(p.join(tempRoot.path, 'game7'));
    await target.create(recursive: true);
    final file = File(p.join(target.path, 'data.bin'));
    await file.writeAsBytes([1, 2, 3]);

    final controller = buildController();
    final entry = game(installPath: target.path);
    await store.upsertGame(entry);

    await controller.remove(entry, deleteFiles: false);

    expect(await store.getGame(entry.threadId), isNull);
    expect(await file.exists(), isTrue);
  });

  test('remove with deleteFiles deletes files inside the root', () async {
    final target = Directory(p.join(tempRoot.path, 'game7'));
    await target.create(recursive: true);
    await File(p.join(target.path, 'data.bin')).writeAsBytes([1, 2, 3]);

    final controller = buildController();
    final entry = game(installPath: target.path);
    await store.upsertGame(entry);

    await controller.remove(entry, deleteFiles: true);

    expect(await store.getGame(entry.threadId), isNull);
    expect(await target.exists(), isFalse);
  });

  test('remove with deleteFiles refuses a path outside the root', () async {
    final target = Directory(
      p.join(
        Directory.systemTemp.path,
        'f95hub_out_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await target.create(recursive: true);
    addTearDown(() async {
      if (await target.exists()) await target.delete(recursive: true);
    });

    final controller = buildController();
    final entry = game(installPath: target.path);
    await store.upsertGame(entry);

    await expectLater(
      controller.remove(entry, deleteFiles: true),
      throwsArgumentError,
    );
    expect(await target.exists(), isTrue);
    expect(await store.getGame(entry.threadId), isNotNull);
  });
}
