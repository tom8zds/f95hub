import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/remove_game_dialog.dart';

void main() {
  testWidgets('pops keepFiles for 保留文件', (tester) async {
    RemoveChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showDialog<RemoveChoice>(
                  context: context,
                  builder: (_) => const RemoveGameDialog(title: 'Kunoichi'),
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

    expect(
      find.text('Remove "Kunoichi" from your library?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep files'));
    await tester.pumpAndSettle();

    expect(result, RemoveChoice.keepFiles);
  });

  testWidgets('pops deleteFiles for 删除文件', (tester) async {
    RemoveChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showDialog<RemoveChoice>(
                  context: context,
                  builder: (_) => const RemoveGameDialog(title: 'Kunoichi'),
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

    await tester.tap(find.text('Delete files'));
    await tester.pumpAndSettle();

    expect(result, RemoveChoice.deleteFiles);
  });

  testWidgets('golden preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const RemoveGameDialog(title: 'Kunoichi Sensei'),
      ),
    );

    await expectLater(
      find.byType(RemoveGameDialog),
      matchesGoldenFile('goldens/remove_game_dialog.png'),
    );
  });
}
