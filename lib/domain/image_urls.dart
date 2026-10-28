import 'dart:core';

/// Rewrites an f95zone image URL to its full-size variant for detail views.
///
/// The site serves three tiers:
/// * `preview.f95zone.to/<y>/<m>/<file>` — a downscaled, re-encoded preview
///   (what the list API returns; fine for cards, blurry in a detail gallery);
/// * `attachments.f95zone.to/<y>/<m>/thumb/<file>` — a tiny thumbnail used by
///   forum pages;
/// * `attachments.f95zone.to/<y>/<m>/<file>` — the original full image.
///
/// When [authenticated] is true (a session cookie is active), the attachments
/// host serves images on the cookie alone — no `h` signature needed — so the
/// rewrite is a plain host swap / `/thumb/` strip. Without a session the
/// rewrite is skipped: the unsigned full-size URL would 403, and the preview
/// tier is the best an anonymous session can reliably get.
///
/// Unknown hosts are returned unchanged.
String fullSizeImageUrl(String url, {required bool authenticated}) {
  if (!authenticated) {
    return url;
  }
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return url;
  }
  final segments = uri.pathSegments;
  final hasThumb = segments.contains('thumb');
  if (uri.host == 'attachments.f95zone.to') {
    if (!hasThumb) {
      return url;
    }
    return uri
        .replace(
          pathSegments: segments.where((s) => s != 'thumb').toList(),
        )
        .toString();
  }
  if (uri.host == 'preview.f95zone.to') {
    return uri
        .replace(host: 'attachments.f95zone.to', pathSegments: segments)
        .toString();
  }
  return url;
}
