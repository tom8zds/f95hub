import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/version_side_by_side.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: 500, height: 120, child: child),
    ),
  ),
);

void main() {
  testWidgets('shows local and latest side by side with a 不同 flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const VersionSideBySide(version: 'v0.0.1', latestVersion: 'v0.0.2'),
      ),
    );

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('v0.0.1'), findsOneWidget);
    expect(find.text('v0.0.2'), findsOneWidget);
    expect(find.text('Different'), findsOneWidget);
    expect(find.text('有更新'), findsNothing);
  });

  testWidgets('shows no flag when versions match', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VersionSideBySide(version: 'v1.2.3', latestVersion: 'v1.2.3'),
      ),
    );

    expect(find.text('Different'), findsNothing);
    expect(find.text('有更新'), findsNothing);
    expect(find.text('v1.2.3'), findsNWidgets(2));
  });

  testWidgets('renders a dash for unknown versions', (tester) async {
    await tester.pumpWidget(
      _wrap(const VersionSideBySide(version: '', latestVersion: '')),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Different'), findsNothing);
  });

  testWidgets('shows the edit affordance only when a callback is given', (
    tester,
  ) async {
    var edits = 0;
    await tester.pumpWidget(
      _wrap(
        VersionSideBySide(
          version: 'v0.0.1',
          latestVersion: 'v0.0.2',
          onEditVersion: () => edits++,
        ),
      ),
    );

    expect(find.byTooltip('Edit version'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit version'));
    expect(edits, 1);

    await tester.pumpWidget(
      _wrap(
        const VersionSideBySide(version: 'v0.0.1', latestVersion: 'v0.0.2'),
      ),
    );
    expect(find.byTooltip('Edit version'), findsNothing);
  });

  testWidgets('golden preview', (tester) async {
    await tester.pumpWidget(
      _wrap(
        VersionSideBySide(
          version: 'v0.0.1',
          latestVersion: 'v0.0.2',
          onEditVersion: () {},
        ),
      ),
    );

    await expectLater(
      find.byType(VersionSideBySide),
      matchesGoldenFile('goldens/version_side_by_side.png'),
    );
  });
}
