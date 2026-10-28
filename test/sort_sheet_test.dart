import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/widgets/sort_sheet.dart';

void main() {
  testWidgets('SortSheet renders each sort option with a check on the current', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SortSheet(current: SortOrder.date, onSelected: _noop),
        ),
      ),
    );

    expect(find.text('Sort'), findsOneWidget);
    for (final label in ['Date', 'Likes', 'Views', 'Title', 'Rating']) {
      expect(find.text(label), findsOneWidget);
    }
    // Only the active option is checked.
    expect(find.byIcon(Icons.check), findsOneWidget);

    await expectLater(
      find.byType(SortSheet),
      matchesGoldenFile('goldens/sort_sheet.png'),
    );
  });

  testWidgets('shows the check on a non-default current option', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SortSheet(current: SortOrder.rating, onSelected: _noop),
        ),
      ),
    );

    final ratingTile = find.widgetWithText(ListTile, 'Rating');
    expect(find.descendant(of: ratingTile, matching: find.byIcon(Icons.check)),
        findsOneWidget);
  });
}

void _noop(SortOrder _) {}
