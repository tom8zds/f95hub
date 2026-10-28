import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/f95zone_metadata_source.dart';
import 'package:f95hub/domain/ports.dart';

void main() {
  group('parseListResponse', () {
    // Recorded (redacted) live response from research 01.
    const recorded = '''
{
  "status": "ok",
  "msg": {
    "data": [
      {
        "thread_id": 319855,
        "title": "Kunoichi Sensei",
        "creator": "NTRNoob",
        "version": "v0.0.1",
        "views": 2076,
        "likes": 3,
        "prefixes": [3],
        "tags": [173, 448, 505, 783, 1507, 2229, 2265],
        "rating": 0,
        "cover": "https://preview.f95zone.to/2026/10/6626188_1792723282230.png",
        "screens": ["https://preview.f95zone.to/2026/10/6626033_super-fast.gif"],
        "date": "1 hr",
        "watched": false,
        "ignored": false,
        "new": false,
        "ts": 1792808403
      }
    ],
    "pagination": { "page": 1, "total": 931 },
    "count": 27913
  }
}
''';

    test('maps fields to Game and GameListPage', () {
      final page = parseListResponse(jsonDecode(recorded));

      expect(page.items, hasLength(1));
      expect(page.page, 1);
      expect(page.totalPages, 931);
      expect(page.totalCount, 27913);

      final game = page.items.single;
      expect(game.threadId, 319855);
      expect(game.title, 'Kunoichi Sensei');
      expect(game.creator, 'NTRNoob');
      expect(game.latestVersion, 'v0.0.1');
      expect(
        game.cover,
        'https://preview.f95zone.to/2026/10/6626188_1792723282230.png',
      );
      expect(game.screens, [
        'https://preview.f95zone.to/2026/10/6626033_super-fast.gif',
      ]);
      expect(
        game.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1792808403 * 1000),
      );
    });

    test('throws F95zoneException on a non-ok status', () {
      expect(
        () => parseListResponse({'status': 'error', 'msg': 'missing category'}),
        throwsA(isA<F95zoneException>()),
      );
    });

    test('throws F95zoneException on a non-object body', () {
      expect(() => parseListResponse('nope'), throwsA(isA<F95zoneException>()));
    });

    test('tolerates missing pagination and count', () {
      final page = parseListResponse({
        'status': 'ok',
        'msg': {
          'data': [
            {'thread_id': 1},
          ],
        },
      });

      expect(page.items.single.threadId, 1);
      expect(page.page, 1);
      expect(page.totalPages, 1);
      expect(page.totalCount, 1);
    });
  });

  group('buildListQuery', () {
    test('builds the base query with sort and page', () {
      final q = buildListQuery(
        GameCategory.games,
        sort: SortOrder.rating,
        page: 3,
      );
      expect(q, 'cmd=list&cat=games&page=3&sort=rating');
    });

    test('appends tags[]/prefixes[] in PHP array notation', () {
      final q = buildListQuery(
        GameCategory.games,
        tags: [45, 107],
        prefixes: [1],
      );
      expect(
        q,
        'cmd=list&cat=games&page=1&sort=date&tags[]=45&tags[]=107&prefixes[]=1',
      );
    });

    test('appends date only when provided', () {
      expect(
        buildListQuery(GameCategory.games, date: 7),
        'cmd=list&cat=games&page=1&sort=date&date=7',
      );
      expect(
        buildListQuery(GameCategory.games),
        'cmd=list&cat=games&page=1&sort=date',
      );
    });
  });

  group('parseTagTable', () {
    // Trimmed `var latestUpdates = {…}` from /latest (research 01 §4).
    const html = '''
<!DOCTYPE html><html><head></head><body>
<script>
  var latestUpdates = {
    "prefixes": {
      "games": [
        {"id": 3, "name": "Other", "prefixes": [
          {"id": 19, "name": "Collection", "class": "x"},
          {"id": 13, "name": "VN", "class": "x"}
        ]},
        {"id": 1, "name": "Engine", "prefixes": [
          {"id": 3, "name": "Unity", "class": "x"},
          {"id": 7, "name": "Ren'Py", "class": "x"}
        ]}
      ],
      "comics": [
        {"id": 3, "name": "Other", "prefixes": [
          {"id": 43, "name": "Manga", "class": "x"}
        ]}
      ]
    },
    "tags": {"30": "incest", "45": "rpg", "1507": "2dcg"},
    "options": false
  };
</script></body></html>
''';

    test('resolves tag ids to names', () {
      final table = parseTagTable(html);
      expect(table.tagName(45), 'rpg');
      expect(table.tagName(1507), '2dcg');
      expect(table.tagName(9999), isNull);
    });

    test('resolves prefix ids per category, sharing the id namespace', () {
      final table = parseTagTable(html);

      // id 3 is "Unity" under games → Engine, but "Manga" (id 43) is comics.
      expect(table.prefixName(GameCategory.games, 3),
          (group: 'Engine', name: 'Unity'));
      expect(table.prefixName(GameCategory.games, 13),
          (group: 'Other', name: 'VN'));
      expect(table.prefixName(GameCategory.comics, 43),
          (group: 'Other', name: 'Manga'));
      // id 13 does not exist under comics.
      expect(table.prefixName(GameCategory.comics, 13), isNull);
      // Unknown id.
      expect(table.prefixName(GameCategory.games, 9999), isNull);
    });

    test('throws F95zoneException when the table is missing', () {
      expect(
        () => parseTagTable('<html>no table here</html>'),
        throwsA(isA<F95zoneException>()),
      );
    });
  });

  group('parseThreadDetail', () {
    const html = '''
<!DOCTYPE html><html>
<head>
  <meta property="og:title" content="Kunoichi Sensei" />
  <meta property="og:description" content="Overview: A ninja training sim." />
  <title>Kunoichi Sensei | F95zone</title>
</head>
<body>
  <article>
    <div class="message-content">
      <div class="bbWrapper">Full overview text with <b>bold</b> &amp; a
        <div class="bbImageWrapper">nested image</div> inside.</div>
    </div>
  </article>
</body></html>
''';

    test('extracts title and og:description (stripping Overview:)', () {
      final detail = parseThreadDetail(html, threadId: 319855);
      expect(detail.threadId, 319855);
      expect(detail.title, 'Kunoichi Sensei');
      expect(detail.description, 'A ninja training sim.');
    });

    test('falls back to the first bbWrapper text when og:description is absent',
        () {
      final noOg = html.replaceAll(
        RegExp(r'<meta property="og:description"[^>]*/>'),
        '',
      );
      final detail = parseThreadDetail(noOg, threadId: 319855);
      expect(
        detail.description,
        'Full overview text with bold & a nested image inside.',
      );
    });

    test('falls back to empty description when neither source exists', () {
      final bare = '<html><head><title>X</title></head><body></body></html>';
      final detail = parseThreadDetail(bare, threadId: 1);
      expect(detail.title, 'X');
      expect(detail.description, '');
    });

    test('falls back to <title> when og:title is absent', () {
      final noTitle = html.replaceAll(
        RegExp(r'<meta property="og:title"[^>]*/>'),
        '',
      );
      final detail = parseThreadDetail(noTitle, threadId: 319855);
      expect(detail.title, 'Kunoichi Sensei');
    });
  });

  group('parseListResponse — numeric title/creator/version', () {
    test('coerces non-string title/creator/version to strings', () {
      const body =
          '{"status":"ok","msg":{"data":[{"thread_id":163136,"title":2040,'
          '"creator":933,"version":1.02,"cover":null,"screens":[],"tags":[],'
          '"prefixes":[],"rating":0,"views":1,"likes":0,"ts":1792808403}],'
          '"pagination":{"page":1,"total":931},"count":27913}}';
      final page = parseListResponse(jsonDecode(body));
      final game = page.items.single;
      expect(game.title, '2040');
      expect(game.creator, '933');
      expect(game.latestVersion, '1.02');
      expect(game.cover, isNull);
    });
  });
}
