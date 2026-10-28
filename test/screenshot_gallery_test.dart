import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/theme/app_scroll_behavior.dart';
import 'package:f95hub/widgets/image_gallery.dart';
import 'package:f95hub/widgets/screenshot_gallery.dart';

import 'support/fake_cache_manager.dart';

const _cover = 'https://preview.f95zone.to/2026/10/cover.png';
const _screenA = 'https://preview.f95zone.to/2026/10/a.png';
const _screenB = 'https://preview.f95zone.to/2026/10/b.png';

Future<void> _pumpGallery(
  WidgetTester tester, {
  String? cover = _cover,
  List<String> screens = const [_screenA, _screenB],
  FakeCacheManager? cacheManager,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 200,
          child: ScreenshotGallery(
            cover: cover,
            screens: screens,
            cacheManager: cacheManager,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ScreenshotGallery carousels the cover and every screenshot', (
    tester,
  ) async {
    final cache = FakeCacheManager();
    await _pumpGallery(tester, cacheManager: cache);
    // The fake manager fails every load; the error placeholders settle.
    await tester.pumpAndSettle();

    final carousel = tester.widget<CarouselView>(find.byType(CarouselView));
    expect(carousel.children.map((child) => (child as GalleryImage).url), [
      _cover,
      _screenA,
      _screenB,
    ]);
    final images = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .toList();
    expect(images, isNotEmpty);
    expect(images.every((image) => image.cacheManager == cache), isTrue);
    expect(find.byIcon(Icons.broken_image), findsWidgets);

    await expectLater(
      find.byType(ScreenshotGallery),
      matchesGoldenFile('goldens/screenshot_gallery.png'),
    );
  });

  testWidgets('tapping a carousel item opens the full-screen gallery', (
    tester,
  ) async {
    final cache = FakeCacheManager();
    await _pumpGallery(tester, cacheManager: cache);
    await tester.pumpAndSettle();

    // The carousel's ink overlay receives the tap, not the image itself.
    await tester.tap(find.byType(GalleryImage).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    final gallery = tester.widget<FullScreenGallery>(
      find.byType(FullScreenGallery),
    );
    expect(gallery.images, [_cover, _screenA, _screenB]);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('ScreenshotGallery renders nothing when empty', (tester) async {
    await _pumpGallery(tester, cover: null, screens: const []);
    await tester.pumpAndSettle();

    expect(find.byType(CarouselView), findsNothing);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('ScreenshotGallery hides the cover when it is missing', (
    tester,
  ) async {
    await _pumpGallery(tester, cover: null, cacheManager: FakeCacheManager());
    await tester.pumpAndSettle();

    final carousel = tester.widget<CarouselView>(find.byType(CarouselView));
    expect(carousel.children.map((child) => (child as GalleryImage).url), [
      _screenA,
      _screenB,
    ]);
  });

  testWidgets('AppScrollBehavior allows every pointer kind to drag', (
    tester,
  ) async {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    expect(behavior.dragDevices, contains(PointerDeviceKind.stylus));
    expect(behavior.dragDevices, contains(PointerDeviceKind.invertedStylus));
  });

  testWidgets('the carousel can be dragged with the mouse', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: ScreenshotGallery(
              cover: _cover,
              screens: const [_screenA, _screenB],
              cacheManager: FakeCacheManager(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, 0);

    await tester.drag(
      find.byType(CarouselView),
      const Offset(-300, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
    expect(position.pixels, closeTo(220, 1));
  });
}
