import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/library_actions.dart';

void main() {
  testWidgets('fires each action callback and disables open without a path', (
    tester,
  ) async {
    var opened = 0;
    var launched = 0;
    var removed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryActions(
            hasInstallPath: false,
            onOpenFolder: () => opened++,
            onLaunch: () => launched++,
            onRemove: () => removed++,
          ),
        ),
      ),
    );

    final openButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(openButton.onPressed, isNull);

    await tester.tap(find.text('Launch game'));
    await tester.tap(find.text('Remove'));

    expect(opened, 0);
    expect(launched, 1);
    expect(removed, 1);
  });

  testWidgets('golden preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryActions(
            onOpenFolder: () {},
            onLaunch: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(LibraryActions),
      matchesGoldenFile('goldens/library_actions.png'),
    );
  });
}
