import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A cover image (or a placeholder when absent/unloadable).
///
/// Shared by the listing [GameCard] and the detail page so both render the
/// same placeholder treatment. Covers are cached on disk by
/// `cached_network_image`, so switching pages/dialogs reuses the downloaded
/// file instead of refetching it. Tests inject a fake [cacheManager] to keep
/// the widget offline and deterministic.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    this.url,
    this.icon = Icons.videogame_asset,
    this.cacheManager,
  });

  final String? url;
  final IconData icon;

  /// Cache manager to load through; null uses
  /// `CachedNetworkImageProvider.defaultCacheManager` (the shared disk cache).
  final BaseCacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    final cover = url;
    if (cover == null || cover.isEmpty) {
      return _CoverPlaceholder(icon: icon);
    }
    return CachedNetworkImage(
      imageUrl: cover,
      fit: BoxFit.cover,
      cacheManager: cacheManager,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => _CoverPlaceholder(icon: icon, loading: true),
      errorWidget: (_, _, _) => _CoverPlaceholder(icon: Icons.broken_image),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.icon, this.loading = false});

  final IconData icon;

  /// When true a small spinner replaces the icon — the "still fetching"
  /// affordance, so an empty tile reads as loading rather than broken.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  scheme.onSurfaceVariant,
                ),
              ),
            )
          : Icon(icon, size: 40, color: scheme.onSurfaceVariant),
    );
  }
}
