import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/pages/game_detail_page.dart';
import 'package:f95hub/state/game_detail.dart';

import 'support/fake_metadata_source.dart';

void main() {
  testWidgets('GameDetailView renders cover, info sections and description', (
    tester,
  ) async {
    // Wide enough for the two-pane layout (the default 800px surface would
    // clamp the host box down to the narrow breakpoint).
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = makeGame(
      7,
      title: 'Kunoichi Sensei',
      tagIds: const [45, 107],
      prefixIds: const [3, 13],
    );
    final details = resolveGameDetails(game, makeTagTable());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: GameDetailView(
              game: game,
              details: details,
              description: 'A ninja training sim.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Kunoichi Sensei'), findsOneWidget);
    expect(find.text('rpg'), findsOneWidget);
    expect(find.text('VN'), findsOneWidget);
    expect(find.text('Unity'), findsOneWidget);
    expect(find.text('Creator 7'), findsOneWidget);
    expect(find.text('A ninja training sim.'), findsOneWidget);

    // Wide layout: sidebar and content scroll independently.
    expect(find.byType(SingleChildScrollView), findsNWidgets(2));

    await expectLater(
      find.byType(GameDetailView),
      matchesGoldenFile('goldens/game_detail_view.png'),
    );
  });

  testWidgets('GameDetailView stacks a single column below the wide breakpoint', (
    tester,
  ) async {
    final game = makeGame(
      7,
      title: 'Kunoichi Sensei',
      tagIds: const [45, 107],
      prefixIds: const [3, 13],
    );
    final details = resolveGameDetails(game, makeTagTable());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 900,
            child: GameDetailView(
              game: game,
              details: details,
              description: 'A ninja training sim.',
            ),
          ),
        ),
      ),
    );

    // Single scrolling column: one scroll view, not the wide layout's two.
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await expectLater(
      find.byType(GameDetailView),
      matchesGoldenFile('goldens/game_detail_view_narrow.png'),
    );
  });
}
