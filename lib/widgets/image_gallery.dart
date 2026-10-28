import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import '../state/image_cache.dart';

/// Sniffs the AVIF brand from a file's leading `ftyp` box.
bool isAvifBytes(Uint8List bytes) {
  if (bytes.length < 12) {
    return false;
  }
  if (String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
    return false;
  }
  final brand = String.fromCharCodes(bytes.sublist(8, 12));
  return brand == 'avif' || brand == 'avis' || brand == 'mif1';
}

/// Decodes [bytes] via `flutter_avif` and returns the first frame.
Future<ui.Image> _decodeAvifFirstFrame(Uint8List bytes) async {
  final frames = await decodeAvif(bytes);
  return frames.first.image;
}

/// A gallery image that survives the attachments CDN's AVIF re-encoding.
///
/// The f95zone attachments host re-encodes every static image as AVIF, which
/// the engine's default decoder cannot decompress on Windows — so this widget
/// fetches the bytes through the authed cache manager (shared disk cache with
/// [CachedNetworkImage]) and, when they smell like AVIF, decodes them with
/// libavif via `flutter_avif` instead of the engine. Everything else renders
/// through the normal [Image.memory] path.
///
/// [decoder] is the AVIF decode seam; tests inject a fake because the native
/// library is not resolvable in the widget-test runner.
class AvifCapableImage extends StatefulWidget {
  const AvifCapableImage({
    super.key,
    required this.url,
    this.cacheManager,
    this.fit = BoxFit.contain,
    this.decoder,
  });

  final String url;

  /// Cache manager to load through; null uses the app's authed manager.
  final BaseCacheManager? cacheManager;

  final BoxFit fit;

  /// AVIF decoder override (tests).
  final Future<ui.Image> Function(Uint8List bytes)? decoder;

  @override
  State<AvifCapableImage> createState() => _AvifCapableImageState();
}

class _AvifCapableImageState extends State<AvifCapableImage> {
  /// The frame we decoded ourselves; disposed on unmount.
  ui.Image? _owned;

  /// Download progress (`null` = unknown/indeterminate) while loading.
  double? _progress;

  /// Started once; a FutureBuilder rebuilding would otherwise restart the
  /// load on every parent rebuild.
  late final Future<Object> _future = _load();

  Future<Object> _load() async {
    final manager = widget.cacheManager ?? appImageCacheManager;
    await for (final response in manager!.getFileStream(
      widget.url,
      withProgress: true,
    )) {
      if (response is DownloadProgress) {
        if (mounted) {
          setState(() => _progress = response.progress);
        }
        continue;
      }
      final file = (response as FileInfo).file;
      final bytes = Uint8List.fromList(await file.readAsBytes());
      if (isAvifBytes(bytes)) {
        final image = await (widget.decoder ?? _decodeAvifFirstFrame)(bytes);
        _owned = image;
        return image;
      }
      return bytes;
    }
    throw StateError('no file response for ${widget.url}');
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return const _GalleryPlaceholder(icon: Icons.image_outlined);
    }
    return FutureBuilder<Object>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Full-size originals take seconds to download: show an active
          // loader (with byte progress when the server reports it) instead
          // of a placeholder that looks like nothing is happening.
          return _GalleryLoading(progress: _progress);
        }
        final data = snapshot.data;
        if (data is ui.Image) {
          return RawImage(image: data, fit: widget.fit);
        }
        if (data is Uint8List) {
          return Image.memory(data, fit: widget.fit, gaplessPlayback: true);
        }
        return const _GalleryPlaceholder(icon: Icons.broken_image);
      },
    );
  }
}

/// The full-screen loading state: spinner plus a byte-progress bar when the
/// size is known.
class _GalleryLoading extends StatelessWidget {
  const _GalleryLoading({this.progress});

  /// 0..1 while the total size is known; `null` shows an indeterminate bar.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single image in a gallery (carousel thumbnail or full-screen page).
///
/// Loads through `cached_network_image` so thumbnails and the full-screen view
/// share the same disk cache. Missing URLs and load failures fall back to an
/// icon placeholder. Tests inject a fake [cacheManager] to stay offline.
///
/// The full-screen pages use [AvifCapableImage] instead (the attachments CDN
/// serves AVIF the engine cannot decode); this widget remains for the
/// carousel strip, whose preview-tier URLs are always engine-decodable.
class GalleryImage extends StatelessWidget {
  const GalleryImage({
    super.key,
    required this.url,
    this.cacheManager,
    this.fit = BoxFit.cover,
  });

  final String url;

  /// Cache manager to load through; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const _GalleryPlaceholder(icon: Icons.image_outlined);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      cacheManager: cacheManager,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const _GalleryLoading(),
      errorWidget: (_, _, _) =>
          const _GalleryPlaceholder(icon: Icons.broken_image),
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(child: Icon(icon, size: 48, color: Colors.white70)),
    );
  }
}

/// Opens [images] full screen, starting at [initialIndex].
///
/// No-op when [images] is empty. The gallery is shown as a translucent modal
/// dialog: the page behind stays visible through the `Colors.black54` barrier
/// and the gallery's own transparent background. It can be dismissed with the
/// close button, the back action, or a tap on the barrier.
Future<void> openImageGallery(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
  BaseCacheManager? cacheManager,
}) {
  if (images.isEmpty) {
    return Future<void>.value();
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => FullScreenGallery(
      images: images,
      initialIndex: initialIndex,
      cacheManager: cacheManager,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// A dark, full-screen image viewer with pinch-zoom and page navigation.
///
/// The scaffold itself is transparent so the dimmed page behind the modal
/// dialog shows through.
class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.cacheManager,
  });

  final List<String> images;
  final int initialIndex;

  /// Cache manager to load through; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final lastIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
    _index = widget.initialIndex.clamp(0, lastIndex);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.images.length) {
      return;
    }
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                // Swiping is handled by [_GalleryPage] so the per-page
                // InteractiveViewer cannot swallow the drag; see its doc.
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _GalleryPage(
                  url: widget.images[index],
                  controller: _controller,
                  pageCount: widget.images.length,
                  cacheManager: widget.cacheManager,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _GalleryBottomBar(
                images: widget.images,
                index: _index,
                onTapThumb: (index) => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                ),
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (_index > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.white,
                  tooltip: context.t.gallery.previous,
                  onPressed: () => _step(-1),
                ),
              ),
            if (_index < widget.images.length - 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.white,
                  tooltip: context.t.gallery.next,
                  onPressed: () => _step(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One page of the gallery: pinch-zoomable, and pannable only once zoomed in.
///
/// A plain [PageView] cannot swipe here: the [InteractiveViewer]'s scale
/// recognizer always wins the gesture arena, even when panning is disabled, so
/// the page view would never receive a drag. The page therefore observes raw
/// pointers and drives its [PageController] while the image is at rest, and
/// leaves gestures to the [InteractiveViewer] once zoomed in.
class _GalleryPage extends StatefulWidget {
  const _GalleryPage({
    required this.url,
    required this.controller,
    required this.pageCount,
    this.cacheManager,
  });

  final String url;
  final PageController controller;
  final int pageCount;
  final BaseCacheManager? cacheManager;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  static const _flingVelocity = 300.0;

  final _transform = TransformationController();
  bool _zoomed = false;

  int? _activePointer;
  Offset _downPosition = Offset.zero;
  Offset _lastPosition = Offset.zero;
  Duration _lastMoveTime = Duration.zero;
  double _startPixels = 0;
  double _velocity = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _transform.removeListener(_handleTransform);
    _transform.dispose();
    super.dispose();
  }

  void _handleTransform() {
    // A hair above 1 absorbs floating-point noise from the gesture.
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_zoomed) {
      return;
    }
    if (_activePointer != null) {
      // A second pointer means a pinch-to-zoom is starting; hand the gesture
      // to the InteractiveViewer instead of paging.
      _activePointer = null;
      _dragging = false;
      return;
    }
    _activePointer = event.pointer;
    _downPosition = event.position;
    _lastPosition = event.position;
    _lastMoveTime = event.timeStamp;
    _startPixels = widget.controller.position.pixels;
    _velocity = 0;
    _dragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    final offset = event.position - _downPosition;
    if (!_dragging) {
      if (offset.dx.abs() <= kTouchSlop || offset.dx.abs() < offset.dy.abs()) {
        return;
      }
      _dragging = true;
    }
    final position = widget.controller.position;
    position.jumpTo(
      (_startPixels - offset.dx)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
    );
    final elapsed = event.timeStamp - _lastMoveTime;
    if (elapsed > Duration.zero) {
      _velocity =
          (event.position.dx - _lastPosition.dx) /
          (elapsed.inMicroseconds / Duration.microsecondsPerSecond);
    }
    _lastPosition = event.position;
    _lastMoveTime = event.timeStamp;
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _activePointer = null;
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final position = widget.controller.position;
    final page = position.pixels / position.viewportDimension;
    var target = page.round();
    if (_velocity < -_flingVelocity) {
      target = page.floor() + 1;
    } else if (_velocity > _flingVelocity) {
      target = page.ceil() - 1;
    }
    widget.controller.animateToPage(
      target.clamp(0, widget.pageCount - 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        panEnabled: _zoomed,
        child: Center(
          child: AvifCapableImage(
            url: widget.url,
            cacheManager: widget.cacheManager,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// The gallery's bottom bar: a switchable thumbnail strip, the page counter,
/// and the close button.
class _GalleryBottomBar extends StatelessWidget {
  const _GalleryBottomBar({
    required this.images,
    required this.index,
    required this.onTapThumb,
    required this.onClose,
  });

  final List<String> images;

  /// The currently shown page.
  final int index;

  /// Jumps the gallery to the tapped thumbnail.
  final ValueChanged<int> onTapThumb;

  final VoidCallback onClose;

  static const _thumbWidth = 88.0;
  static const _thumbHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black87,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1} / ${images.length}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    key: const Key('gallery-bar-close'),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: _thumbHeight + 8,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = i == index;
                    return InkWell(
                      key: Key('gallery-thumb-$i'),
                      onTap: () => onTapThumb(i),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: Container(
                        width: _thumbWidth,
                        height: _thumbHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: active ? scheme.primary : Colors.white24,
                            width: active ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AvifCapableImage(
                          url: images[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
