import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/pages/directory_import_page.dart';
import 'package:f95hub/state/directory_import.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/cover_image.dart';
import 'package:f95hub/widgets/directory_candidate_card.dart';
import 'package:f95hub/widgets/directory_candidate_grid.dart';
import 'package:f95hub/widgets/directory_matched_list.dart';
import 'package:f95hub/widgets/game_picker_dialog.dart';
import 'package:f95hub/widgets/page_frame.dart';

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

/// Builds a source tree: `<root>/<name>/...` with a couple of files.
Future<String> _gameDir(String root, String name) async {
  final dir = Directory(p.join(root, name));
  await dir.create();
  await File(p.join(dir.path, 'game.exe')).writeAsString('exe');
  await Directory(p.join(dir.path, 'sub')).create();
  await File(p.join(dir.path, 'sub', 'data.txt')).writeAsString('data');
  return dir.path;
}

void main() {
  group('DirectoryImportController', () {
    late Directory src;
    late Directory storage;

    setUp(() async {
      src = await Directory.systemTemp.createTemp('f95hub_imp_src_');
      storage = await Directory.systemTemp.createTemp('f95hub_imp_storage_');
    });

    tearDown(() async {
      await src.delete(recursive: true);
      await storage.delete(recursive: true);
    });

    ProviderContainer container(
      DriftLibraryStore store,
      FakeMetadataSource source, {
      GameIndexStore? index,
      String? root,
    }) {
      final c = ProviderContainer(
        overrides: [
          metadataSourceProvider.overrideWithValue(source),
          libraryStoreProvider.overrideWithValue(store),
          libraryRootProvider.overrideWithValue(root ?? storage.path),
          directoryPickerProvider.overrideWithValue(() async => src.path),
          gameIndexStoreProvider.overrideWithValue(
            index ?? _index(FakeMetadataSource(const [])),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('scan lists candidates in the left pane, nothing matched', () async {
      await _gameDir(src.path, 'AlphaGame-0.5-pc');
      await _gameDir(src.path, 'BetaGame-0.2-pc');
      await Directory(p.join(src.path, '.hidden')).create();
      await Directory(p.join(src.path, 'empty')).create();

      final c = container(_store(), FakeMetadataSource(const []));
      await c.read(directoryImportProvider.notifier).pickAndScan();

      final state = c.read(directoryImportProvider);
      expect(state.sourceDir, src.path);
      expect(state.left.map((i) => i.name).toList(),
          ['AlphaGame-0.5-pc', 'BetaGame-0.2-pc']);
      expect(state.right, isEmpty);
      expect(state.left.every((i) => i.matchedGame == null), isTrue);
    });

    test('scan records the cache completeness', () async {
      await _gameDir(src.path, 'AlphaGame-0.5-pc');
      final source = FakeMetadataSource(
        List.generate(65, (i) => makeGame(i + 1, title: 'Game ${i + 1}')),
        pageSize: 30,
      );
      final index = _index(source);
      // A cancelled build stops after page 1 but keeps the total page count.
      await index.buildAll(isCancelled: () => true);

      final c = container(_store(), source, index: index);
      await c.read(directoryImportProvider.notifier).pickAndScan();

      final state = c.read(directoryImportProvider);
      expect(state.lastBuiltPage, 1);
      expect(state.totalPages, 3);
    });

    test('scan auto-matches a unique hit into the right pane', () async {
      await _gameDir(src.path, 'Secret Care Cafe-0.9.5-pc');
      final source = FakeMetadataSource([
        makeGame(1, title: 'Secret Care Cafe [v0.9.5] [Rare Alex]'),
      ]);
      final index = _index(source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();

      final state = c.read(directoryImportProvider);
      expect(state.left, isEmpty);
      expect(state.right.single.matchedGame?.threadId, 1);
      expect(
        state.right.single.matchedGame?.title,
        'Secret Care Cafe [v0.9.5] [Rare Alex]',
      );
      expect(state.autoMatching, isFalse);
      expect(state.autoMatchDone, 1);
      expect(state.autoMatchTotal, 1);
    });

    test('scan leaves ambiguous and unknown candidates on the left', () async {
      final ambiguousDir = await _gameDir(src.path, 'Secret Care Cafe-0.9.5-pc');
      final unknownDir = await _gameDir(src.path, 'Unknown Game-1.0-pc');
      final source = FakeMetadataSource([
        makeGame(1, title: 'Secret Care Cafe'),
        makeGame(2, title: 'Secret Care Cafe 2'),
      ]);
      final index = _index(source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();

      final state = c.read(directoryImportProvider);
      expect(state.right, isEmpty);
      expect(state.left.map((i) => i.path).toList(), [ambiguousDir, unknownDir]);
      expect(state.left.every((i) => i.matchedGame == null), isTrue);
      expect(state.autoMatchDone, 2);
    });

    test('manual matchLeft still moves a left candidate into the right pane',
        () async {
      await _gameDir(src.path, 'Secret Care Cafe-0.9.5-pc');
      final source = FakeMetadataSource([
        makeGame(1, title: 'Secret Care Cafe'),
        makeGame(2, title: 'Secret Care Cafe 2'),
      ]);
      final index = _index(source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      final item = c.read(directoryImportProvider).left.single;

      // The picker resolved the ambiguity.
      controller.matchLeft(item, makeGame(2, title: 'Secret Care Cafe 2'));

      final state = c.read(directoryImportProvider);
      expect(state.left, isEmpty);
      expect(state.right.single.matchedGame?.threadId, 2);
    });

    test('cancelAutoMatch stops the pass after the item in flight', () async {
      await _gameDir(src.path, 'Charlie-1.0-pc');
      await _gameDir(src.path, 'Delta-1.0-pc');
      await _gameDir(src.path, 'Echo-1.0-pc');
      final source = FakeMetadataSource([
        makeGame(1, title: 'Charlie'),
        makeGame(2, title: 'Delta'),
        makeGame(3, title: 'Echo'),
      ]);
      final db = LibraryDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _GatedIndex(db, source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      final scan = controller.pickAndScan();

      // The pass is holding on the second query; the first hit already moved.
      while (index.searchCount < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(c.read(directoryImportProvider).autoMatching, isTrue);
      expect(
        c.read(directoryImportProvider).right.single.name,
        'Charlie-1.0-pc',
      );

      controller.cancelAutoMatch();
      index.release();
      await scan;

      final state = c.read(directoryImportProvider);
      expect(state.autoMatching, isFalse);
      expect(state.right.single.name, 'Charlie-1.0-pc');
      expect(
        state.left.map((i) => i.name).toList(),
        ['Delta-1.0-pc', 'Echo-1.0-pc'],
      );
      // No further catalogue query ran after cancellation.
      expect(index.searchCount, 2);
    });

    test('selectLeft reports ambiguity without moving the item', () async {
      final dir = await _gameDir(src.path, 'Secret Care Cafe-0.9.5-pc');
      final source = FakeMetadataSource([
        makeGame(1, title: 'Secret Care Cafe'),
        makeGame(2, title: 'Secret Care Cafe 2'),
      ]);
      final index = _index(source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      final item = c.read(directoryImportProvider).left.single;

      final outcome = await controller.selectLeft(item);

      expect(outcome, LeftMatchOutcome.ambiguous);
      expect(c.read(directoryImportProvider).left.single.path, dir);
      expect(c.read(directoryImportProvider).right, isEmpty);

      // The picker resolved it: the chosen game moves the item right.
      controller.matchLeft(item, makeGame(2, title: 'Secret Care Cafe 2'));
      expect(c.read(directoryImportProvider).left, isEmpty);
      expect(c.read(directoryImportProvider).right.single.matchedGame?.threadId, 2);
    });

    test('selectLeft reports no match and keeps the item left', () async {
      final dir = await _gameDir(src.path, 'Unknown Game-1.0-pc');
      final source = FakeMetadataSource([makeGame(1, title: 'Other Game')]);
      final index = _index(source);
      await index.buildAll();

      final c = container(_store(), source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();

      final outcome = await controller.selectLeft(
        c.read(directoryImportProvider).left.single,
      );

      expect(outcome, LeftMatchOutcome.noMatch);
      expect(c.read(directoryImportProvider).left.single.path, dir);
      expect(c.read(directoryImportProvider).right, isEmpty);
    });

    test('removeRight sends the item back to the left pane unmatched', () async {
      await _gameDir(src.path, 'AlphaGame-0.5-pc');
      final c = container(_store(), FakeMetadataSource(const []));
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      final item = c.read(directoryImportProvider).left.single;
      controller.matchLeft(item, makeGame(7, title: 'Alpha Game'));

      controller.removeRight(c.read(directoryImportProvider).right.single);

      final state = c.read(directoryImportProvider);
      expect(state.right, isEmpty);
      expect(state.left.single.path, item.path);
      expect(state.left.single.matchedGame, isNull);
    });

    test('setMatchedGame replaces the match of a right-pane item', () async {
      final dir = await _gameDir(src.path, 'Unknown Game-1.0-pc');
      final c = container(_store(), FakeMetadataSource(const []));
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      controller.matchLeft(
        c.read(directoryImportProvider).left.single,
        makeGame(1, title: 'First Pick'),
      );

      controller.setMatchedGame(dir, makeGame(9, title: 'Picked Game'));

      expect(
        c.read(directoryImportProvider).right.single.matchedGame?.threadId,
        9,
      );
    });

    test('import moves the source into storage and persists a scraped game',
        () async {
      final gameDir = await _gameDir(src.path, 'MyGame-0.5-pc');
      final store = _store();
      final source = FakeMetadataSource(
        [makeGame(7, title: 'My Game')],
        tagTable: makeTagTable(),
        threadDetails: {7: makeThreadDetail(7, description: 'A great game.')},
      );

      final c = container(store, source);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      expect(c.read(directoryImportProvider).left.single.name, 'MyGame-0.5-pc');

      await controller.import(gameDir, makeGame(7, title: 'My Game'));

      final item = c.read(directoryImportProvider).left.single;
      expect(item.phase, ImportItemPhase.done);

      final movedPath = p.join(storage.path, 'My Game');
      expect(await File(p.join(movedPath, 'game.exe')).exists(), isTrue);
      expect(await File(p.join(movedPath, 'sub', 'data.txt')).exists(), isTrue);
      // Moved: the source folder is gone.
      expect(await Directory(gameDir).exists(), isFalse);

      final stored = await store.getGame(7);
      expect(stored, isNotNull);
      expect(stored!.installPath, movedPath);
      expect(stored.version, '0.5');
      expect(stored.description, 'A great game.');
    });

    test('import refuses an existing target and keeps the source intact',
        () async {
      final gameDir = await _gameDir(src.path, 'MyGame-0.5-pc');
      final existing = Directory(p.join(storage.path, 'My Game'));
      await existing.create();
      await File(p.join(existing.path, 'old.txt')).writeAsString('old');
      final store = _store();

      final c = container(store, FakeMetadataSource(const []));
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      await controller.import(gameDir, makeGame(7, title: 'My Game'));

      expect(
        c.read(directoryImportProvider).left.single.phase,
        ImportItemPhase.failed,
      );
      expect(await File(p.join(gameDir, 'game.exe')).exists(), isTrue);
      expect(await File(p.join(existing.path, 'old.txt')).exists(), isTrue);
      expect(await store.getGame(7), isNull);
    });

    test('import fails cleanly when no storage root is configured', () async {
      final gameDir = await _gameDir(src.path, 'MyGame-0.5-pc');
      final store = _store();
      final c = ProviderContainer(
        overrides: [
          metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
          libraryStoreProvider.overrideWithValue(store),
          libraryRootProvider.overrideWithValue(null),
          directoryPickerProvider.overrideWithValue(() async => src.path),
          gameIndexStoreProvider.overrideWithValue(
            _index(FakeMetadataSource(const [])),
          ),
        ],
      );
      addTearDown(c.dispose);

      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      await controller.import(gameDir, makeGame(7, title: 'My Game'));

      expect(
        c.read(directoryImportProvider).left.single.phase,
        ImportItemPhase.failed,
      );
      // Nothing was moved.
      expect(await Directory(gameDir).exists(), isTrue);
    });

    test('importRight imports only the right-pane items', () async {
      final gammaDir = await _gameDir(src.path, 'Gamma Game-0.5-pc');
      final betaDir = await _gameDir(src.path, 'BetaGame-0.2-pc');
      final store = _store();
      final source = FakeMetadataSource(
        [
          makeGame(7, title: 'Gamma Game'),
          makeGame(8, title: 'Other Game'),
        ],
        tagTable: makeTagTable(),
        threadDetails: {
          7: makeThreadDetail(7, description: 'Gamma.'),
          8: makeThreadDetail(8, description: 'Beta.'),
        },
      );
      final index = _index(source);
      await index.buildAll();

      final c = container(store, source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();

      // The scan auto-matched the unique catalogue hit.
      expect(c.read(directoryImportProvider).right.single.name,
          'Gamma Game-0.5-pc');
      expect(c.read(directoryImportProvider).left.single.name,
          'BetaGame-0.2-pc');

      await controller.importRight();

      final state = c.read(directoryImportProvider);
      // The imported item leaves the right pane; the unmatched left candidate
      // is untouched.
      expect(state.right, isEmpty);
      expect(state.left.single.name, 'BetaGame-0.2-pc');

      final stored = await store.getGame(7);
      expect(stored, isNotNull);
      expect(stored!.description, 'Gamma.');
      expect(stored.installPath, p.join(storage.path, 'Gamma Game'));
      expect(await Directory(gammaDir).exists(), isFalse);
      // The un-matched left candidate was not touched.
      expect(await Directory(betaDir).exists(), isTrue);
      expect(await store.getGame(8), isNull);
    });

    test('importRight removes a successfully imported right item', () async {
      await _gameDir(src.path, 'Gamma Game-0.5-pc');
      final store = _store();
      final source = FakeMetadataSource(
        [makeGame(7, title: 'Gamma Game')],
        tagTable: makeTagTable(),
        threadDetails: {7: makeThreadDetail(7)},
      );
      final index = _index(source);
      await index.buildAll();

      final c = container(store, source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      expect(c.read(directoryImportProvider).right, hasLength(1));

      await controller.importRight();

      expect(c.read(directoryImportProvider).right, isEmpty);
      expect(await store.getGame(7), isNotNull);
    });

    test('importRight keeps a failed right item so it can be retried', () async {
      await _gameDir(src.path, 'Gamma Game-0.5-pc');
      // An existing target makes the move refuse, so the import fails.
      await Directory(p.join(storage.path, 'Gamma Game')).create();
      final store = _store();
      final source = FakeMetadataSource(
        [makeGame(7, title: 'Gamma Game')],
        tagTable: makeTagTable(),
        threadDetails: {7: makeThreadDetail(7)},
      );
      final index = _index(source);
      await index.buildAll();

      final c = container(store, source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      expect(c.read(directoryImportProvider).right, hasLength(1));

      await controller.importRight();

      final item = c.read(directoryImportProvider).right.single;
      expect(item.name, 'Gamma Game-0.5-pc');
      expect(item.phase, ImportItemPhase.failed);
      expect(item.error, isNotNull);
      expect(await store.getGame(7), isNull);
    });

    test('importRight empties the right pane after importing every item',
        () async {
      await _gameDir(src.path, 'Gamma Game-0.5-pc');
      await _gameDir(src.path, 'Delta Game-0.1-pc');
      final store = _store();
      final source = FakeMetadataSource(
        [
          makeGame(7, title: 'Gamma Game'),
          makeGame(8, title: 'Delta Game'),
        ],
        tagTable: makeTagTable(),
        threadDetails: {
          7: makeThreadDetail(7),
          8: makeThreadDetail(8),
        },
      );
      final index = _index(source);
      await index.buildAll();

      final c = container(store, source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      expect(c.read(directoryImportProvider).right, hasLength(2));

      await controller.importRight();

      expect(c.read(directoryImportProvider).right, isEmpty);
      expect(await store.getGame(7), isNotNull);
      expect(await store.getGame(8), isNotNull);
    });

    test('importRight skips items that were already imported', () async {
      await _gameDir(src.path, 'Gamma Game-0.5-pc');
      final store = _store();
      final source = FakeMetadataSource(
        [makeGame(7, title: 'Gamma Game')],
        tagTable: makeTagTable(),
        threadDetails: {7: makeThreadDetail(7)},
      );
      final index = _index(source);
      await index.buildAll();

      final c = container(store, source, index: index);
      final controller = c.read(directoryImportProvider.notifier);
      await controller.pickAndScan();
      expect(c.read(directoryImportProvider).right, hasLength(1));

      await controller.importRight();
      await controller.importRight();

      // The first pass removed the item, so the second is a no-op.
      expect(c.read(directoryImportProvider).right, isEmpty);
      expect(await store.getGame(7), isNotNull);
    });
  });

  group('DirectoryCandidateCard', () {
    ImportItem item(String name,
            {ImportItemPhase phase = ImportItemPhase.pending}) =>
        ImportItem(path: '/src/$name', name: name, phase: phase);

    Widget host(Widget child) => MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 300, height: 300, child: child)),
          ),
        );

    testWidgets('renders name, version, path, and a placeholder cover',
        (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc'),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('MyGame'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);
      expect(find.text('/src/MyGame-0.5-pc'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(CoverImage), findsOneWidget);
    });

    testWidgets('tapping the card selects it', (tester) async {
      var selects = 0;
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc'),
            onSelect: () => selects++,
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(find.byType(DirectoryCandidateCard));
      expect(selects, 1);
    });

    testWidgets('renders move progress with a cancel action', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc', phase: ImportItemPhase.moving)
                .copyWith(progress: 0.5),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders the done state with the game title', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc', phase: ImportItemPhase.done).copyWith(
              game: makeGame(7, title: 'My Game'),
            ),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('Imported: My Game'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows the matched game title and version', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc').copyWith(
              matchedGame: makeGame(7, title: 'My Game', version: 'v0.9.5'),
            ),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('My Game'), findsOneWidget);
      expect(find.text('v0.9.5'), findsOneWidget);
      expect(find.text('Matched'), findsOneWidget);
      expect(find.text('Not matched'), findsNothing);
    });

    testWidgets('hints when no catalogue game matched', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc'),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('Not matched'), findsOneWidget);
      expect(find.text('Matched'), findsNothing);
    });

    testWidgets('golden', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryCandidateCard(
            item: item('MyGame-0.5-pc'),
            onSelect: () {},
            onCancel: () {},
          ),
        ),
      );

      await expectLater(
        find.byType(DirectoryCandidateCard),
        matchesGoldenFile('goldens/directory_candidate_card_pending.png'),
      );
    });
  });

  group('DirectoryCandidateGrid', () {
    List<ImportItem> items() => const [
          ImportItem(path: '/games/A-0.1-pc', name: 'A-0.1-pc'),
          ImportItem(path: '/games/B-0.2-pc', name: 'B-0.2-pc'),
          ImportItem(path: '/games/C-0.3-pc', name: 'C-0.3-pc'),
          ImportItem(path: '/games/D-0.4-pc', name: 'D-0.4-pc'),
        ];

    int columnCount(WidgetTester tester) {
      final finder = find.byType(DirectoryCandidateCard);
      final lefts = <double>{};
      final count = tester.widgetList(finder).length;
      for (var i = 0; i < count; i++) {
        lefts.add(tester.getRect(finder.at(i)).left);
      }
      return lefts.length;
    }

    testWidgets('column count adapts to width', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;

      Future<void> pumpAt(double width) async {
        tester.view.physicalSize = Size(width, 600);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DirectoryCandidateGrid(
                items: items(),
                onSelect: (_) {},
                onCancel: (_) {},
              ),
            ),
          ),
        );
      }

      await pumpAt(320);
      expect(columnCount(tester), 1);

      await pumpAt(600);
      expect(columnCount(tester), 2);

      await pumpAt(900);
      expect(columnCount(tester), 3);

      await pumpAt(1200);
      expect(columnCount(tester), 4);
    });

    testWidgets('tapping a card reports the item as selected', (tester) async {
      ImportItem? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectoryCandidateGrid(
              items: items(),
              onSelect: (item) => selected = item,
              onCancel: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DirectoryCandidateCard).first);
      expect(selected?.name, 'A-0.1-pc');
    });

    testWidgets('golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: DirectoryCandidateGrid(
                items: items(),
                onSelect: (_) {},
                onCancel: (_) {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(DirectoryCandidateGrid),
        matchesGoldenFile('goldens/directory_candidate_grid.png'),
      );
    });
  });

  group('DirectoryMatchedList', () {
    List<ImportItem> items() => [
          ImportItem(path: '/games/A-0.1-pc', name: 'A-0.1-pc').copyWith(
            matchedGame: makeGame(1, title: 'Alpha Game', version: 'v0.9.5'),
          ),
          ImportItem(path: '/games/B-0.2-pc', name: 'B-0.2-pc').copyWith(
            matchedGame: makeGame(2, title: 'Beta Game'),
          ),
        ];

    Widget host(Widget child, {double width = 500, double height = 400}) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: width, height: height, child: child),
          ),
        );

    testWidgets('lists matched titles with change and remove actions',
        (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryMatchedList(
            items: items(),
            onChangeMatch: (_) {},
            onRemove: (_) {},
            onCancel: (_) {},
          ),
        ),
      );

      expect(find.text('Alpha Game'), findsOneWidget);
      expect(find.text('Beta Game'), findsOneWidget);
      expect(find.byTooltip('Change matched game'), findsNWidgets(2));
      expect(find.byTooltip('Remove'), findsNWidgets(2));
    });

    testWidgets('reports change-match and remove for the tapped row',
        (tester) async {
      ImportItem? changed;
      ImportItem? removed;
      await tester.pumpWidget(
        host(
          DirectoryMatchedList(
            items: items(),
            onChangeMatch: (item) => changed = item,
            onRemove: (item) => removed = item,
            onCancel: (_) {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.swap_horiz).first);
      expect(changed?.name, 'A-0.1-pc');

      await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
      expect(removed?.name, 'B-0.2-pc');
    });

    testWidgets('shows a hint when nothing is matched', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryMatchedList(
            items: const [],
            onChangeMatch: (_) {},
            onRemove: (_) {},
            onCancel: (_) {},
          ),
        ),
      );

      expect(find.text('Select a folder on the left to match it'),
          findsOneWidget);
    });

    testWidgets('golden', (tester) async {
      await tester.pumpWidget(
        host(
          DirectoryMatchedList(
            items: items(),
            onChangeMatch: (_) {},
            onRemove: (_) {},
            onCancel: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DirectoryMatchedList),
        matchesGoldenFile('goldens/directory_matched_list.png'),
      );
    });
  });

  group('DirectoryImportPage', () {
    setUp(() => _FakeImportController.importRightCalls = 0);

    Widget host() => ProviderScope(
          overrides: [
            metadataSourceProvider
                .overrideWithValue(FakeMetadataSource(const [])),
            libraryStoreProvider.overrideWithValue(_store()),
            directoryImportProvider.overrideWith(_FakeImportController.new),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1200, height: 800, child: DirectoryImportPage()),
          ),
        );

    testWidgets('renders the two panes and the batch-import action',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('Scanned folders'), findsOneWidget);
      expect(find.text('Matched (0)'), findsOneWidget);
      expect(find.byType(DirectoryCandidateCard), findsNWidgets(2));
      expect(find.text('MyGame'), findsOneWidget);
      expect(find.text('OtherGame'), findsOneWidget);
      expect(find.text('Import (0)'), findsOneWidget);

      await expectLater(
        find.byType(DirectoryImportPage),
        matchesGoldenFile('goldens/directory_import_page.png'),
      );
    });

    testWidgets('tapping a left card matches it into the right pane',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DirectoryCandidateCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(DirectoryCandidateCard), findsOneWidget);
      expect(find.text('Matched (1)'), findsOneWidget);
      expect(find.text('My Game'), findsOneWidget);
      expect(find.text('Import (1)'), findsOneWidget);
    });

    testWidgets('the import button batch-imports the right pane',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DirectoryCandidateCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import (1)'));
      await tester.pump();

      expect(_FakeImportController.importRightCalls, 1);
    });

    testWidgets('several catalogue hits open the game picker, then cancel',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider
                .overrideWithValue(FakeMetadataSource(const [])),
            libraryStoreProvider.overrideWithValue(_store()),
            gameIndexStoreProvider
                .overrideWithValue(_index(FakeMetadataSource(const []))),
            directoryImportProvider.overrideWith(
              _AmbiguousImportController.new,
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1200, height: 800, child: DirectoryImportPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DirectoryCandidateCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(GamePickerDialog), findsOneWidget);
      expect(find.text('Matched (0)'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(GamePickerDialog), findsNothing);
      expect(find.text('Matched (0)'), findsOneWidget);
    });

    testWidgets('no catalogue hit opens the picker and choosing moves it right',
        (tester) async {
      final source = FakeMetadataSource([makeGame(7, title: 'MyGame Deluxe')]);
      final index = _index(source);
      await index.buildAll();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider.overrideWithValue(source),
            libraryStoreProvider.overrideWithValue(_store()),
            gameIndexStoreProvider.overrideWithValue(index),
            directoryImportProvider.overrideWith(
              _NoMatchImportController.new,
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1200, height: 800, child: DirectoryImportPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DirectoryCandidateCard).first);
      await tester.pumpAndSettle();

      // The picker opens with the guessed folder title pre-filled.
      expect(find.byType(GamePickerDialog), findsOneWidget);
      expect(find.widgetWithText(TextField, 'MyGame'), findsOneWidget);
      expect(find.text('Matched (0)'), findsOneWidget);

      await tester.tap(find.text('MyGame Deluxe'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePickerDialog), findsNothing);
      expect(find.byType(DirectoryCandidateCard), findsOneWidget);
      expect(find.text('Matched (1)'), findsOneWidget);
      expect(find.text('MyGame Deluxe'), findsOneWidget);
      expect(find.text('Import (1)'), findsOneWidget);
    });

    testWidgets('warns when the cache only covers part of the catalogue', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider
                .overrideWithValue(FakeMetadataSource(const [])),
            libraryStoreProvider.overrideWithValue(_store()),
            directoryImportProvider.overrideWith(
              _IncompleteCacheImportController.new,
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1200, height: 800, child: DirectoryImportPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2/5'), findsOneWidget);
      expect(find.text('Not matched'), findsWidgets);
    });

    testWidgets('shows the auto-match progress while the pass runs', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider
                .overrideWithValue(FakeMetadataSource(const [])),
            libraryStoreProvider.overrideWithValue(_store()),
            directoryImportProvider.overrideWith(
              _AutoMatchingImportController.new,
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1200, height: 800, child: DirectoryImportPage()),
          ),
        ),
      );
      // The loading bar animates indefinitely, so `pumpAndSettle` would time out.
      await tester.pump();

      expect(
        find.text('Auto-matching folders 1/2'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      expect(find.byType(PageLoadingBar), findsOneWidget);
    });
  });

  group('GamePickerDialog prefill', () {
    testWidgets('pre-fills the search field with the guessed title',
        (tester) async {
      final source = FakeMetadataSource(
        [
          makeGame(1, title: 'Secret Care Cafe'),
          makeGame(2, title: 'Other Game'),
        ],
      );
      final index = _index(source);
      await index.buildAll();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider.overrideWithValue(source),
            gameIndexStoreProvider.overrideWithValue(index),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GamePickerDialog(initialQuery: 'Secret Care Cafe'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Secret Care Cafe'),
        findsOneWidget,
      );
      // The guessed query filters the results to the matching game.
      expect(find.text('Secret Care Cafe'), findsWidgets);
      expect(find.text('Other Game'), findsNothing);
    });

    testWidgets('leaves the search field empty without a guess', (tester) async {
      final source = FakeMetadataSource(const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metadataSourceProvider.overrideWithValue(source),
            gameIndexStoreProvider.overrideWithValue(_index(source)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GamePickerDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No guess applied: the field shows its placeholder hint.
      expect(find.text('Search by title'), findsOneWidget);
    });
  });
}

/// A controller with a pre-populated left pane, so the page tests never perform
/// real file I/O (which cannot complete under `testWidgets`' fake-async zone).
/// Selecting a left item simulates the unique auto-match.
class _FakeImportController extends DirectoryImportController {
  static int importRightCalls = 0;

  @override
  DirectoryImportState build() => const DirectoryImportState(
        sourceDir: '/games',
        left: [
          ImportItem(path: '/games/MyGame-0.5-pc', name: 'MyGame-0.5-pc'),
          ImportItem(path: '/games/OtherGame-1.0-pc', name: 'OtherGame-1.0-pc'),
        ],
      );

  @override
  Future<void> pickAndScan() async {}

  @override
  Future<LeftMatchOutcome> selectLeft(ImportItem item) async {
    matchLeft(item, makeGame(7, title: 'My Game'));
    return LeftMatchOutcome.matched;
  }

  @override
  Future<void> importRight() async {
    importRightCalls++;
  }
}

/// A page state with a partially built catalogue, so the completeness hint
/// renders.
class _IncompleteCacheImportController extends _FakeImportController {
  @override
  DirectoryImportState build() => const DirectoryImportState(
        sourceDir: '/games',
        lastBuiltPage: 2,
        totalPages: 5,
        left: [
          ImportItem(path: '/games/MyGame-0.5-pc', name: 'MyGame-0.5-pc'),
        ],
      );
}

/// Reports several catalogue hits, so the page must open the picker.
class _AmbiguousImportController extends _FakeImportController {
  @override
  Future<LeftMatchOutcome> selectLeft(ImportItem item) async =>
      LeftMatchOutcome.ambiguous;
}

/// Reports no catalogue hit, so the page must keep the item on the left.
class _NoMatchImportController extends _FakeImportController {
  @override
  Future<LeftMatchOutcome> selectLeft(ImportItem item) async =>
      LeftMatchOutcome.noMatch;
}

/// A controller showing the auto-match pass in progress, so the progress note
/// renders.
class _AutoMatchingImportController extends _FakeImportController {
  @override
  DirectoryImportState build() => const DirectoryImportState(
        sourceDir: '/games',
        autoMatching: true,
        autoMatchTotal: 2,
        autoMatchDone: 1,
        left: [
          ImportItem(path: '/games/MyGame-0.5-pc', name: 'MyGame-0.5-pc'),
        ],
      );
}

/// A [GameIndexStore] that holds every query after the first until released,
/// so a test can cancel the auto-match pass mid-run.
class _GatedIndex extends GameIndexStore {
  _GatedIndex(super.db, super.source);

  int searchCount = 0;

  /// Queries past this many wait for [release] before answering.
  int gateAfter = 1;

  Completer<void>? _gate;

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<List<GameIndexRow>> search(String query, {int limit = 50}) async {
    searchCount++;
    if (searchCount > gateAfter) {
      _gate ??= Completer<void>();
      await _gate!.future;
    }
    final rows = await super.search(query, limit: limit);
    return rows;
  }
}
