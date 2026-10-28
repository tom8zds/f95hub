import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/widgets/filter_drawer.dart';

import 'support/fake_metadata_source.dart';

/// Pumps a [FilterDrawer] hosted as a Scaffold `endDrawer` and opens it, so the
/// drawer controls are on screen and its golden is the opened drawer.
Future<void> _pumpOpenDrawer(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final key = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          key: key,
          endDrawer: const FilterDrawer(),
          body: const SizedBox.expand(),
        ),
      ),
    ),
  );
  key.currentState!.openEndDrawer();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FilterDrawer renders the filter controls and apply button', (
    tester,
  ) async {
    final source = FakeMetadataSource(const [], tagTable: makeTagTable());
    final container = ProviderContainer(
      overrides: [metadataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);

    await _pumpOpenDrawer(tester, container);
    await container.read(gameListProvider.notifier).load();
    await tester.pump();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    // Multi-select fields show the "All" placeholder until something is picked.
    expect(find.text('All'), findsNWidgets(3));
    expect(find.text('Apply'), findsOneWidget);

    await expectLater(
      find.byType(FilterDrawer),
      matchesGoldenFile('goldens/filter_drawer.png'),
    );
  });

  testWidgets('selecting a tag in the dropdown updates the list state', (
    tester,
  ) async {
    final source = FakeMetadataSource(const [], tagTable: makeTagTable());
    final container = ProviderContainer(
      overrides: [metadataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);

    // Load first so the tag table exists and the 类别 section is built (it is
    // skipped while the table is empty).
    await container.read(gameListProvider.notifier).load();

    await _pumpOpenDrawer(tester, container);
    await tester.pump();

    expect(source.lastTags, isNull);

    await tester.tap(find.byKey(const ValueKey('filter-section-Category')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'rpg'));
    await tester.pumpAndSettle();

    expect(source.lastTags, [45]);
  });
}
