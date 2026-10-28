import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate, HttpException;
import 'dart:math' show Random;

import 'package:dio/dio.dart';

import '../domain/ports.dart';

/// Raised when the f95zone `latest_data.php` endpoint returns `status != "ok"`
/// or a malformed body.
class F95zoneException implements Exception {
  const F95zoneException(this.message);

  final String message;

  @override
  String toString() => 'F95zoneException: $message';
}

/// Builds the query string for a `cmd=list` request.
///
/// The endpoint expects PHP array notation (`tags[]=45&tags[]=107`), so the
/// query is assembled by hand rather than through dio's `queryParameters`
/// (whose list encoding would drop the `[]` brackets).
String buildListQuery(
  GameCategory cat, {
  List<int>? tags,
  List<int>? prefixes,
  SortOrder sort = SortOrder.date,
  int? date,
  int page = 1,
}) {
  final parts = <String>[
    'cmd=list',
    'cat=${cat.name}',
    'page=$page',
    'sort=${sort.name}',
  ];
  for (final tag in tags ?? const <int>[]) {
    parts.add('tags[]=$tag');
  }
  for (final prefix in prefixes ?? const <int>[]) {
    parts.add('prefixes[]=$prefix');
  }
  if (date != null) {
    parts.add('date=$date');
  }
  return parts.join('&');
}

/// A delay used between 429 backoff retries (injectable so tests run fast).
typedef BackoffDelay = Future<void> Function(Duration duration);

/// Wall clock used to pace requests (injectable so tests can fake time).
typedef MetadataClock = DateTime Function();

/// Uniform source of `0 .. max - 1` integers used for the request jitter
/// (injectable so tests can make the wait deterministic).
typedef RandomInt = int Function(int max);

/// Real [MetadataSource] adapter over the f95zone `latest_data.php` endpoint.
class F95zoneMetadataSource implements MetadataSource {
  F95zoneMetadataSource({
    Dio? dio,
    String? baseUrl,
    BackoffDelay? backoffDelay,
    MetadataClock? clock,
    RandomInt? randomInt,
    this.requestInterval = const Duration(milliseconds: 1500),
    this.jitter = const Duration(milliseconds: 800),
    this.maxRetries = 10,
    this.retriesPerThrottle = 5,
    this.retryPause = const Duration(seconds: 90),
    this.maxAttempts = 200,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? _endpoint,
        _backoffDelay = backoffDelay ?? _defaultDelay,
        _clock = clock ?? DateTime.now,
        _randomInt = randomInt ?? Random().nextInt;

  static const _endpoint =
      'https://f95zone.to/sam/latest_alpha/latest_data.php';

  static const _threadsBase = 'https://f95zone.to/threads';

  static const _latestUrl = 'https://f95zone.to/latest';


  final Dio _dio;
  final String _baseUrl;

  /// In-memory session cookie; null until [login] succeeds. Never persisted.
  String? _cookie;

  /// Minimum wall-clock gap between two requests; f95zone returns 429 after
  /// roughly a dozen back-to-back requests (research 01 §5.2).
  final Duration requestInterval;

  /// Random extra wait drawn uniformly from `0 .. jitter` and added on top of
  /// [requestInterval], so the request cadence isn't perfectly periodic.
  final Duration jitter;

  /// Initial number of 429 retries granted; every 429 then refills the budget
  /// by [retriesPerThrottle], so a throttle burst does not end the fetch.
  final int maxRetries;

  /// Retries added to the budget each time the server answers 429.
  final int retriesPerThrottle;

  /// Fixed pause before each 429 retry. A longer `Retry-After` wins.
  final Duration retryPause;

  /// Hard cap on requests per fetch, so a server stuck on 429 cannot spin the
  /// retry loop forever.
  final int maxAttempts;

  final BackoffDelay _backoffDelay;
  final MetadataClock _clock;
  final RandomInt _randomInt;

  /// When the last paced request started, or null before the first one.
  DateTime? _lastRequestAt;

  /// Serializes pacing so concurrent callers cannot both slip through the gap.
  Future<void> _paceGate = Future<void>.value();

  /// Broadcasts `true` while backing off from a 429 and `false` once done.
  final StreamController<bool> _throttledController =
      StreamController<bool>.broadcast();

  /// In-memory cache of parsed `listGames`/`getTagTable` responses, keyed by
  /// the request URL. Session-long (no TTL): f95zone rate-limits aggressively
  /// and the static table only needs a periodic re-fetch (research 01 §5.2).
  final Map<String, Object> _cache = {};

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);

  @override
  void clearCache() => _cache.clear();

  /// Returns a cached value for [key], else fetches it (with 429 backoff) and
  /// caches the result.
  Future<T> _cached<T extends Object>(String key, Future<T> Function() fetch) async {
    final hit = _cache[key];
    if (hit != null) {
      return hit as T;
    }
    final value = await _withBackoff(fetch);
    _cache[key] = value;
    return value;
  }

  /// Waits until [requestInterval] plus a random jitter sample has elapsed
  /// since the previous request, then stamps the new one. Concurrent callers
  /// queue up rather than racing, so a burst can never collapse into a single
  /// wait.
  Future<void> _pace() {
    final next = _paceGate.then((_) => _awaitRequestSlot());
    _paceGate = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _awaitRequestSlot() async {
    final last = _lastRequestAt;
    if (last != null) {
      // Jitter only rides on a real interval; a zero interval means the caller
      // explicitly disabled pacing.
      var target = requestInterval;
      if (target > Duration.zero) {
        target += _jitterSample();
      }
      final remaining = target - _clock().difference(last);
      if (remaining > Duration.zero) {
        await _backoffDelay(remaining);
      }
    }
    _lastRequestAt = _clock();
  }

  /// Uniform sample from `0 .. jitter`, inclusive.
  Duration _jitterSample() {
    final bound = jitter.inMicroseconds;
    if (bound <= 0) {
      return Duration.zero;
    }
    return Duration(microseconds: _randomInt(bound + 1));
  }

  /// Parses a `Retry-After` header value: delta-seconds or an HTTP-date.
  ///
  /// Returns null when the header is absent or malformed. Date values are
  /// measured against the injectable [MetadataClock].
  Duration? _retryAfter(Headers? headers) {
    final raw = headers?.value('retry-after')?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds < 0 ? null : Duration(seconds: seconds);
    }
    try {
      final at = HttpDate.parse(raw);
      final remaining = at.difference(_clock().toUtc());
      return remaining.isNegative ? Duration.zero : remaining;
    } on FormatException {
      return null;
    } on HttpException {
      return null;
    }
  }

  /// Retries [fetch] on HTTP 429 with a fixed [retryPause] between attempts
  /// (or `Retry-After` when the server asks for a longer wait).
  ///
  /// Each 429 also adds [retriesPerThrottle] to the retry budget, seeded from
  /// [maxRetries], so a throttle burst rarely gives up. [maxAttempts] is the
  /// hard cap that keeps a server permanently stuck on 429 from spinning
  /// forever.
  Future<T> _withBackoff<T extends Object>(Future<T> Function() fetch) async {
    var attempts = 0;
    var budget = maxRetries;
    while (true) {
      attempts++;
      await _pace();
      try {
        return await fetch();
      } on DioException catch (e) {
        if (e.response?.statusCode != 429) {
          rethrow;
        }
        if (attempts >= maxAttempts) {
          throw RateLimitedException(e);
        }
        if (budget <= 0) {
          throw RateLimitedException(e);
        }
        budget--;
        budget += retriesPerThrottle;

        final retryAfter = _retryAfter(e.response?.headers);
        final wait = retryAfter != null && retryAfter > retryPause
            ? retryAfter
            : retryPause;
        _throttledController.add(true);
        try {
          await _backoffDelay(wait);
        } finally {
          _throttledController.add(false);
        }
      }
    }
  }

  @override
  Stream<bool> get throttled => _throttledController.stream;

  /// The current session cookie header value, or null when not logged in.
  String? get cookie => _cookie;

  /// Request options for an authenticated read, carrying the session cookie as
  /// a `Cookie` header whenever one is set. Logged-out requests send no header
  /// at all (an empty `Cookie` value would be meaningless).
  Options _options({ResponseType? responseType}) {
    final cookie = _cookie;
    final headers = cookie == null || cookie.isEmpty
        ? null
        : <String, String>{'Cookie': cookie};
    return Options(responseType: responseType, headers: headers);
  }

  @override
  Future<GameListPage> listGames(
    GameCategory cat, {
    List<int>? tags,
    List<int>? prefixes,
    SortOrder sort = SortOrder.date,
    int? date,
    int page = 1,
  }) async {
    final query = buildListQuery(
      cat,
      tags: tags,
      prefixes: prefixes,
      sort: sort,
      date: date,
      page: page,
    );
    final url = '$_baseUrl?$query';
    return _cached('list:$url', () async {
      final response = await _dio.get<dynamic>(url, options: _options());
      return parseListResponse(response.data);
    });
  }

  @override
  Future<ThreadDetail> getThread(int threadId) async {
    // dio follows the 301 → slug URL automatically.
    return _withBackoff(() async {
      final response = await _dio.get<String>(
        '$_threadsBase/$threadId',
        options: _options(responseType: ResponseType.plain),
      );
      return parseThreadDetail(response.data ?? '', threadId: threadId);
    });
  }

  @override
  Future<TagTable> getTagTable() async {
    return _cached('tags', () async {
      final response = await _dio.get<String>(
        _latestUrl,
        options: _options(responseType: ResponseType.plain),
      );
      return parseTagTable(response.data ?? '');
    });
  }

  @override
  Future<String> login(LoginCredentials credentials) async {
    final cookie = credentials.cookie?.trim() ?? '';
    if (cookie.isEmpty) {
      throw const F95zoneException('Login requires a session cookie');
    }
    _cookie = cookie;
    // Everything cached before this point was fetched anonymously (or with the
    // previous session) and may differ for a logged-in user — most notably
    // the tag table and every list page. Drop it so the next read refetches.
    _cache.clear();
    return cookie;
  }
}

/// Parses a `cmd=list` response body into a [GameListPage].
///
/// Expected shape (see research 01):
/// `{status, msg:{data:[…], pagination:{page,total}, count}}`.
GameListPage parseListResponse(dynamic body) {
  if (body is! Map<String, dynamic>) {
    throw const F95zoneException('Malformed response: expected a JSON object');
  }
  final status = body['status'];
  if (status != 'ok') {
    throw F95zoneException('Endpoint error: ${body['msg']}');
  }
  final msg = body['msg'];
  if (msg is! Map<String, dynamic>) {
    throw const F95zoneException('Malformed response: missing "msg" object');
  }
  final data = (msg['data'] as List<dynamic>?) ?? const <dynamic>[];
  final pagination =
      (msg['pagination'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

  return GameListPage(
    items: data.map(_parseGame).toList(growable: false),
    page: (pagination['page'] as num?)?.toInt() ?? 1,
    totalPages: (pagination['total'] as num?)?.toInt() ?? 1,
    totalCount: (msg['count'] as num?)?.toInt() ?? data.length,
  );
}

/// Maps one `msg.data` item onto a [Game].
///
/// `ts` (Unix epoch seconds) is the only timestamp the endpoint exposes, so it
/// feeds both [Game.createdAt] and [Game.updatedAt]. `tags`/`prefixes` are
/// numeric ids that can only be resolved to names via the static tag table
/// (`getTagTable`, a later ticket), so they are intentionally left unresolved
/// here. `rating`/`views`/`likes` are carried verbatim for the game index
/// cache; they never drive client-side logic.
/// f95zone occasionally returns a numeric `title`/`creator`/`version` (e.g.
/// `"title": 2040`, `"version": 1.02` instead of `"v1.02"`), so coerce any
/// non-null value to its string form rather than a hard `as String?` cast.
String? _asString(Object? value) =>
    value == null ? null : (value is String ? value : value.toString());

Game _parseGame(dynamic raw) {
  final map = raw as Map<String, dynamic>;
  final ts = (map['ts'] as num?)?.toInt();
  final timestamp = ts != null
      ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
      : DateTime.fromMillisecondsSinceEpoch(0);

  return Game(
    threadId: (map['thread_id'] as num).toInt(),
    title: _asString(map['title']) ?? '',
    creator: _asString(map['creator']) ?? '',
    latestVersion: _asString(map['version']) ?? '',
    cover: map['cover'] is String ? map['cover'] as String : null,
    screens: ((map['screens'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
    tagIds: ((map['tags'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList(growable: false),
    prefixIds: ((map['prefixes'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList(growable: false),
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    views: (map['views'] as num?)?.toInt() ?? 0,
    likes: (map['likes'] as num?)?.toInt() ?? 0,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

/// Parses a thread-page HTML body into a [ThreadDetail].
///
/// The description is the `og:description` meta (an `Overview: …` line) when
/// present, else the first post's `bbWrapper` text with all tags stripped; if
/// neither is found the description falls back to the empty string. The title
/// comes from `og:title` (or `<title>` as a last resort).
ThreadDetail parseThreadDetail(String html, {required int threadId}) {
  final title = _metaContent(html, 'og:title') ?? _titleTag(html) ?? '';

  var description = _overviewDescription(html);
  if (description == null || description.isEmpty) {
    description = _firstBbWrapperText(html) ?? '';
  }

  return ThreadDetail(threadId: threadId, title: title, description: description);
}

/// Extracts the `og:description` content and strips the leading `Overview:`
/// prefix the site prepends.
String? _overviewDescription(String html) {
  final content = _metaContent(html, 'og:description');
  if (content == null) {
    return null;
  }
  final cleaned = content.trim();
  if (cleaned.toLowerCase().startsWith('overview:')) {
    return cleaned.substring('overview:'.length).trim();
  }
  return cleaned;
}

/// Returns the `content` of the first `<meta property="<property>">` tag.
String? _metaContent(String html, String property) {
  final tag = RegExp(
    "<meta[^>]*property=[\"']$property[\"'][^>]*>",
    caseSensitive: false,
  ).firstMatch(html);
  if (tag == null) {
    return null;
  }
  final content =
      RegExp("content=[\"']([^\"']*)[\"']", caseSensitive: false)
          .firstMatch(tag.group(0)!);
  return content?.group(1);
}

/// Returns the `<title>` element's text, if any, with the trailing site name
/// (`| F95zone`) stripped.
String? _titleTag(String html) {
  final match = RegExp(
    r'<title[^>]*>(.*?)</title>',
    dotAll: true,
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) {
    return null;
  }
  final text = _cleanText(match.group(1)!);
  return text.replaceAll(RegExp(r'\s*[|\-]\s*F95zone\s*$'), '').trim();
}

/// Extracts the text of the first `<div class="bbWrapper">` (the OP body),
/// stripping tags and decoding entities. Tracks `div` nesting so nested
/// quotes/images don't terminate the match early.
String? _firstBbWrapperText(String html) {
  final open = RegExp(
    "<div[^>]*class=[\"'][^\"']*\\bbbWrapper\\b[^\"']*[\"'][^>]*>",
    caseSensitive: false,
  ).firstMatch(html);
  if (open == null) {
    return null;
  }

  var depth = 1;
  var lastPos = open.end;
  final buffer = StringBuffer();
  final tag = RegExp(r'<\s*(/?)\s*([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>');

  for (final match in tag.allMatches(html)) {
    if (match.start < lastPos) {
      continue;
    }
    buffer.write(html.substring(lastPos, match.start));
    final closing = match.group(1) == '/';
    final name = match.group(2)!.toLowerCase();
    if (closing) {
      if (name == 'div') depth--;
    } else if (name == 'div') {
      depth++;
    }
    lastPos = match.end;
    if (depth == 0) break;
  }

  return _cleanText(buffer.toString());
}

/// Decodes common HTML entities and collapses whitespace.
String _cleanText(String input) {
  final decoded = input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
  return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Parses the inline `var latestUpdates = {…};` JSON into a [TagTable].
///
/// Expected shape (research 01 §4):
/// `{prefixes: {games: [{id, name, prefixes: [{id, name, class}]}, …], …},
/// tags: {"30": "incest", …}, options: …}`.
TagTable parseTagTable(String html) {
  final match = RegExp(
    r'var\s+latestUpdates\s*=\s*(\{.*?\});',
    dotAll: true,
  ).firstMatch(html);
  if (match == null) {
    throw const F95zoneException('Tag table not found in page HTML');
  }
  final decoded = jsonDecode(match.group(1)!);
  if (decoded is! Map<String, dynamic>) {
    throw const F95zoneException('Malformed tag table: expected a JSON object');
  }
  return _tagTableFromJson(decoded);
}

/// Maps the decoded `latestUpdates` object onto a [TagTable].
TagTable _tagTableFromJson(Map<String, dynamic> json) {
  final tags = <int, String>{};
  final tagsRaw = json['tags'];
  if (tagsRaw is Map<String, dynamic>) {
    tagsRaw.forEach((key, value) {
      if (value is String) {
        tags[int.parse(key)] = value;
      }
    });
  }

  final prefixes = <GameCategory, List<PrefixGroup>>{};
  final prefixesRaw = json['prefixes'];
  if (prefixesRaw is Map<String, dynamic>) {
    final byName = GameCategory.values.asNameMap();
    prefixesRaw.forEach((catKey, groupsRaw) {
      final cat = byName[catKey];
      if (cat == null || groupsRaw is! List<dynamic>) {
        return;
      }
      prefixes[cat] = groupsRaw
          .whereType<Map<String, dynamic>>()
          .map(_prefixGroupFromJson)
          .toList(growable: false);
    });
  }

  return TagTable(tags: tags, prefixes: prefixes);
}

/// Maps one prefix group object onto a [PrefixGroup].
PrefixGroup _prefixGroupFromJson(Map<String, dynamic> json) {
  final childRaw = json['prefixes'];
  final prefixes = <Prefix>[];
  if (childRaw is List<dynamic>) {
    for (final child in childRaw.whereType<Map<String, dynamic>>()) {
      final id = child['id'];
      final name = child['name'];
      if (id is num && name is String) {
        prefixes.add(Prefix(id: id.toInt(), name: name));
      }
    }
  }
  return PrefixGroup(
    id: (json['id'] as num?)?.toInt() ?? -1,
    name: (json['name'] as String?) ?? '',
    prefixes: prefixes,
  );
}
