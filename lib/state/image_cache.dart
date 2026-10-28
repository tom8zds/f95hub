import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../adapters/authed_image_cache_manager.dart';

/// The session cookie used for image downloads. Kept in sync with
/// [SessionController] state by a `listenSelf` in its `build`; read lazily by
/// the authed cache manager so login/logout apply to the next request without
/// recreating anything.
String? imageCacheCookie;

/// The app's authed image cache manager, installed by
/// [installAuthedImageCache]. Widgets that fetch image bytes themselves (e.g.
/// the AVIF-capable full-screen viewer) use it so the cookie applies and the
/// disk cache is shared with [CachedNetworkImage].
BaseCacheManager? appImageCacheManager;

/// Installs [AuthedImageCacheManager] as the package-wide default cache
/// manager, so every [CachedNetworkImage] / [CachedNetworkImageProvider]
/// without an explicit manager sends the f95zone session cookie (and matching
/// User-Agent/Referer) — the default manager's bare GETs are what made
/// covers/screenshots fail behind Cloudflare.
///
/// Called once from `main()` before the app starts.
void installAuthedImageCache() {
  final manager = AuthedImageCacheManager(cookie: () => imageCacheCookie);
  appImageCacheManager = manager;
  CachedNetworkImageProvider.defaultCacheManager = manager;
}
