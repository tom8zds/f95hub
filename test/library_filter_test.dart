import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/library_filter.dart';
import 'package:f95hub/domain/models.dart';

Game _game(
  int threadId, {
  required String title,
  String version = 'v1.0',
  String latestVersion = 'v1.0',
  List<String> tags = const [],
}) => Game(
  threadId: threadId,
  title: title,
  creator: 'Creator',
  version: version,
  latestVersion: latestVersion,
  tags: tags,
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 24),
);

List<LibraryEntry> _entries() => [
  LibraryEntry(
    game: _game(1, title: 'Kunoichi Sensei', tags: ['rpg', '3dcg']),
  ),
  LibraryEntry(
    game: _game(2, title: 'Secret Care Cafe', tags: ['rpg', 'romance']),
    hasUpdate: true,
  ),
  LibraryEntry(
    game: _game(3, title: 'Pixel Farm', tags: ['sandbox']),
  ),
];

void main() {
  group('hasUpdateFor', () {
    test('is false when the versions match', () {
      expect(
        hasUpdateFor(localVersion: 'v1.0', latestVersion: 'v1.0'),
        isFalse,
      );
    });

    test('is true when the versions differ', () {
      expect(hasUpdateFor(localVersion: 'v1.0', latestVersion: 'v1.1'), isTrue);
    });

    test('is false when the local version is empty', () {
      expect(hasUpdateFor(localVersion: '', latestVersion: 'v1.1'), isFalse);
    });

    test('is false when the catalogue has no version', () {
      expect(hasUpdateFor(localVersion: 'v1.0', latestVersion: ''), isFalse);
      expect(hasUpdateFor(localVersion: 'v1.0', latestVersion: null), isFalse);
    });
  });

  group('libraryEntryFor', () {
    test('prefers the index version over the scrape-time latest', () {
      final entry = libraryEntryFor(
        _game(1, title: 'Game', version: 'v1.0', latestVersion: 'v1.0'),
        'v2.0',
      );

      expect(entry.hasUpdate, isTrue);
    });

    test('falls back to the game latest version when the index has none', () {
      final entry = libraryEntryFor(
        _game(1, title: 'Game', version: 'v1.0', latestVersion: 'v1.5'),
        null,
      );

      expect(entry.hasUpdate, isTrue);
    });

    test('has no update when both sides are empty', () {
      final entry = libraryEntryFor(
        _game(1, title: 'Game', version: '', latestVersion: ''),
        null,
      );

      expect(entry.hasUpdate, isFalse);
    });
  });

  group('filterLibrary', () {
    test('matches the title case-insensitively and trims the query', () {
      final result = filterLibrary(
        _entries(),
        const LibraryFilter(query: '  KUNOICHI '),
      );

      expect(result.map((e) => e.game.threadId), [1]);
    });

    test('matches a game carrying any selected tag', () {
      final result = filterLibrary(
        _entries(),
        const LibraryFilter(tags: {'romance', 'sandbox'}),
      );

      expect(result.map((e) => e.game.threadId), [2, 3]);
    });

    test('keeps only outdated games when onlyUpdates is set', () {
      final result = filterLibrary(
        _entries(),
        const LibraryFilter(onlyUpdates: true),
      );

      expect(result.map((e) => e.game.threadId), [2]);
    });

    test('combines query, tags and onlyUpdates with AND', () {
      final result = filterLibrary(
        _entries(),
        const LibraryFilter(query: 'care', tags: {'rpg'}, onlyUpdates: true),
      );

      expect(result.map((e) => e.game.threadId), [2]);

      final none = filterLibrary(
        _entries(),
        const LibraryFilter(
          query: 'care',
          tags: {'sandbox'},
          onlyUpdates: true,
        ),
      );
      expect(none, isEmpty);
    });

    test('is inactive by default and returns every entry', () {
      const filter = LibraryFilter();
      expect(filter.isActive, isFalse);
      expect(filterLibrary(_entries(), filter), hasLength(3));
    });

    test('copyWith replaces only the given dimension', () {
      const filter = LibraryFilter(
        query: 'a',
        tags: {'rpg'},
        onlyUpdates: true,
      );
      final next = filter.copyWith(tags: {'sandbox'});

      expect(next.query, 'a');
      expect(next.tags, {'sandbox'});
      expect(next.onlyUpdates, isTrue);
    });
  });

  group('libraryTagOptions', () {
    test('unions, de-duplicates and sorts the games tag names', () {
      final options = libraryTagOptions([
        _game(1, title: 'A', tags: ['rpg', 'Romance']),
        _game(2, title: 'B', tags: ['sandbox', 'rpg']),
      ]);

      expect(options, ['Romance', 'rpg', 'sandbox']);
    });

    test('is empty when no game has tags', () {
      expect(libraryTagOptions([_game(1, title: 'A')]), isEmpty);
    });
  });
}
