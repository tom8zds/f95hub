import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/ports.dart';
import 'package:f95hub/domain/scraper.dart';

import 'support/fake_metadata_source.dart';

void main() {
  test('maps listing + thread + tag table into a library game', () {
    final listing = makeGame(7, tagIds: const [45, 107, 9999], prefixIds: const [3, 13]);
    final thread = makeThreadDetail(7, description: 'A ninja training sim.');
    final now = DateTime(2026, 10, 24);

    final game = scrapeToLibraryGame(
      listing,
      thread,
      makeTagTable(),
      installPath: 'C:/games/7',
      now: now,
    );

    expect(game.threadId, 7);
    expect(game.title, 'Game 7');
    expect(game.creator, 'Creator 7');
    expect(game.version, ''); // local version is unknown until downloaded/imported
    expect(game.latestVersion, 'v0.0.7');
    expect(game.tags, ['rpg', '3dcg']); // 9999 is unresolved → dropped
    expect(game.engine, 'Unity'); // prefix id 3 under the "Engine" group
    expect(game.developer, '');
    expect(game.description, 'A ninja training sim.');
    expect(game.installPath, 'C:/games/7');
    expect(game.createdAt, now);
    expect(game.updatedAt, now);
    // Raw numeric ids are preserved verbatim.
    expect(game.tagIds, [45, 107, 9999]);
    expect(game.prefixIds, [3, 13]);
  });

  test('resolves nothing when the tag table is empty', () {
    final listing = makeGame(1, tagIds: const [45], prefixIds: const [3]);
    final game = scrapeToLibraryGame(
      listing,
      makeThreadDetail(1),
      const TagTable(tags: {}, prefixes: {}),
    );
    expect(game.tags, isEmpty);
    expect(game.engine, isEmpty);
  });

  test('falls back to the thread title when the listing title is empty', () {
    final listing = makeGame(1, title: '');
    final thread = makeThreadDetail(1, title: 'From thread');
    final game = scrapeToLibraryGame(listing, thread, makeTagTable());
    expect(game.title, 'From thread');
  });

  test('leaves installPath null when not provided', () {
    final game = scrapeToLibraryGame(
      makeGame(1),
      makeThreadDetail(1),
      makeTagTable(),
    );
    expect(game.installPath, isNull);
  });

  test('uses the provided local version instead of the listing version', () {
    final game = scrapeToLibraryGame(
      makeGame(1),
      makeThreadDetail(1),
      makeTagTable(),
      version: '0.56',
    );
    expect(game.version, '0.56');
  });

  test('defaults the local version to the listing version', () {
    final game = scrapeToLibraryGame(
      makeGame(1),
      makeThreadDetail(1),
      makeTagTable(),
    );
    expect(game.version, ''); // listing version is empty
  });

  group('parseVersionFromName', () {
    test('parses a dotted version from a folder name', () {
      expect(parseVersionFromName('DevotedWife-0.56-pc'), '0.56');
    });

    test('tolerates a full path and keeps only the last segment', () {
      expect(
        parseVersionFromName(r'C:\games\DevotedWife-0.56-pc'),
        '0.56',
      );
      expect(
        parseVersionFromName('C:/games/DevotedWife-0.56-pc'),
        '0.56',
      );
    });

    test('keeps a leading v prefix', () {
      expect(parseVersionFromName('Game-v0.0.1'), 'v0.0.1');
    });

    test('returns empty for an unparsable name', () {
      expect(parseVersionFromName('SomeFolder'), '');
      expect(parseVersionFromName(''), '');
      expect(parseVersionFromName('Game-2024'), ''); // bare year, no dot
    });
  });

  group('parseFolderName', () {
    test('parses title + version from a Patreon-suffixed folder', () {
      final result = parseFolderName('Secret Care Cafe 0.9.5 Patreon');
      expect(result.title, 'Secret Care Cafe');
      expect(result.version, '0.9.5');
    });

    test('parses a dash-separated folder name', () {
      final result = parseFolderName('DevotedWife-0.56-pc');
      expect(result.title, 'DevotedWife');
      expect(result.version, '0.56');
    });

    test('parses a bracketed English + version suffix', () {
      final result = parseFolderName('Coin Pussy [English v1.0]');
      expect(result.title, 'Coin Pussy');
      expect(result.version, '1.0');
    });

    test('tolerates a full path and keeps only the last segment', () {
      expect(
        parseFolderName(r'C:\games\Secret Care Cafe 0.9.5 Patreon').title,
        'Secret Care Cafe',
      );
      expect(
        parseFolderName('C:/games/DevotedWife-0.56-pc').version,
        '0.56',
      );
    });

    test('strips noise words and brackets, collapsing whitespace', () {
      expect(
        parseFolderName('My Game [v2.1.0] (Windows) Final').title,
        'My Game',
      );
      expect(parseFolderName('My Game [v2.1.0] (Windows) Final').version, '2.1.0');
    });

    test('returns an empty title for a version-only folder', () {
      final result = parseFolderName('0.9.5');
      expect(result.title, '');
      expect(result.version, '0.9.5');
    });

    test('strips a trailing space-separated date', () {
      final result = parseFolderName(
        'Amelia and the Erotic Tentacle Trap Dungeon 2025 11 14',
      );
      expect(result.title, 'Amelia and the Erotic Tentacle Trap Dungeon');
      expect(result.version, '');
    });

    test('strips a trailing date in any separator style', () {
      for (final date in [
        '2025-11-14',
        '2025_11_14',
        '2025.11.14',
        '2025 11',
      ]) {
        expect(
          parseFolderName('Some Game $date').title,
          'Some Game',
          reason: date,
        );
      }
    });

    test('keeps a trailing year that is not a date', () {
      expect(parseFolderName('Some Game 2025').title, 'Some Game 2025');
    });
  });

  group('normalizeThreadTitle', () {
    test('strips the category prefix and bracket suffixes', () {
      expect(
        normalizeThreadTitle('Others - Secret Care Cafe [v0.9.5] [Rare Alex]'),
        'Secret Care Cafe',
      );
    });

    test("strips a Ren'Py category prefix", () {
      expect(
        normalizeThreadTitle("Ren'Py - My Game [v1.2]"),
        'My Game',
      );
    });

    test('leaves an already-clean title intact', () {
      expect(normalizeThreadTitle('Secret Care Cafe'), 'Secret Care Cafe');
    });
  });
}
