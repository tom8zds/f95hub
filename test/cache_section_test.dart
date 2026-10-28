import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/widgets/cache_section.dart';

import 'support/fake_metadata_source.dart';

/// A source whose request for a chosen page blocks until released, so a widget
/// test can observe the cache mid-build.
class _GatedSource extends FakeMetadataSource {
  _GatedSource(super.games, {super.pageSize});

  final Map<int, Completer<void>> _gates = {};

  void gate(int page) => _gates[page] = Completer<void>();

  void release(int page) => _gates[page]!.complete();

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    final gate = _gates[page];
    if (gate != null) {
      await gate.future;
    }
    return super.listGames(
      cat,
      tags: tags,
      prefixes: prefixes,
      sort: sort,
      date: date,
      page: page,
    );
  }
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
  testWidgets('CacheSection golden (idle with a cache)', (tester) async {
    await _golden(
      tester,
      CacheSection(
        count: 27913,
        lastUpdated: DateTime(2026, 10, 24, 9, 30),
        busy: false,
        page: 0,
        total: 0,
        lastBuiltPage: 3,
        totalPages: 3,
        error: null,
        onBuild: () {},
        onRefresh: () {},
        onClear: () {},
        onCancel: () {},
      ),
      'cache_section',
    );
  });

  testWidgets('CacheSection golden (building)', (tester) async {
    await _golden(
      tester,
      CacheSection(
        count: 0,
        lastUpdated: null,
        busy: true,
        page: 12,
        total: 931,
        lastBuiltPage: 11,
        totalPages: 931,
        error: null,
        onBuild: () {},
        onRefresh: () {},
        onClear: () {},
        onCancel: () {},
      ),
      'cache_section_building',
    );
  });

  testWidgets('delete/refresh are disabled while there is no cache',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CacheSection(
            count: 0,
            lastUpdated: null,
            busy: false,
            page: 0,
            total: 0,
            lastBuiltPage: 0,
            totalPages: 0,
            error: null,
            onBuild: () {},
            onRefresh: () {},
            onClear: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('0 games cached'), findsOneWidget);
    expect(find.text('Last updated: never'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Refresh cache'),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Delete cache'),
      ).onPressed,
      isNull,
    );
  });

  testWidgets('CacheSettingsSection builds, reports and clears the index',
      (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final source = FakeMetadataSource([
      makeGame(1),
      makeGame(2),
      makeGame(3),
    ]);
    final container = ProviderContainer(
      overrides: [
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        gameIndexStoreProvider.overrideWithValue(
          GameIndexStore(db, source, clock: () => DateTime(2026, 10, 24, 9)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CacheSettingsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('0 games cached'), findsOneWidget);

    await tester.tap(find.text('Create cache'));
    await tester.pumpAndSettle();

    expect(find.text('3 games cached'), findsOneWidget);
    expect(find.text('Last updated: 2026-10-24 09:00'), findsOneWidget);
    expect(await db.select(db.gameIndex).get(), hasLength(3));

    await tester.tap(find.text('Delete cache'));
    await tester.pumpAndSettle();

    expect(find.text('0 games cached'), findsOneWidget);
    expect(await db.select(db.gameIndex).get(), isEmpty);
  });

  testWidgets('CacheSection shows the resume point and 继续构建',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CacheSection(
            count: 30,
            lastUpdated: null,
            busy: false,
            page: 0,
            total: 0,
            lastBuiltPage: 1,
            totalPages: 3,
            error: null,
            onBuild: () {},
            onRefresh: () {},
            onClear: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('Reached 1 / 3 pages'), findsOneWidget);
    expect(find.text('Continue build'), findsOneWidget);
    expect(find.text('Create cache'), findsNothing);
    // An interrupted build can still be cleared.
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Delete cache'),
      ).onPressed,
      isNotNull,
    );
  });

  testWidgets('CacheSettingsSection resumes an interrupted build',
      (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final games = List.generate(
      65,
      (i) => makeGame(i + 1, title: 'Game ${i + 1}'),
    );
    final source = FakeMetadataSource(games, pageSize: 30)
      ..rateLimitedPages.add(2);
    final container = ProviderContainer(
      overrides: [
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        gameIndexStoreProvider.overrideWithValue(
          GameIndexStore(db, source, clock: () => DateTime(2026, 10, 24, 9)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CacheSettingsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Create cache'));
    await tester.pumpAndSettle();

    // 429 exhaustion: progress kept, no error, resumable.
    expect(find.text('30 games cached'), findsOneWidget);
    expect(find.text('Reached 1 / 3 pages'), findsOneWidget);
    expect(find.text('Continue build'), findsOneWidget);
    expect(find.text('Last updated: never'), findsOneWidget);

    source.rateLimitedPages.clear();
    await tester.tap(find.text('Continue build'));
    await tester.pumpAndSettle();

    expect(find.text('65 games cached'), findsOneWidget);
    expect(find.text('Reached 1 / 3 pages'), findsNothing);
    expect(find.text('Create cache'), findsOneWidget);
    expect(find.text('Last updated: 2026-10-24 09:00'), findsOneWidget);

    await tester.tap(find.text('Delete cache'));
    await tester.pumpAndSettle();

    expect(find.text('0 games cached'), findsOneWidget);
    expect(await db.select(db.gameIndex).get(), isEmpty);
  });

  testWidgets('CacheSettingsSection counts games as pages land',
      (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final games = List.generate(
      65,
      (i) => makeGame(i + 1, title: 'Game ${i + 1}'),
    );
    final source = _GatedSource(games, pageSize: 30)..gate(2);
    final container = ProviderContainer(
      overrides: [
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
        gameIndexStoreProvider.overrideWithValue(
          GameIndexStore(db, source, clock: () => DateTime(2026, 10, 24, 9)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CacheSettingsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Create cache'));
    // Page 1 lands; the run then waits on the gated page 2 request.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('30 games cached'), findsOneWidget);

    source.release(2);
    await tester.pumpAndSettle();

    expect(find.text('65 games cached'), findsOneWidget);
  });
}
