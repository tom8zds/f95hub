import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:f95hub/adapters/authed_image_cache_manager.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/image_cache.dart';
import 'package:f95hub/state/session.dart';

import 'support/fake_metadata_source.dart';
import 'support/fake_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The real manager eagerly opens its cache under path_provider's
  // directories; point the channel at a temp dir so the constructor's file
  // IO succeeds instead of throwing MissingPluginException.
  final tempRoot = Directory.systemTemp.createTempSync('f95hub-image-cache');
  tearDownAll(() => tempRoot.deleteSync(recursive: true));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          switch (call.method) {
            case 'getTemporaryDirectory':
            case 'getApplicationSupportDirectory':
              return tempRoot.path;
            default:
              return null;
          }
        },
      );

  tearDown(() {
    imageCacheCookie = null;
  });

  test('AuthedHttpClient stamps cookie, User-Agent and Referer on requests', () async {
    final captured = <http.BaseRequest>[];
    final inner = MockClient((request) {
      captured.add(request);
      return Future.value(http.Response('ok', 200));
    });
    final client = AuthedHttpClient(
      cookie: () => 'xf_user=abc; cf_clearance=xyz',
      inner: inner,
    );

    await client.read(Uri.parse('https://img.example/c.png'));

    expect(captured, hasLength(1));
    expect(captured.single.headers['Cookie'], 'xf_user=abc; cf_clearance=xyz');
    expect(captured.single.headers['User-Agent'], f95zoneUserAgent);
    expect(captured.single.headers['Referer'], f95zoneReferer);
  });

  test('AuthedHttpClient follows cookie changes and omits it when logged out', () async {
    var cookie = 'xf_user=first';
    final captured = <http.BaseRequest>[];
    final inner = MockClient((request) {
      captured.add(request);
      return Future.value(http.Response('ok', 200));
    });
    final client = AuthedHttpClient(cookie: () => cookie, inner: inner);

    await client.read(Uri.parse('https://img.example/a.png'));
    cookie = 'xf_user=second';
    await client.read(Uri.parse('https://img.example/b.png'));
    cookie = '';
    await client.read(Uri.parse('https://img.example/c.png'));

    expect(captured[0].headers['Cookie'], 'xf_user=first');
    expect(captured[1].headers['Cookie'], 'xf_user=second');
    expect(captured[2].headers.containsKey('Cookie'), isFalse);
  });

  test('installAuthedImageCache makes the authed manager the package default', () {
    installAuthedImageCache();

    expect(
      CachedNetworkImageProvider.defaultCacheManager,
      isA<AuthedImageCacheManager>(),
    );
  });

  test('logging in updates the image cache cookie', () async {
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(FakeSessionStore()),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).restored;
    await container.read(sessionProvider.notifier).login('xf_user=abc');
    expect(container.read(sessionProvider), 'xf_user=abc');
    expect(imageCacheCookie, 'xf_user=abc');

    await container.read(sessionProvider.notifier).logout();
    expect(imageCacheCookie, isNull);
  });
}
