import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/models.dart';
import 'package:f95hub/widgets/cover_image.dart';
import 'package:f95hub/widgets/game_search_results.dart';

import 'support/fake_cache_manager.dart';

Game _game(int id, String title, {String creator = 'Creator', String? cover}) =>
    Game(
      threadId: id,
      title: title,
      creator: creator,
      cover: cover,
      latestVersion: 'v0.0.1',
      createdAt: DateTime(2026, 10, 24),
      updatedAt: DateTime(2026, 10, 24),
    );

void main() {
  testWidgets('list shows title, creator and disables every tile while busy', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameSearchResults(
            games: [_game(1, 'Secret Care Cafe'), _game(2, 'Another Game')],
            busyThreadId: 1,
            onSelect: (_) => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Secret Care Cafe'), findsOneWidget);
    expect(find.text('Creator'), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Another Game'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('a result with a cover renders a 48x48 rounded thumbnail', (
    tester,
  ) async {
    final cache = FakeCacheManager();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameSearchResults(
            games: [
              _game(
                1,
                'Secret Care Cafe',
                cover: 'https://preview.f95zone.to/cover.png',
              ),
            ],
            cacheManager: cache,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final cover = tester.widget<CoverImage>(find.byType(CoverImage));
    expect(cover.url, 'https://preview.f95zone.to/cover.png');
    expect(cover.cacheManager, same(cache));
    expect(tester.getSize(find.byType(CoverImage)), const Size(48, 48));

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://preview.f95zone.to/cover.png');
    expect(image.cacheManager, same(cache));
  });

  testWidgets('a result without a cover renders the placeholder icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameSearchResults(
            games: [_game(1, 'Secret Care Cafe')],
            cacheManager: FakeCacheManager(),
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    expect(tester.getSize(find.byType(CoverImage)), const Size(48, 48));
  });

  testWidgets('list golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 240,
            child: GameSearchResults(
              games: [
                _game(
                  1,
                  'Secret Care Cafe',
                  creator: 'Rare Alex',
                  cover: 'https://preview.f95zone.to/cover.png',
                ),
                _game(2, 'Another Game', creator: 'Someone'),
              ],
              cacheManager: FakeCacheManager(),
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    // The fake manager fails every load; the error placeholder settles.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameSearchResults),
      matchesGoldenFile('goldens/game_search_results.png'),
    );
  });

  testWidgets('empty-index hint names the cache and Settings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GameIndexEmptyHint())),
    );

    expect(find.text('Game index is empty'), findsOneWidget);
    expect(
      find.text(
        'Build the game cache in Settings to search the whole catalogue '
        'offline.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty-index hint golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 480, height: 240, child: GameIndexEmptyHint()),
        ),
      ),
    );

    await expectLater(
      find.byType(GameIndexEmptyHint),
      matchesGoldenFile('goldens/game_index_empty_hint.png'),
    );
  });
}
