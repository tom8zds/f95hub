import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/models.dart';
import 'package:f95hub/state/detail_tabs.dart';
import 'package:f95hub/widgets/detail_pane.dart';

import 'support/fake_metadata_source.dart';

Widget _emptyTab(Game game) => const SizedBox.shrink();

void main() {
  testWidgets('DetailTabsPane uses pill tabs and enables the scroll controls',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      detailTabsProvider(DetailPaneScope.games).notifier,
    );
    for (var i = 0; i < 8; i++) {
      controller.open(makeGame(i, title: 'Sample Game $i'));
    }
    controller.activate(0);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: kDetailPaneWidth,
              height: 600,
              child: DetailTabsPane(
                scope: DetailPaneScope.games,
                tabBuilder: _emptyTab,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The active chip is a stadium (fully rounded) button.
    final chip = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const Key('detail-tab-chip-0')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(chip.shape, isA<StadiumBorder>());

    // Both controls are permanent; at the start the left one is disabled and
    // the right one enabled because chips overflow.
    final left = tester.widget<IconButton>(
      find.byKey(const Key('detail-tabs-scroll-left')),
    );
    final right = tester.widget<IconButton>(
      find.byKey(const Key('detail-tabs-scroll-right')),
    );
    expect(left.onPressed, isNull);
    expect(right.onPressed, isNotNull);
    expect(find.byIcon(Icons.keyboard_double_arrow_left), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_double_arrow_right), findsOneWidget);

    await expectLater(
      find.byType(DetailTabsPane),
      matchesGoldenFile('goldens/detail_tabs_pane.png'),
    );
  });
}
