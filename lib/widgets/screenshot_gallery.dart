import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../domain/image_urls.dart';
import '../state/image_cache.dart';
import 'image_gallery.dart';

/// A horizontally swipeable carousel of the game's cover and screenshots.
///
/// Tapping an item opens the [FullScreenGallery] at that image. Images load
/// through `cached_network_image`, so revisiting a game reuses the disk-cached
/// files. Tests inject a fake [cacheManager] to keep the gallery offline and
/// deterministic.
///
/// The strip shows the lightweight URLs it was given (the API's preview tier:
/// instant, already cached); tapping an item opens the [FullScreenGallery]
/// with the same images rewritten to their full-size originals via
/// [fullSizeImageUrl] (preview → attachments host, any `/thumb/` segment
/// stripped) while logged in — big originals are downloaded only when the
/// user actually expands one.
class ScreenshotGallery extends StatelessWidget {
  const ScreenshotGallery({
    super.key,
    this.cover,
    required this.screens,
    this.cacheManager,
  });

  /// The game cover; shown first when present.
  final String? cover;

  final List<String> screens;

  /// Cache manager to load through; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  static const _itemExtent = 220.0;
  static const _height = 140.0;

  List<String> get _images => [
    if (cover != null && cover!.isNotEmpty) cover!,
    ...screens,
  ];

  /// The expand-view variant of [_images]: full-size originals when a session
  /// is active, otherwise the same preview URLs.
  @visibleForTesting
  List<String> get fullImages => _images
      .map(
        (url) => fullSizeImageUrl(url, authenticated: imageCacheCookie != null),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _height,
      child: CarouselView(
        itemExtent: _itemExtent,
        itemSnapping: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        onTap: (index) => openImageGallery(
          context,
          images: fullImages,
          initialIndex: index,
          cacheManager: cacheManager,
        ),
        children: [
          for (final url in images)
            GalleryImage(url: url, cacheManager: cacheManager),
        ],
      ),
    );
  }
}
