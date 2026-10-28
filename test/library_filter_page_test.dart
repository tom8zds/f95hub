import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/pages/library_page.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/widgets/game_card.dart';
import 'package:f95hub/widgets/game_grid.dart';
import 'package:f95hub/widgets/library_filter_drawer.dart';
import 'package:f95hub/widgets/library_sort_sheet.dart';
import 'package:f95hub/widgets/search_field.dart';

import 'support/fake_metadata_source.dart';

Game _game(
  int threadId, {
  required String title,
  String version = 'v1.0',
  String latestVersion = 'v1.0',
  List<String> tags = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Game(
  threadId: threadId,
  title: title,
  creator: 'Creator',
  version: version,
  latestVersion: latestVersion,
  tags: tags,
  createdAt: createdAt ?? DateTime(2026, 10, 24),
  updatedAt: updatedAt ?? DateTime(2026, 10, 24),
);

/// Builds a library with three games (one outdated per the index) and the
/// matching catalogue cache rows.
Future<Widget> _pumpReady(WidgetTester tester) async {
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final store = DriftLibraryStore(db);
  final source = FakeMetadataSource(const []);
  final index = GameIndexStore(db, source);

  await store.upsertGame(
    _game(1, title: 'Kunoichi Sensei', tags: ['rpg', '3dcg']),
  );
  await store.upsertGame(
    _game(2, title: 'Secret Care Cafe', tags: ['rpg', 'romance']),
  );
  await store.upsertGame(_game(3, title: 'Pixel Farm', tags: ['sandbox']));

  // Only thread 2 is behind the catalogue: threads 1/3 match, and thread 3 is
  // not cached at all (falls back to its scrape-time latest).
  await db
      .into(db.gameIndex)
      .insertOnConflictUpdate(
        GameIndexCompanion.insert(
          threadId: const Value(1),
          title: 'Kunoichi Sensei',
          normalizedTitle: 'kunoichi sensei',
          latestVersion: const Value('v1.0'),
          cachedAt: DateTime(2026, 10, 24),
        ),
      );
  await db
      .into(db.gameIndex)
      .insertOnConflictUpdate(
        GameIndexCompanion.insert(
          threadId: const Value(2),
          title: 'Secret Care Cafe',
          normalizedTitle: 'secret care cafe',
          latestVersion: const Value('v1.1'),
          cachedAt: DateTime(2026, 10, 24),
        ),
      );

  return ProviderScope(
    overrides: [
      metadataSourceProvider.overrideWithValue(source),
      libraryStoreProvider.overrideWithValue(store),
      gameIndexStoreProvider.overrideWithValue(index),
    ],
    child: const MaterialApp(
      home: SizedBox(width: 900, height: 700, child: LibraryPage()),
    ),
  );
}

/// Opens the AppBar's 过滤器 end drawer.
Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('library-filter-button')));
  await tester.pumpAndSettle();
  expect(find.byType(LibraryFilterDrawer), findsOneWidget);
}

/// The titles of the grid's games, in display order.
List<String> _gridTitles(WidgetTester tester) => tester
    .widget<GameGrid>(find.byType(GameGrid))
    .games
    .map((game) => game.title)
    .toList(growable: false);

void main() {
  testWidgets('library page badges only the outdated game', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    expect(find.byType(GameCard), findsNWidgets(3));
    expect(find.byKey(const Key('game-update-badge-2')), findsOneWidget);
    expect(find.byKey(const Key('game-update-badge-1')), findsNothing);
    expect(find.byKey(const Key('game-update-badge-3')), findsNothing);
    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('search, filter and sort live in the AppBar', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    expect(find.byType(SearchField), findsOneWidget);
    expect(find.byKey(const Key('library-search-field')), findsOneWidget);
    expect(find.byKey(const Key('library-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('library-sort-button')), findsOneWidget);
    // Import actions stay reachable from the title bar.
    expect(
      find.byKey(const Key('library-import-folder-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('library-import-directory-button')),
      findsOneWidget,
    );
  });

  testWidgets('search filters the grid by title', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('library-search-field')),
      'CARE',
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameCard), findsOneWidget);
    expect(find.text('Secret Care Cafe'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('library-search-field')),
      'nope',
    );
    await tester.pumpAndSettle();
    expect(find.byType(GameCard), findsNothing);
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('filter drawer tag chips multi-select and narrow the grid', (
    tester,
  ) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();
    await _openFilters(tester);

    // Options are the union of the library's tags.
    expect(find.byKey(const Key('library-tag-rpg')), findsOneWidget);
    expect(find.byKey(const Key('library-tag-sandbox')), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-tag-sandbox')));
    await tester.pumpAndSettle();
    expect(find.byType(GameCard), findsOneWidget);
    expect(find.text('Pixel Farm'), findsOneWidget);

    // A second selected tag widens the result (any-of).
    await tester.tap(find.byKey(const Key('library-tag-rpg')));
    await tester.pumpAndSettle();
    expect(find.byType(GameCard), findsNWidgets(3));

    // Toggling a chip off again narrows once more.
    await tester.tap(find.byKey(const Key('library-tag-sandbox')));
    await tester.pumpAndSettle();
    expect(find.byType(GameCard), findsNWidgets(2));
  });

  testWidgets('drawer 应用 closes the drawer and keeps the filter', (
    tester,
  ) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();
    await _openFilters(tester);

    await tester.tap(find.byKey(const Key('library-only-updates')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryFilterDrawer), findsNothing);
    expect(find.byType(GameCard), findsOneWidget);
    expect(find.text('Secret Care Cafe'), findsOneWidget);
  });

  testWidgets('sort sheet reorders the grid', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    // All three share an updatedAt, so the default keeps thread order.
    expect(_gridTitles(tester), [
      'Kunoichi Sensei',
      'Secret Care Cafe',
      'Pixel Farm',
    ]);

    await tester.tap(find.byKey(const Key('library-sort-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LibrarySortSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-sort-title')));
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySortSheet), findsNothing);
    expect(_gridTitles(tester), [
      'Kunoichi Sensei',
      'Pixel Farm',
      'Secret Care Cafe',
    ]);
  });

  testWidgets('search, tags and updates-only combine', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('library-search-field')),
      'care',
    );
    await _openFilters(tester);
    await tester.tap(find.byKey(const Key('library-tag-rpg')));
    await tester.tap(find.byKey(const Key('library-only-updates')));
    await tester.pumpAndSettle();

    expect(find.byType(GameCard), findsOneWidget);
    expect(find.text('Secret Care Cafe'), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-tag-sandbox')));
    await tester.pumpAndSettle();
    // rpg is still selected, and tags match any-of, so the game still shows.
    expect(find.byType(GameCard), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-tag-rpg')));
    await tester.pumpAndSettle();
    expect(find.byType(GameCard), findsNothing);
  });

  testWidgets('LibraryPage filter drawer golden', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();
    await _openFilters(tester);

    await tester.tap(find.byKey(const Key('library-tag-rpg')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LibraryPage),
      matchesGoldenFile('goldens/library_page_filters.png'),
    );
  });

  testWidgets('LibrarySortSheet golden', (tester) async {
    await tester.pumpWidget(await _pumpReady(tester));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('library-sort-button')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LibrarySortSheet),
      matchesGoldenFile('goldens/library_sort_sheet.png'),
    );
  });
}
