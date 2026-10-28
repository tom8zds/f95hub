import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/pages/library_page.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/add_game_to_library.dart';
import 'package:f95hub/widgets/game_search_list.dart';
import 'package:f95hub/widgets/import_game_dialog.dart';
import 'package:f95hub/widgets/install_path_dialog.dart';

import 'support/fake_metadata_source.dart';

DriftLibraryStore _store() {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return DriftLibraryStore(db);
}

GameIndexStore _index(FakeMetadataSource source) {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return GameIndexStore(db, source);
}

Widget _scope(
  DriftLibraryStore store,
  FakeMetadataSource source, {
  GameIndexStore? index,
  Widget? child,
}) {
  return ProviderScope(
    overrides: [
      metadataSourceProvider.overrideWithValue(source),
      libraryStoreProvider.overrideWithValue(store),
      gameIndexStoreProvider.overrideWithValue(index ?? _index(source)),
      directoryPickerProvider.overrideWithValue(() async => 'C:/games/7'),
    ],
    child: child ?? const SizedBox.shrink(),
  );
}

/// Stands in for the games grid's context menu — the only real entry point to
/// the add-to-library flow since the detail FAB now opens the browser.
class _AddToLibraryHost extends ConsumerWidget {
  const _AddToLibraryHost({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addGameToLibrary(context, ref, game),
        label: const Text('Add to library'),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

void main() {
  testWidgets('加入库 scrapes and persists', (tester) async {
    final store = _store();
    final source = FakeMetadataSource(
      const [],
      tagTable: makeTagTable(),
      threadDetails: {
        7: makeThreadDetail(7, description: 'A ninja training sim.'),
      },
    );
    final game = makeGame(
      7,
      title: 'Kunoichi Sensei',
      tagIds: const [45, 107],
      prefixIds: const [3],
    );

    await tester.pumpWidget(
      _scope(
        store,
        source,
        child: MaterialApp(
          home: SizedBox(
            width: 900,
            height: 700,
            child: _AddToLibraryHost(game: game),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();

    expect(find.byType(InstallPathDialog), findsOneWidget);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final stored = await store.getGame(7);
    expect(stored, isNotNull);
    expect(stored!.installPath, 'C:/games/7');
    expect(stored.tags, ['rpg', '3dcg']);
    expect(stored.engine, 'Unity');
    expect(stored.description, 'A ninja training sim.');
    expect(find.text('Added to library'), findsOneWidget);
  });

  testWidgets('manual import picks a folder and associates a thread', (
    tester,
  ) async {
    final store = _store();
    final source = FakeMetadataSource(
      [makeGame(1, title: 'Alpha Game'), makeGame(2, title: 'Beta Game')],
      tagTable: makeTagTable(),
      threadDetails: {2: makeThreadDetail(2, description: 'Beta desc.')},
    );
    final index = _index(source);
    await index.buildAll();

    await tester.pumpWidget(
      _scope(
        store,
        source,
        index: index,
        child: const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: LibraryPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('No games in your library yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pumpAndSettle();

    expect(find.byType(ImportGameDialog), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(ImportGameDialog), matching: find.byType(TextField)).first, 'beta');
    await tester.pump(GameSearchList.searchDebounce);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beta Game'));
    await tester.pumpAndSettle();

    final stored = await store.getGame(2);
    expect(stored, isNotNull);
    expect(stored!.installPath, 'C:/games/7');
    expect(stored.description, 'Beta desc.');
  });

  testWidgets('加入库 persists the local version parsed from the folder', (
    tester,
  ) async {
    final store = _store();
    final source = FakeMetadataSource(
      const [],
      tagTable: makeTagTable(),
      threadDetails: {
        7: makeThreadDetail(7, description: 'A ninja training sim.'),
      },
    );
    final game = makeGame(7, title: 'Kunoichi Sensei');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataSourceProvider.overrideWithValue(source),
          libraryStoreProvider.overrideWithValue(store),
          directoryPickerProvider.overrideWithValue(
            () async => 'C:/games/DevotedWife-0.56-pc',
          ),
        ],
        child: MaterialApp(
          home: SizedBox(
            width: 900,
            height: 700,
            child: _AddToLibraryHost(game: game),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '0.56'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final stored = await store.getGame(7);
    expect(stored, isNotNull);
    expect(stored!.version, '0.56');
  });

  testWidgets('manual import persists the version parsed from the folder name', (
    tester,
  ) async {
    final store = _store();
    final source = FakeMetadataSource(
      [makeGame(2, title: 'Beta Game')],
      tagTable: makeTagTable(),
      threadDetails: {2: makeThreadDetail(2, description: 'Beta desc.')},
    );
    final index = _index(source);
    await index.buildAll();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataSourceProvider.overrideWithValue(source),
          libraryStoreProvider.overrideWithValue(store),
          gameIndexStoreProvider.overrideWithValue(index),
          directoryPickerProvider.overrideWithValue(
            () async => 'C:/games/DevotedWife-0.56-pc',
          ),
        ],
        child: const MaterialApp(
          home: SizedBox(width: 900, height: 700, child: LibraryPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '0.56'), findsOneWidget);
    // The search is prefilled with the parsed title; narrow it to the target.
    await tester.enterText(find.descendant(of: find.byType(ImportGameDialog), matching: find.byType(TextField)).first, 'Beta');
    await tester.pump(GameSearchList.searchDebounce);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beta Game'));
    await tester.pumpAndSettle();

    final stored = await store.getGame(2);
    expect(stored, isNotNull);
    expect(stored!.version, '0.56');
  });

  testWidgets('InstallPathDialog golden', (tester) async {
    await tester.pumpWidget(
      _scope(
        _store(),
        FakeMetadataSource(const []),
        child: const MaterialApp(home: Scaffold(body: InstallPathDialog())),
      ),
    );

    await expectLater(
      find.byType(InstallPathDialog),
      matchesGoldenFile('goldens/install_path_dialog.png'),
    );
  });

  testWidgets('ImportGameDialog golden', (tester) async {
    final source = FakeMetadataSource(
      [makeGame(1, title: 'Alpha Game'), makeGame(2, title: 'Beta Game')],
    );
    final index = _index(source);
    await index.buildAll();

    await tester.pumpWidget(
      _scope(
        _store(),
        source,
        index: index,
        child: const MaterialApp(
          home: Scaffold(body: ImportGameDialog(installPath: 'C:/games')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byType(ImportGameDialog),
      matchesGoldenFile('goldens/import_game_dialog.png'),
    );
  });

  testWidgets('ImportGameDialog prefills title + version from folder name', (
    tester,
  ) async {
    final source = FakeMetadataSource([
      makeGame(1, title: 'Devoted Wife'),
      makeGame(2, title: 'Other Game'),
    ]);
    final index = _index(source);
    await index.buildAll();

    await tester.pumpWidget(
      _scope(
        _store(),
        source,
        index: index,
        child: const MaterialApp(
          home: Scaffold(
            body: ImportGameDialog(installPath: 'C:/games/Devoted Wife-0.56-pc'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The search field is prefilled with the parsed title.
    expect(find.widgetWithText(TextField, 'Devoted Wife'), findsOneWidget);
    // The local-version field is prefilled with the parsed version.
    expect(find.widgetWithText(TextField, '0.56'), findsOneWidget);
  });

  testWidgets('加入库 moves the picked folder under the storage root', (
    tester,
  ) async {
    final store = _store();
    final source = FakeMetadataSource(
      const [],
      tagTable: makeTagTable(),
      threadDetails: {
        7: makeThreadDetail(7, description: 'A ninja training sim.'),
      },
    );
    final game = makeGame(7, title: 'Kunoichi Sensei');
    final storage = Directory.systemTemp.createTempSync('f95hub_add_storage_');
    final picked = Directory.systemTemp.createTempSync('f95hub_add_picked_');
    addTearDown(() {
      // Synchronous cleanup: tear-downs run in the fake-async zone.
      if (storage.existsSync()) storage.deleteSync(recursive: true);
      if (picked.existsSync()) picked.deleteSync(recursive: true);
    });
    File(p.join(picked.path, 'game.exe')).writeAsStringSync('exe');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metadataSourceProvider.overrideWithValue(source),
          libraryStoreProvider.overrideWithValue(store),
          libraryRootProvider.overrideWithValue(storage.path),
          directoryPickerProvider.overrideWithValue(
            () async => picked.path,
          ),
        ],
        child: MaterialApp(
          home: SizedBox(
            width: 900,
            height: 700,
            child: _AddToLibraryHost(game: game),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));

    // The move + scrape use real file I/O, so pump while giving the real event
    // loop a chance to complete it.
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
      final done = await tester.runAsync(() => store.getGame(7));
      if (done != null) break;
    }
    await tester.pumpAndSettle();

    final target = p.join(storage.path, 'Kunoichi Sensei');
    expect(picked.existsSync(), isFalse);
    expect(File(p.join(target, 'game.exe')).existsSync(), isTrue);

    final stored = await tester.runAsync(() => store.getGame(7));
    expect(stored, isNotNull);
    expect(stored!.installPath, target);
    expect(stored.description, 'A ninja training sim.');
  });
}
