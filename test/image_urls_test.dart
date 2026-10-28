import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/image_urls.dart';
import 'package:f95hub/state/image_cache.dart';
import 'package:f95hub/widgets/screenshot_gallery.dart';

import 'support/fake_cache_manager.dart';

void main() {
  group('fullSizeImageUrl', () {
    tearDown(() {
      imageCacheCookie = null;
    });

    test(
      'swaps the preview host for the attachments host, keeping the path',
      () {
        expect(
          fullSizeImageUrl(
            'https://preview.f95zone.to/2017/08/27639_ele2_demo_0002.jpg',
            authenticated: true,
          ),
          'https://attachments.f95zone.to/2017/08/27639_ele2_demo_0002.jpg',
        );
      },
    );

    test('strips the /thumb/ segment from attachment URLs', () {
      expect(
        fullSizeImageUrl(
          'https://attachments.f95zone.to/2024/10/thumb/4123459_01.jpg?h=abc&e=1792990800&u=4355484',
          authenticated: true,
        ),
        'https://attachments.f95zone.to/2024/10/4123459_01.jpg?h=abc&e=1792990800&u=4355484',
      );
    });

    test('leaves a full-size attachment URL untouched', () {
      const url = 'https://attachments.f95zone.to/2024/10/4123459_01.jpg';
      expect(fullSizeImageUrl(url, authenticated: true), url);
    });

    test('leaves non-f95zone hosts untouched', () {
      const url = 'https://picsum.photos/seed/f95hub/640/360';
      expect(fullSizeImageUrl(url, authenticated: true), url);
    });

    test('keeps the preview tier when not authenticated', () {
      const url = 'https://preview.f95zone.to/2017/08/27639_x.jpg';
      expect(fullSizeImageUrl(url, authenticated: false), url);
    });
  });

  testWidgets('the strip keeps preview URLs; expanding loads full-size', (
    tester,
  ) async {
    imageCacheCookie = 'xf_user=abc';
    addTearDown(() => imageCacheCookie = null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenshotGallery(
            cover: 'https://preview.f95zone.to/2024/10/cover.png',
            screens: const [
              'https://attachments.f95zone.to/2024/10/thumb/4123459_01.jpg?h=abc&e=1&u=1',
            ],
            cacheManager: FakeCacheManager(),
          ),
        ),
      ),
    );

    // The carousel strip renders the URLs it was given, untouched.
    final stripUrls = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl)
        .toSet();
    expect(stripUrls, const <String>{
      'https://preview.f95zone.to/2024/10/cover.png',
      'https://attachments.f95zone.to/2024/10/thumb/4123459_01.jpg?h=abc&e=1&u=1',
    });

    // The expand-view list carries the full-size rewrites. (CarouselView's
    // tap handling does not fire in widget tests, so the getter is asserted
    // directly.)
    expect(
      tester
          .widget<ScreenshotGallery>(find.byType(ScreenshotGallery))
          .fullImages,
      const <String>[
        'https://attachments.f95zone.to/2024/10/cover.png',
        'https://attachments.f95zone.to/2024/10/4123459_01.jpg?h=abc&e=1&u=1',
      ],
    );
  });
}
