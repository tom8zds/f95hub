import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decodes every mounted [Image] before a golden snapshot, so the snapshot
/// contains the artwork rather than an empty box (asset decoding is a real
/// asynchronous step that `pump` alone does not drive).
Future<void> settleMountedImages(WidgetTester tester) async {
  final elements = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in elements) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}
