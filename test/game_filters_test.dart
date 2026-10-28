import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/game_filters.dart';
import 'package:f95hub/widgets/multi_select_field.dart';

import 'support/fake_metadata_source.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(width: 900, height: 360, child: child),
    ),
  ),
);

void main() {
  testWidgets('selecting a prefix option invokes onPrefixesChanged', (
    tester,
  ) async {
    final calls = <Set<int>>[];
    await tester.pumpWidget(
      _wrap(
        GameFilters(
          tagTable: makeTagTable(),
          selectedTags: const {},
          selectedPrefixes: const {},
          date: null,
          onTagsChanged: (_) {},
          onPrefixesChanged: calls.add,
          onDateChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('filter-section-Engine')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Unity'));
    await tester.pumpAndSettle();

    expect(calls.map((set) => set.join(',')), contains('3'));
  });

  testWidgets('selecting a tag option invokes onTagsChanged with the set', (
    tester,
  ) async {
    final calls = <Set<int>>[];
    await tester.pumpWidget(
      _wrap(
        GameFilters(
          tagTable: makeTagTable(),
          selectedTags: const {},
          selectedPrefixes: const {},
          date: null,
          onTagsChanged: calls.add,
          onPrefixesChanged: (_) {},
          onDateChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('filter-section-Category')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'rpg'));
    await tester.pumpAndSettle();

    expect(calls, [
      {45},
    ]);
  });

  testWidgets('GameFilters renders sections with multi-select fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameFilters(
          tagTable: makeTagTable(),
          selectedTags: const {45},
          selectedPrefixes: const {3},
          date: null,
          onTagsChanged: (_) {},
          onPrefixesChanged: (_) {},
          onDateChanged: (_) {},
        ),
      ),
    );

    // Section labels.
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Engine'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    // One multi-select field per section.
    expect(find.byType(MultiSelectField), findsNWidgets(3));

    // The "Other" prefix group (VN/Collection/SiteRip) is gone.
    expect(find.text('VN'), findsNothing);
    expect(find.text('Collection'), findsNothing);
    expect(find.text('SiteRip'), findsNothing);

    // Date control.
    expect(find.text('Anytime'), findsOneWidget);

    await expectLater(
      find.byType(GameFilters),
      matchesGoldenFile('goldens/game_filters.png'),
    );
  });
}
