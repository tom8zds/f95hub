import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/open_in_browser_button.dart';

import 'support/fake_metadata_source.dart';

void main() {
  testWidgets('opens the f95zone thread URL in the browser', (tester) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: OpenInBrowserButton(
            game: makeGame(7),
            onOpen: (url) async => opened = url,
          ),
        ),
      ),
    );

    expect(find.text('Open in browser'), findsOneWidget);
    await tester.tap(find.text('Open in browser'));
    expect(opened, 'https://f95zone.to/threads/7/');
  });
}
