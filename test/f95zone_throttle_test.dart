import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/f95zone_metadata_source.dart';
import 'package:f95hub/adapters/game_index_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';

const _listBody =
    '{"status":"ok","msg":{"data":[],"pagination":{"page":1,"total":1},'
    '"count":0}}';

/// Fake time: a mutable clock plus a delay function that advances it, so the
/// pacing logic can be asserted without ever really sleeping.
class _FakeTime {
  _FakeTime(this.now);

  DateTime now;
  final List<Duration> waits = [];

  DateTime clock() => now;

  Future<void> delay(Duration duration) async {
    waits.add(duration);
    now = now.add(duration);
  }
}

/// Records the fake-clock instant of every request, and scripts the response
/// status/headers per call.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(
    this._time, {
    this.statusCodes = const [200],
    this.body = _listBody,
    this.pageTotal = 1,
    this.retryAfter,
  });

  final _FakeTime _time;
  final List<int> statusCodes;
  final String body;
  final int pageTotal;
  final String? Function(int call)? retryAfter;

  final List<DateTime> requestTimes = [];
  final List<Uri> requestUris = [];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestTimes.add(_time.now);
    requestUris.add(options.uri);
    final index = calls < statusCodes.length ? calls : statusCodes.length - 1;
    final status = statusCodes[index];
    final retryAfterValue = retryAfter?.call(calls);
    calls++;

    if (pageTotal > 1 && status == 200) {
      final page = int.tryParse(options.uri.queryParameters['page'] ?? '1') ?? 1;
      return ResponseBody.fromString(
        _pageBody(page, pageTotal),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      status == 200 ? body : '',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (retryAfterValue != null) 'retry-after': [retryAfterValue],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _pageBody(int page, int total) => jsonEncode({
      'status': 'ok',
      'msg': {
        'data': [
          for (var i = 0; i < 2; i++)
            {
              'thread_id': page * 10 + i,
              'title': 'Game ${page * 10 + i}',
              'creator': 'Creator',
              'version': 'v1.0',
              'ts': 1792808403,
            },
        ],
        'pagination': {'page': page, 'total': total},
        'count': total * 2,
      },
    });

Dio _dioWith(HttpClientAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('request pacing', () {
    test('two requests are separated by at least requestInterval', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time);
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: const Duration(seconds: 2),
        jitter: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games, page: 1);
      await source.listGames(GameCategory.games, page: 2);

      expect(adapter.requestTimes, hasLength(2));
      expect(
        adapter.requestTimes[1].difference(adapter.requestTimes[0]),
        greaterThanOrEqualTo(const Duration(seconds: 2)),
      );
      // The first request is not delayed; only the second waits.
      expect(time.waits, [const Duration(seconds: 2)]);
    });

    test('concurrent requests queue behind the same interval', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time, body: '');
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: const Duration(seconds: 2),
        jitter: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await Future.wait([source.getThread(1), source.getThread(2)]);

      expect(adapter.requestTimes, hasLength(2));
      expect(
        time.waits.fold(Duration.zero, (sum, d) => sum + d),
        const Duration(seconds: 2),
      );
    });

    test('a cached call does not consume an interval slot', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time);
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: const Duration(seconds: 2),
        jitter: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);
      await source.listGames(GameCategory.games);

      expect(adapter.calls, 1);
      expect(time.waits, isEmpty);
    });
  });

  group('jitter', () {
    test('adds a sample within 0..jitter to the interval', () async {
      Future<Duration> waitFor(int sample) async {
        final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
        final adapter = _ScriptedAdapter(time);
        final source = F95zoneMetadataSource(
          dio: _dioWith(adapter),
          requestInterval: const Duration(seconds: 2),
          jitter: const Duration(milliseconds: 800),
          randomInt: (max) {
            expect(max, 800001);
            return sample;
          },
          backoffDelay: time.delay,
          clock: time.clock,
        );

        await source.listGames(GameCategory.games, page: 1);
        await source.listGames(GameCategory.games, page: 2);

        expect(time.waits, hasLength(1));
        return time.waits.single;
      }

      expect(await waitFor(0), const Duration(seconds: 2));
      expect(await waitFor(800000), const Duration(milliseconds: 2800));
    });

    test('a cache hit skips the jittered wait', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time);
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: const Duration(seconds: 2),
        jitter: const Duration(milliseconds: 800),
        randomInt: (_) => 400000,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);
      await source.listGames(GameCategory.games);

      expect(adapter.calls, 1);
      expect(time.waits, isEmpty);
    });
  });

  group('429 backoff', () {
    test('a Retry-After shorter than the pause still waits 90s', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429, 200],
        retryAfter: (_) => '7',
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 2);
      expect(time.waits, [const Duration(seconds: 90)]);
    });

    test('a Retry-After longer than 90s wins', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429, 200],
        retryAfter: (_) =>
            HttpDate.format(time.now.add(const Duration(seconds: 300))),
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);

      expect(adapter.calls, 2);
      expect(time.waits, [const Duration(seconds: 300)]);
    });

    test('a malformed Retry-After falls back to the 90s pause', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429, 200],
        retryAfter: (_) => 'soon-ish',
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);

      expect(time.waits, [const Duration(seconds: 90)]);
    });

    test('every retry waits the fixed 90s pause', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429, 429, 429, 429, 200],
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        maxRetries: 10,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await source.listGames(GameCategory.games);

      expect(time.waits, const [
        Duration(seconds: 90),
        Duration(seconds: 90),
        Duration(seconds: 90),
        Duration(seconds: 90),
      ]);
    });

    test('the hard attempt cap rethrows RateLimitedException', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429],
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        maxAttempts: 3,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await expectLater(
        source.listGames(GameCategory.games),
        throwsA(isA<RateLimitedException>()),
      );
      expect(adapter.calls, 3);
      expect(time.waits, const [
        Duration(seconds: 90),
        Duration(seconds: 90),
      ]);
    });

    test('the initial budget limits retries when no refill is configured',
        () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(
        time,
        statusCodes: const [429, 429, 429],
      );
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        maxRetries: 2,
        retriesPerThrottle: 0,
        backoffDelay: time.delay,
        clock: time.clock,
      );

      await expectLater(
        source.listGames(GameCategory.games),
        throwsA(isA<RateLimitedException>()),
      );
      expect(adapter.calls, 3);
      expect(time.waits, const [
        Duration(seconds: 90),
        Duration(seconds: 90),
      ]);
    });

    test('throttled still signals true/false around each backoff', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time, statusCodes: const [429, 200]);
      final events = <bool>[];
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );
      source.throttled.listen(events.add);

      await source.listGames(GameCategory.games);

      expect(events, [true, false]);
    });
  });

  group('crawl pacing', () {
    test('buildAll paces every page and still reports progress', () async {
      final time = _FakeTime(DateTime.utc(2026, 10, 24, 12));
      final adapter = _ScriptedAdapter(time, pageTotal: 3);
      final source = F95zoneMetadataSource(
        dio: _dioWith(adapter),
        requestInterval: const Duration(seconds: 2),
        jitter: Duration.zero,
        backoffDelay: time.delay,
        clock: time.clock,
      );
      final db = LibraryDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = GameIndexStore(db, source, clock: time.clock);
      final progress = <String>[];
      final counts = <int>[];

      final count = await store.buildAll(
        onProgress: (page, total, count) {
          progress.add('$page/$total');
          counts.add(count);
        },
      );

      expect(count, 6);
      expect(progress, ['1/3', '2/3', '3/3']);
      expect(counts, [2, 4, 6]);
      expect(adapter.requestTimes, hasLength(3));
      expect(time.waits, const [
        Duration(seconds: 2),
        Duration(seconds: 2),
      ]);
      expect(
        adapter.requestUris[2].queryParameters['page'],
        '3',
      );
    });
  });
}
