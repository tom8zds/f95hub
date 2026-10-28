import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/cover_image.dart';

import 'support/fake_cache_manager.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, height: 180, child: child)),
  ),
);

void main() {
  testWidgets('missing url renders the plain placeholder without touching the '
      'cache', (tester) async {
    await tester.pumpWidget(_host(const CoverImage()));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
  });

  testWidgets('url loads through the injected disk cache manager', (
    tester,
  ) async {
    final cache = FakeCacheManager();

    await tester.pumpWidget(
      _host(
        CoverImage(
          url: 'https://preview.f95zone.to/cover.png',
          cacheManager: cache,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://preview.f95zone.to/cover.png');
    expect(image.cacheManager, same(cache));
    expect(image.fit, BoxFit.cover);
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
