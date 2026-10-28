import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/empty_state.dart';
import 'package:f95hub/widgets/skeleton.dart';

void main() {
  testWidgets('SkeletonGrid golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonGrid(count: 8))),
    );

    await expectLater(
      find.byType(SkeletonGrid),
      matchesGoldenFile('goldens/skeleton_grid.png'),
    );
  });

  testWidgets('DetailSkeleton renders both panes on a wide surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DetailSkeleton())),
    );

    expect(find.byType(SingleChildScrollView), findsNWidgets(2));

    await expectLater(
      find.byType(DetailSkeleton),
      matchesGoldenFile('goldens/skeleton_detail.png'),
    );
  });

  testWidgets('EmptyState shows title, message, and invokes its action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.cloud_off,
            title: 'Failed to load',
            message: 'Try again later.',
            actionLabel: 'Retry',
            onAction: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Try again later.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(taps, 1);
    // Let the button's ripple finish before capturing the golden.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(EmptyState),
      matchesGoldenFile('goldens/empty_state.png'),
    );
  });

  testWidgets('EmptyState hides message and action when unset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.library_books, title: 'No games yet'),
        ),
      ),
    );

    expect(find.text('No games yet'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
