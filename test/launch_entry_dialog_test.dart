import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/launch_entry_dialog.dart';

void main() {
  const entries = [
    r'C:\games\game7\Game.exe',
    r'C:\games\game7\bin\Launcher.exe',
  ];

  testWidgets('tapping an entry pops its path and marks the current choice', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showDialog<String>(
                  context: context,
                  builder: (_) => const LaunchEntryDialog(
                    entries: entries,
                    selectedPath: r'C:\games\game7\Game.exe',
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Game.exe'), findsOneWidget);
    expect(find.text('Launcher.exe'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Launcher.exe'));
    await tester.pumpAndSettle();

    expect(picked, r'C:\games\game7\bin\Launcher.exe');
  });

  testWidgets('golden preview', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LaunchEntryDialog(
            entries: entries,
            selectedPath: r'C:\games\game7\Game.exe',
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(LaunchEntryDialog),
      matchesGoldenFile('goldens/launch_entry_dialog.png'),
    );
  });
}
