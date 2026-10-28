import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/f95zone_metadata_source.dart';
import 'package:f95hub/domain/ports.dart';

const _cookie = 'xf_user=abc; cf_clearance=def';

const _listBody = '{"status":"ok","msg":{"data":[],'
    '"pagination":{"page":1,"total":1},"count":0}}';

const _threadHtml =
    '<html><head><title>Some Thread | F95zone</title></head><body>'
    '<div class="bbWrapper">Overview: fine thread</div></body></html>';

const _tagHtml =
    '<script>var latestUpdates = {"prefixes":{},"tags":{"45":"rpg"},'
    '"options":false};</script>';

/// Fake dio adapter that records every [RequestOptions] and answers with a
/// canned 200 body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final String body;
  final List<RequestOptions> requests = [];

  int get calls => requests.length;

  /// The `Cookie` header sent with the request at [index], or null.
  String? cookieAt(int index) => requests[index].headers['Cookie'] as String?;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

F95zoneMetadataSource _source(_RecordingAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return F95zoneMetadataSource(
    dio: dio,
    // Cookie plumbing, not pacing, is under test.
    requestInterval: Duration.zero,
  );
}

void main() {
  group('listGames', () {
    test('sends the session cookie when logged in', () async {
      final adapter = _RecordingAdapter(_listBody);
      final source = _source(adapter);
      await source.login(const LoginCredentials(cookie: _cookie));

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 1);
      expect(adapter.cookieAt(0), _cookie);
    });

    test('sends no Cookie header when logged out', () async {
      final adapter = _RecordingAdapter(_listBody);
      final source = _source(adapter);

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 1);
      expect(adapter.cookieAt(0), isNull);
      expect(adapter.requests.single.headers.containsKey('Cookie'), isFalse);
    });
  });

  group('getThread', () {
    test('sends the session cookie when logged in', () async {
      final adapter = _RecordingAdapter(_threadHtml);
      final source = _source(adapter);
      await source.login(const LoginCredentials(cookie: _cookie));

      await source.getThread(42);

      expect(adapter.calls, 1);
      expect(adapter.cookieAt(0), _cookie);
    });

    test('sends no Cookie header when logged out', () async {
      final adapter = _RecordingAdapter(_threadHtml);
      final source = _source(adapter);

      await source.getThread(42);

      expect(adapter.requests.single.headers.containsKey('Cookie'), isFalse);
    });
  });

  group('getTagTable', () {
    test('sends the session cookie when logged in', () async {
      final adapter = _RecordingAdapter(_tagHtml);
      final source = _source(adapter);
      await source.login(const LoginCredentials(cookie: _cookie));

      await source.getTagTable();

      expect(adapter.calls, 1);
      expect(adapter.cookieAt(0), _cookie);
    });

    test('sends no Cookie header when logged out', () async {
      final adapter = _RecordingAdapter(_tagHtml);
      final source = _source(adapter);

      await source.getTagTable();

      expect(adapter.requests.single.headers.containsKey('Cookie'), isFalse);
    });
  });

  group('login', () {
    test('clears the cached list so the next request refetches', () async {
      final adapter = _RecordingAdapter(_listBody);
      final source = _source(adapter);

      await source.listGames(GameCategory.games);
      expect(adapter.calls, 1);

      await source.login(const LoginCredentials(cookie: _cookie));

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 2);
      expect(adapter.cookieAt(0), isNull);
      expect(adapter.cookieAt(1), _cookie);
    });

    test('clears the cached tag table so the next request refetches', () async {
      final adapter = _RecordingAdapter(_tagHtml);
      final source = _source(adapter);

      await source.getTagTable();
      expect(adapter.calls, 1);

      await source.login(const LoginCredentials(cookie: _cookie));

      await source.getTagTable();

      expect(adapter.calls, 2);
      expect(adapter.cookieAt(1), _cookie);
    });

    test('drops the cache when logging in again with another cookie', () async {
      final adapter = _RecordingAdapter(_listBody);
      final source = _source(adapter);

      await source.login(const LoginCredentials(cookie: _cookie));
      await source.listGames(GameCategory.games);
      await source.login(const LoginCredentials(cookie: 'xf_user=other'));

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 2);
      expect(adapter.cookieAt(1), 'xf_user=other');
    });
  });
}
