import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/tag_chips.dart';

void main() {
  testWidgets('TagChips renders a chip per tag', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 100,
            child: TagChips(tags: ['rpg', '3dcg', '2dcg', 'ai cg']),
          ),
        ),
      ),
    );

    expect(find.text('rpg'), findsOneWidget);
    expect(find.text('ai cg'), findsOneWidget);

    await expectLater(
      find.byType(TagChips),
      matchesGoldenFile('goldens/tag_chips.png'),
    );
  });
}
