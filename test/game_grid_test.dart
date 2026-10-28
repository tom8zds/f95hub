import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/models.dart';
import 'package:f95hub/widgets/game_card.dart';
import 'package:f95hub/widgets/game_grid.dart';

List<Game> _games() => List.generate(
  4,
  (i) => Game(
    threadId: i,
    title: 'Game $i',
    creator: 'Creator $i',
    version: 'v0.0.$i',
    createdAt: DateTime(2026, 10, 24),
    updatedAt: DateTime(2026, 10, 24),
  ),
);

/// Number of distinct card left-edges laid out — i.e. the column count.
int _columnCount(WidgetTester tester) {
  final finder = find.byType(GameCard);
  final lefts = <double>{};
  final count = tester.widgetList(finder).length;
  for (var i = 0; i < count; i++) {
    lefts.add(tester.getRect(finder.at(i)).left);
  }
  return lefts.length;
}

/// Widest laid-out card.
double _maxCardWidth(WidgetTester tester) {
  final finder = find.byType(GameCard);
  var width = 0.0;
  final count = tester.widgetList(finder).length;
  for (var i = 0; i < count; i++) {
    final w = tester.getRect(finder.at(i)).width;
    if (w > width) width = w;
  }
  return width;
}

void main() {
  testWidgets('GameGrid renders a grid of cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: GameGrid(games: _games()),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(GameGrid),
      matchesGoldenFile('goldens/game_grid.png'),
    );
  });

  testWidgets('column count adapts to width and cards stay ≈300px wide', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;

    Future<void> pumpAt(double width) async {
      tester.view.physicalSize = Size(width, 600);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GameGrid(games: _games()))),
      );
    }

    await pumpAt(320);
    expect(_columnCount(tester), 1);

    await pumpAt(600);
    expect(_columnCount(tester), 2);

    await pumpAt(900);
    expect(_columnCount(tester), 3);

    await pumpAt(1200);
    expect(_columnCount(tester), 4);

    // Cards never stretch beyond ~300px (+ one cross-axis spacing tolerance).
    expect(_maxCardWidth(tester), lessThanOrEqualTo(312));
  });
}
