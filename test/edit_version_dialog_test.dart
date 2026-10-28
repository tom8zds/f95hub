import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/edit_version_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    required String initialVersion,
    required void Function(String?) onResult,
  }) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      EditVersionDialog(initialVersion: initialVersion),
                );
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fills the current version and pops the edited text', (
    tester,
  ) async {
    String? saved;
    await openDialog(
      tester,
      initialVersion: 'v0.0.1',
      onResult: (value) => saved = value,
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'v0.0.1',
    );

    await tester.enterText(find.byType(TextField), 'v0.1.0 custom');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, 'v0.1.0 custom');
  });

  testWidgets('saving an empty field pops an empty string', (tester) async {
    String? saved;
    await openDialog(
      tester,
      initialVersion: 'v0.0.1',
      onResult: (value) => saved = value,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, '');
  });

  testWidgets('cancel pops null', (tester) async {
    var called = false;
    String? saved;
    await openDialog(
      tester,
      initialVersion: 'v0.0.1',
      onResult: (value) {
        called = true;
        saved = value;
      },
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(saved, isNull);
  });
}
