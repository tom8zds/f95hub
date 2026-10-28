import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/game_index_codec.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/state/game_index.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';

import 'support/fake_metadata_source.dart';

GameIndexRow _row(int threadId, {String? cover}) => GameIndexRow(
  threadId: threadId,
  title: 'Game $threadId',
  normalizedTitle: 'game $threadId',
  compactTitle: 'game$threadId',
  creator: 'dev',
  latestVersion: 'v1.0',
  cover: cover,
  screens: '["https://img/s1.png"]',
  tags: '[45]',
  prefixes: '[3]',
  rating: 4.5,
  views: 100,
  likes: 10,
  ts: 1790000000,
  cachedAt: DateTime(2026, 10, 25),
);

GameIndexSnapshot _snapshot() => GameIndexSnapshot(
  rows: [_row(1), _row(2, cover: null), _row(3, cover: 'https://img/c.png')],
  snapshotAt: DateTime(2026, 10, 25, 12),
  totalPages: 931,
);

void main() {
  test('snapshot codec roundtrips rows and bookkeeping', () {
    final snapshot = _snapshot();
    final bytes = encodeGameIndexSnapshot(snapshot);
    final decoded = decodeGameIndexSnapshot(bytes);

    expect(decoded.totalPages, 931);
    expect(decoded.snapshotAt, snapshot.snapshotAt);
    expect(decoded.rows, hasLength(3));
    // Row-level fidelity, including the null-cover edge.
    expect(decoded.rows[1].cover, isNull);
    expect(decoded.rows[2].cover, 'https://img/c.png');
    expect(decoded.rows.first.title, 'Game 1');
    expect(decoded.rows.first.screens, '["https://img/s1.png"]');
    expect(decoded.rows.first.rating, 4.5);
    expect(decoded.rows.first.ts, 1790000000);
  });

  test('seed fills an empty index and marks the build complete', () async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = GameIndexStore(db, FakeMetadataSource(const []));

    final count = await store.seed(_snapshot());

    expect(count, 3);
    expect(await store.count(), 3);
    expect(await store.lastBuiltPage(), 931);
    expect(await store.totalPages(), 931);
    expect(await store.lastUpdated(), DateTime(2026, 10, 25, 12));
  });

  test('seed never touches a non-empty index', () async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = GameIndexStore(
      db,
      FakeMetadataSource([makeGame(7, title: 'Existing')]),
      clock: () => DateTime(2026, 1, 1),
    );
    await store.buildAll();

    final count = await store.seed(_snapshot());

    expect(count, 1);
    expect(await store.count(), 1);
    // The user's own bookkeeping is preserved.
    expect(await store.totalPages(), isNot(931));
  });

  test('loadStats seeds an empty index from the bundled snapshot', () async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final bytes = encodeGameIndexSnapshot(_snapshot());
    final container = ProviderContainer(
      overrides: [
        libraryDatabaseProvider.overrideWithValue(db),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        gameIndexSeedAssetProvider.overrideWithValue(() async => bytes),
      ],
    );
    addTearDown(container.dispose);

    await container.read(gameIndexProvider.notifier).loadStats();

    final state = container.read(gameIndexProvider);
    expect(state.count, 3);
    expect(state.hasCache, isTrue);
    expect(state.complete, isTrue);
    expect(state.lastUpdated, DateTime(2026, 10, 25, 12));
  });

  test('a missing bundle leaves the empty index untouched', () async {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        libraryDatabaseProvider.overrideWithValue(db),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
        gameIndexSeedAssetProvider.overrideWithValue(() async => null),
      ],
    );
    addTearDown(container.dispose);

    await container.read(gameIndexProvider.notifier).loadStats();

    expect(container.read(gameIndexProvider).count, 0);
    expect(container.read(gameIndexProvider).hasCache, isFalse);
  });
}
