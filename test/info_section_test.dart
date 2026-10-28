import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/info_section.dart';

void main() {
  testWidgets('InfoSection renders its title and content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 100,
            child: InfoSection(
              title: 'Description',
              child: Text('A short overview.'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Description'), findsOneWidget);
    expect(find.text('A short overview.'), findsOneWidget);

    await expectLater(
      find.byType(InfoSection),
      matchesGoldenFile('goldens/info_section.png'),
    );
  });
}
