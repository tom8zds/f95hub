import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// User-Agent sent on every f95zone request (metadata, thread pages, and
/// image downloads). Cloudflare ties `cf_clearance` to the requesting UA, so
/// the image path MUST send the same one the metadata adapter sends.
const String f95zoneUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) f95hub/1.0';

/// Referer sent on every f95zone request (hotlink protection on the image
/// hosts checks it).
const String f95zoneReferer = 'https://f95zone.to/';

/// A [CacheManager] whose downloads carry the f95zone session cookie plus the
/// matching [f95zoneUserAgent] and [f95zoneReferer].
///
/// Cover and screenshot hosts (`preview.f95zone.to`, …) sit behind the same
/// Cloudflare gate as the metadata endpoints: a plain GET without the
/// `Cookie` header is rejected, which is why images failed to load while the
/// rest of the app worked. [cookie] is read lazily per request so login /
/// logout take effect immediately without rebuilding the manager.
class AuthedImageCacheManager extends CacheManager {
  AuthedImageCacheManager({required String? Function() cookie})
    : super(
        Config(
          _kCacheKey,
          fileService: HttpFileService(
            httpClient: AuthedHttpClient(cookie: cookie),
          ),
        ),
      );

  static const String _kCacheKey = 'f95hubAuthedImages';
}

/// An [http.Client] that stamps f95zone auth headers onto every outgoing
/// request before delegating to [inner].
class AuthedHttpClient extends http.BaseClient {
  AuthedHttpClient({required this.cookie, http.Client? inner})
    : _inner = inner ?? http.Client();

  /// Current session cookie (`xf_user=…; cf_clearance=…`), or null when
  /// logged out (no `Cookie` header is sent then).
  final String? Function() cookie;

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final value = cookie();
    if (value != null && value.isNotEmpty) {
      request.headers['Cookie'] = value;
    }
    request.headers['User-Agent'] = f95zoneUserAgent;
    request.headers['Referer'] = f95zoneReferer;
    return _inner.send(request);
  }
}
