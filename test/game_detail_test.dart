import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/pages/game_detail_page.dart';
import 'package:f95hub/state/game_detail.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/widgets/skeleton.dart';

import 'support/fake_metadata_source.dart';

Widget _scope(FakeMetadataSource source, Widget child) {
  return ProviderScope(
    overrides: [metadataSourceProvider.overrideWithValue(source)],
    child: child,
  );
}

void main() {
  group('resolveGameDetails', () {
    test('maps tag and prefix ids to names', () {
      final game = makeGame(
        1,
        tagIds: [45, 107, 9999],
        prefixIds: [3, 13],
      );
      final details = resolveGameDetails(game, makeTagTable());

      expect(details.tags, ['rpg', '3dcg']);
      expect(details.engines, ['Unity']);
      expect(details.categories, ['VN']);
    });

    test('handles a game with no ids', () {
      final details = resolveGameDetails(makeGame(1), makeTagTable());
      expect(details.tags, isEmpty);
      expect(details.engines, isEmpty);
      expect(details.categories, isEmpty);
    });
  });

  testWidgets('GameDetailPage renders resolved details and description', (
    tester,
  ) async {
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
      prefixIds: const [3, 13],
    );

    await tester.pumpWidget(
      _scope(
        source,
        MaterialApp(
          home: SizedBox(width: 900, height: 700, child: GameDetailPage(game: game)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The detail's floating action opens the thread in the browser.
    expect(find.text('Open in browser'), findsOneWidget);
    // The AppBar is gone; the back button sits beside the content title.
    expect(find.byType(BackButton), findsOneWidget);

    // Tags (resolved names), category/engine (resolved prefix names).
    expect(find.text('rpg'), findsOneWidget);
    expect(find.text('3dcg'), findsOneWidget);
    expect(find.text('VN'), findsOneWidget);
    expect(find.text('Unity'), findsOneWidget);
    // Developer falls back to the creator.
    expect(find.text('Creator 7'), findsOneWidget);
    // Version and description.
    expect(find.text('v0.0.7'), findsOneWidget);
    expect(find.text('A ninja training sim.'), findsOneWidget);
  });

  testWidgets('the back button stays available while the skeleton loads', (
    tester,
  ) async {
    final gate = Completer<void>();
    final source = FakeMetadataSource(
      const [],
      threadDetails: {7: makeThreadDetail(7)},
    )..threadGate = gate;

    await tester.pumpWidget(
      _scope(
        source,
        MaterialApp(
          home: SizedBox(
            width: 900,
            height: 700,
            child: GameDetailPage(game: makeGame(7)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DetailSkeleton), findsOneWidget);
    // The skeleton carries no chrome; the back control floats over it.
    expect(find.byType(BackButton), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(DetailSkeleton), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('GameDetailPage shows error and retries', (tester) async {
    final source = FakeMetadataSource(
      const [],
      tagTable: makeTagTable(),
      threadDetails: {
        7: makeThreadDetail(7, description: 'A ninja training sim.'),
      },
    )..fail = true;

    await tester.pumpWidget(
      _scope(
        source,
        MaterialApp(
          home: SizedBox(
            width: 900,
            height: 700,
            child: GameDetailPage(game: makeGame(7)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to load details'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    // Recover: clear the failure and retry.
    source.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('A ninja training sim.'), findsOneWidget);
  });
}
