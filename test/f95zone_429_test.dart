import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/f95zone_metadata_source.dart';
import 'package:f95hub/domain/ports.dart';

const _listBody =
    '{"status":"ok","msg":{"data":[],"pagination":{"page":1,"total":1},'
    '"count":0}}';

const _tagHtml =
    '<script>var latestUpdates = {"prefixes":{},"tags":{"45":"rpg"},'
    '"options":false};</script>';

/// A fake dio adapter returning the configured status codes in order, so a
/// test can script a 429 followed by a success.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCodes, this.body);

  final List<int> statusCodes;
  final String body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = calls < statusCodes.length ? calls : statusCodes.length - 1;
    calls++;
    final status = statusCodes[index];
    return ResponseBody.fromString(
      status == 200 ? body : '',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

F95zoneMetadataSource _source(
  _FakeAdapter adapter, {
  int maxRetries = 3,
  int retriesPerThrottle = 5,
  int maxAttempts = 200,
  List<Duration>? delays,
}) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return F95zoneMetadataSource(
    dio: dio,
    // These tests exercise the backoff math, not the request pacing.
    requestInterval: Duration.zero,
    maxRetries: maxRetries,
    retriesPerThrottle: retriesPerThrottle,
    maxAttempts: maxAttempts,
    backoffDelay: (d) async {
      delays?.add(d);
    },
  );
}

void main() {
  test('listGames retries a 429 with backoff, then succeeds', () async {
    final adapter = _FakeAdapter([429, 200], _listBody);
    final delays = <Duration>[];
    final source = _source(adapter, delays: delays);

    final page = await source.listGames(GameCategory.games);

    expect(adapter.calls, 2);
    expect(page.items, isEmpty);
    expect(delays, [const Duration(seconds: 90)]);
  });

  test('listGames caches a successful response', () async {
    final adapter = _FakeAdapter([200], _listBody);
    final source = _source(adapter);

    await source.listGames(GameCategory.games);
    await source.listGames(GameCategory.games);

    expect(adapter.calls, 1);
  });

  test('listGames cache is keyed by the full query (page/sort)', () async {
    final adapter = _FakeAdapter([200, 200], _listBody);
    final source = _source(adapter);

    await source.listGames(GameCategory.games, page: 1);
    await source.listGames(GameCategory.games, page: 2);

    expect(adapter.calls, 2);
  });

  test('getTagTable caches its parsed table', () async {
    final adapter = _FakeAdapter([200], _tagHtml);
    final source = _source(adapter);

    final table = await source.getTagTable();
    await source.getTagTable();

    expect(table.tagName(45), 'rpg');
    expect(adapter.calls, 1);
  });

  test('listGames pauses 90s before each retry and gives up at the hard cap',
      () async {
    final adapter = _FakeAdapter([429, 429, 429, 429], _listBody);
    final delays = <Duration>[];
    final source =
        _source(adapter, maxAttempts: 3, delays: delays);

    await expectLater(
      source.listGames(GameCategory.games),
      throwsA(isA<RateLimitedException>()),
    );
    // Three requests total: the third 429 hits the cap and rethrows.
    expect(adapter.calls, 3);
    expect(delays, [
      const Duration(seconds: 90),
      const Duration(seconds: 90),
    ]);
  });

  test('every 429 grows the retry budget by retriesPerThrottle', () async {
    // Without the +5 refill the initial budget of 2 ends the fetch after three
    // requests. With it, only the hard cap stops the loop.
    final noRefill = _FakeAdapter([429, 429, 429, 429], _listBody);
    await expectLater(
      _source(noRefill, maxRetries: 2, retriesPerThrottle: 0)
          .listGames(GameCategory.games),
      throwsA(isA<RateLimitedException>()),
    );
    expect(noRefill.calls, 3);

    final refilled = _FakeAdapter([429, 429, 429, 429], _listBody);
    await expectLater(
      _source(
        refilled,
        maxRetries: 2,
        retriesPerThrottle: 5,
        maxAttempts: 4,
      ).listGames(GameCategory.games),
      throwsA(isA<RateLimitedException>()),
    );
    expect(refilled.calls, 4);
  });

  test('getThread retries a 429 with backoff', () async {
    final adapter = _FakeAdapter([429, 200], '');
    final delays = <Duration>[];
    final source = _source(adapter, delays: delays);

    final thread = await source.getThread(1);

    expect(adapter.calls, 2);
    expect(thread.threadId, 1);
    expect(delays, [const Duration(seconds: 90)]);
  });

  test('getTagTable retries a 429 with backoff', () async {
    final adapter = _FakeAdapter([429, 200], _tagHtml);
    final delays = <Duration>[];
    final source = _source(adapter, delays: delays);

    final table = await source.getTagTable();

    expect(adapter.calls, 2);
    expect(table.tagName(45), 'rpg');
    expect(delays, [const Duration(seconds: 90)]);
  });

  test('throttled emits true during backoff and false after', () async {
    final adapter = _FakeAdapter([429, 200], _listBody);
    final events = <bool>[];
    final source = _source(adapter, delays: <Duration>[]);
    source.throttled.listen(events.add);

    await source.listGames(GameCategory.games);

    expect(events, [true, false]);
  });
}
