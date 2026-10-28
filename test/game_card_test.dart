import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/models.dart';
import 'package:f95hub/theme/tokens.dart';
import 'package:f95hub/widgets/game_card.dart';

Game _game({
  String? cover,
  String version = 'v0.0.1',
  List<String> tags = const [],
}) => Game(
  threadId: 319855,
  title: 'Kunoichi Sensei',
  creator: 'NTRNoob',
  version: version,
  cover: cover,
  tags: tags,
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 24),
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, height: 300, child: child)),
  ),
);

void main() {
  testWidgets(
    'GameCard lays out a 16:9 cover, dark gradient, ellipsized name, version chip',
    (tester) async {
      await tester.pumpWidget(_host(GameCard(game: _game(tags: ['rpg']))));

      // 16:9 cover.
      final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspect.aspectRatio, 16 / 9);

      // Bottom→middle dark gradient overlay.
      final gradient = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<LinearGradient>()
          .first;
      expect(gradient.begin, Alignment.bottomCenter);
      expect(gradient.end, Alignment.center);
      expect(gradient.colors, AppOverlay.coverGradient);

      // Name is a single ellipsized line, with the full title on hover.
      final title = tester.widget<Text>(find.text('Kunoichi Sensei'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.byType(Tooltip), findsOneWidget);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Kunoichi Sensei',
      );

      // Version chip is present.
      expect(find.text('v0.0.1'), findsOneWidget);
    },
  );

  testWidgets('GameCard hides the version chip when there is no version', (
    tester,
  ) async {
    await tester.pumpWidget(_host(GameCard(game: _game(version: ''))));

    // Title renders but no version text is shown.
    expect(find.text('Kunoichi Sensei'), findsOneWidget);
    expect(find.text('v0.0.1'), findsNothing);
  });

  testWidgets('GameCard fades in a hover scrim over the cover', (tester) async {
    await tester.pumpWidget(_host(GameCard(game: _game(), onTap: () {})));

    AnimatedOpacity scrim() => tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byType(ColoredBox),
        matching: find.byType(AnimatedOpacity),
      ).first,
    );
    expect(scrim().opacity, 0);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: tester.getCenter(find.byType(GameCard)));
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle(AppDurations.fast * 2);

    expect(scrim().opacity, 1);
  });

  testWidgets('GameCard shows the update badge only when hasUpdate is set', (
    tester,
  ) async {
    await tester.pumpWidget(_host(GameCard(game: _game(), hasUpdate: true)));

    expect(find.text('Update available'), findsOneWidget);
    expect(find.byKey(const Key('game-update-badge-319855')), findsOneWidget);

    await tester.pumpWidget(_host(GameCard(game: _game())));
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('GameCard lifts its shadow on hover', (tester) async {
    await tester.pumpWidget(_host(GameCard(game: _game(), onTap: () {})));

    Color shadowColor() {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      return decoration.boxShadow!.first.color;
    }

    expect(shadowColor(), Colors.transparent);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: tester.getCenter(find.byType(GameCard)));
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle(AppDurations.fast * 2);

    expect(shadowColor(), Colors.black26);
  });

  testWidgets('GameCard golden (update badge)', (tester) async {
    await tester.pumpWidget(
      _host(GameCard(game: _game(tags: ['rpg', '3dcg']), hasUpdate: true)),
    );

    await expectLater(
      find.byType(GameCard),
      matchesGoldenFile('goldens/game_card_update.png'),
    );
  });

  testWidgets('GameCard golden', (tester) async {
    await tester.pumpWidget(
      _host(GameCard(game: _game(tags: ['rpg', '3dcg', '2dcg', 'sandbox']))),
    );

    await expectLater(
      find.byType(GameCard),
      matchesGoldenFile('goldens/game_card.png'),
    );
  });
}
