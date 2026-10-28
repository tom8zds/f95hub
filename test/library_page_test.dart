import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/pages/library_detail_page.dart';
import 'package:f95hub/pages/library_page.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/state/library_view.dart';
import 'package:f95hub/widgets/game_card.dart';

import 'support/fake_metadata_source.dart';

void main() {
  (Widget, DriftLibraryStore) buildScope(List<Game> games) {
    final db = LibraryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftLibraryStore(db);
    final widget = ProviderScope(
      overrides: [
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        libraryStoreProvider.overrideWithValue(store),
        latestVersionLookupProvider.overrideWithValue((_) async => null),
      ],
      child: const MaterialApp(
        home: SizedBox(width: 900, height: 700, child: LibraryPage()),
      ),
    );
    return (widget, store);
  }

  testWidgets('LibraryPage renders the stored games', (tester) async {
    final (widget, store) = buildScope([
      makeGame(1, title: 'Stored Game 1'),
      makeGame(2, title: 'Stored Game 2'),
    ]);
    await store.upsertGame(makeGame(1, title: 'Stored Game 1'));
    await store.upsertGame(makeGame(2, title: 'Stored Game 2'));

    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameCard), findsNWidgets(2));
    expect(find.text('Stored Game 1'), findsOneWidget);
    expect(find.text('Stored Game 2'), findsOneWidget);

    await expectLater(
      find.byType(LibraryPage),
      matchesGoldenFile('goldens/library_page.png'),
    );
  });

  testWidgets('tapping a card opens the detail page', (tester) async {
    final game = makeGame(1, title: 'Stored Game 1');
    final (widget, store) = buildScope([game]);
    await store.upsertGame(game);

    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(GameCard));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryDetailPage), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryDetailPage), findsNothing);
    expect(find.byType(GameCard), findsOneWidget);
  });

  testWidgets('LibraryPage shows an empty state', (tester) async {
    final (widget, _) = buildScope(const []);

    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();

    expect(find.text('No games in your library yet'), findsOneWidget);
  });
}
