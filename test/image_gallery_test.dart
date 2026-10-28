import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/theme/app_scroll_behavior.dart';
import 'package:f95hub/widgets/image_gallery.dart';

import 'support/fake_cache_manager.dart';

const _screenA = 'https://preview.f95zone.to/2026/10/a.png';
const _screenB = 'https://preview.f95zone.to/2026/10/b.png';

void main() {
  testWidgets('FullScreenGallery shows a zoomable image with controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenGallery(
          images: const [_screenA, _screenB],
          cacheManager: FakeCacheManager(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // The close button lives in the bottom bar.
    expect(find.byKey(const Key('gallery-bar-close')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
    // The fake manager fails the load; the error placeholder is shown.
    // Every image (page + bottom-bar thumbnails) shows the broken
    // placeholder with the failing fake manager.
    expect(find.byIcon(Icons.broken_image), findsNWidgets(3));
    expect(find.byKey(const Key('gallery-thumb-0')), findsOneWidget);
    expect(find.byKey(const Key('gallery-thumb-1')), findsOneWidget);

    await expectLater(
      find.byType(FullScreenGallery),
      matchesGoldenFile('goldens/image_gallery.png'),
    );
  });

  testWidgets('FullScreenGallery pages between images', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenGallery(
          images: const [_screenA, _screenB],
          cacheManager: FakeCacheManager(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(
      tester.widget<AvifCapableImage>(find.byType(AvifCapableImage).last).url,
      _screenB,
    );

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('FullScreenGallery starts at the tapped image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenGallery(
          images: const [_screenA, _screenB],
          initialIndex: 1,
          cacheManager: FakeCacheManager(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('close dismisses the gallery route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openImageGallery(
              context,
              images: const [_screenA, _screenB],
              cacheManager: FakeCacheManager(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenGallery), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenGallery), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('openImageGallery opens a translucent modal gallery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openImageGallery(
                  context,
                  images: const [_screenA, _screenB],
                  cacheManager: FakeCacheManager(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final route = ModalRoute.of(
      tester.element(find.byType(FullScreenGallery)),
    );
    expect(route, isNotNull);
    expect(route!.opaque, isFalse);
    expect(route.barrierColor, Colors.black54);
    expect(route.barrierDismissible, isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ModalBarrier && widget.color == Colors.black54,
      ),
      findsOneWidget,
    );
    // The gallery's own scaffold is transparent so the page shows through.
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(FullScreenGallery),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, Colors.transparent);
  });

  testWidgets('the gallery pages with a mouse drag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: FullScreenGallery(
          images: const [_screenA, _screenB],
          cacheManager: FakeCacheManager(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(
      find.byType(PageView),
      const Offset(-600, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('the gallery still pinches to zoom', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenGallery(
          images: const [_screenA, _screenB],
          cacheManager: FakeCacheManager(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), 1);

    final center = tester.getCenter(find.byType(PageView));
    final first = await tester.createGesture();
    final second = await tester.createGesture();
    await first.down(center - const Offset(40, 0));
    await second.down(center + const Offset(40, 0));
    await tester.pump();
    await first.moveBy(const Offset(-60, 0));
    await second.moveBy(const Offset(60, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    // Zooming must not have paged the gallery.
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('GalleryImage falls back for an empty url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GalleryImage(url: '')),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
