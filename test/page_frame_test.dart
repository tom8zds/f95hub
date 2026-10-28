import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/page_frame.dart';

void main() {
  testWidgets('PageFrame renders its title bar and content slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PageFrame(
          title: 'Games',
          child: Center(child: Text('content')),
        ),
      ),
    );

    await expectLater(
      find.byType(PageFrame),
      matchesGoldenFile('goldens/page_frame.png'),
    );
  });

  testWidgets('PageFrame shows the progress bar while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PageFrame(
          title: 'Games',
          loading: true,
          child: Center(child: Text('content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageLoadingBar), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await expectLater(
      find.byType(PageFrame),
      matchesGoldenFile('goldens/page_frame_loading.png'),
    );
  });

  testWidgets('PageFrame omits the progress bar when not loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PageFrame(
          title: 'Games',
          loading: false,
          child: Center(child: Text('content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageLoadingBar), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('PageFrame tracks loading changes', (tester) async {
    final loading = ValueNotifier<bool>(true);
    addTearDown(loading.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: loading,
          builder: (_, value, _) => PageFrame(
            title: 'Games',
            loading: value,
            child: const Center(child: Text('content')),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PageLoadingBar), findsOneWidget);

    loading.value = false;
    await tester.pump();
    expect(find.byType(PageLoadingBar), findsNothing);

    loading.value = true;
    await tester.pump();
    expect(find.byType(PageLoadingBar), findsOneWidget);
  });
}
