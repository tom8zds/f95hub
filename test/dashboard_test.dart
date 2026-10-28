import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/domain/models.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/pages/dashboard_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

void main() {
  testWidgets('dashboard shows the library hero, playtime stats and cache', (
    tester,
  ) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftLibraryStore(db);
    await store.upsertGame(
      Game(
        threadId: 1,
        title: 'Game One',
        creator: 'dev',
        version: 'v1',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      ),
    );
    await store.upsertGame(
      Game(
        threadId: 2,
        title: 'Game Two',
        creator: 'dev',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(store),
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
          home: SizedBox(width: 900, height: 700, child: DashboardPage()),
        ),
      ),
    );
    await container.read(libraryProvider.notifier).refresh();
    await tester.pump();
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // hero only; stats no longer repeat it
    expect(find.text('Library games'), findsOneWidget);
    expect(find.text('Play time'), findsOneWidget);
    expect(find.text('Games played'), findsOneWidget);
    expect(find.text('Game index'), findsOneWidget);
    expect(find.text('never'), findsOneWidget); // cache not built here
    // Hero card and quick-access tiles navigate via onOpenDestination.
    await tester.tap(find.byKey(const Key('dashboard-tile-1')));
    expect(find.byKey(const Key('dashboard-hero')), findsOneWidget);
  });

  testWidgets('dashboard lays out at a narrow width without an infinite height',
      (tester) async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftLibraryStore(db);
    await store.upsertGame(
      Game(
        threadId: 1,
        title: 'Game One',
        creator: 'dev',
        version: 'v1',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(store),
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
          home: SizedBox(width: 480, height: 700, child: DashboardPage()),
        ),
      ),
    );
    await container.read(libraryProvider.notifier).refresh();
    await tester.pump();
    await tester.pump();

    // The hero used to force an infinite height inside the narrow ListView.
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('dashboard-hero')), findsOneWidget);
  });
}
