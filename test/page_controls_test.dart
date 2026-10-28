import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/page_controls.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// Asserts the pagination chips show [page] / [total].
void expectPage(WidgetTester tester, int page, int total) {
  Text chip(String key) =>
      tester.widget<Chip>(find.byKey(Key(key))).label as Text;
  expect(chip('page-current').data, '$page');
  expect(chip('page-total').data, '$total');
}

void main() {
  testWidgets('renders page indicator and both buttons enabled mid-range', (
    tester,
  ) async {
    var prev = 0;
    var next = 0;
    await tester.pumpWidget(
      _wrap(
        PageControls(
          page: 2,
          totalPages: 5,
          onPrev: () => prev++,
          onNext: () => next++,
        ),
      ),
    );

    expectPage(tester, 2, 5);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.byKey(const Key('page-prev')));
    await tester.tap(find.byKey(const Key('page-next')));
    expect(prev, 1);
    expect(next, 1);
  });

  testWidgets('disables 上一页 on the first page and 下一页 on the last', (
    tester,
  ) async {
    var prev = 0;
    var next = 0;
    await tester.pumpWidget(
      _wrap(
        PageControls(
          page: 1,
          totalPages: 1,
          onPrev: () => prev++,
          onNext: () => next++,
        ),
      ),
    );

    expectPage(tester, 1, 1);

    final prevButton =
        tester.widget<ElevatedButton>(find.byKey(const Key('page-prev')));
    final nextButton =
        tester.widget<ElevatedButton>(find.byKey(const Key('page-next')));
    expect(prevButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('page-prev')));
    await tester.tap(find.byKey(const Key('page-next')));
    expect(prev, 0);
    expect(next, 0);
  });

  testWidgets('on the first page of many only 上一页 is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PageControls(
          page: 1,
          totalPages: 3,
          onPrev: () {},
          onNext: () {},
        ),
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-prev'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-next'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('on the last page of many only 下一页 is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PageControls(
          page: 3,
          totalPages: 3,
          onPrev: () {},
          onNext: () {},
        ),
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-prev'))).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('page-next'))).onPressed,
      isNull,
    );
  });

  testWidgets('PageControls golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PageControls(page: 2, totalPages: 5),
      ),
    );

    await expectLater(
      find.byType(PageControls),
      matchesGoldenFile('goldens/page_controls.png'),
    );
  });
}
