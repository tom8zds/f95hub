import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/library_filter.dart';
import 'package:f95hub/domain/library_sort.dart';
import 'package:f95hub/domain/models.dart';

Game _game(
  int threadId, {
  required String title,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Game(
  threadId: threadId,
  title: title,
  creator: 'Creator',
  version: 'v1.0',
  latestVersion: 'v1.0',
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  updatedAt: updatedAt ?? DateTime(2026, 1, 1),
);

List<LibraryEntry> _entries() => [
  LibraryEntry(
    game: _game(
      1,
      title: 'Bravo Game',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 10),
    ),
  ),
  LibraryEntry(
    game: _game(
      2,
      title: 'alpha Game',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 2, 1),
    ),
  ),
  LibraryEntry(
    game: _game(
      3,
      title: 'Charlie Game',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 20),
    ),
  ),
];

List<String> _titles(List<LibraryEntry> entries) => [
  for (final entry in entries) entry.game.title,
];

void main() {
  test('recently updated puts the newest update first', () {
    expect(_titles(sortLibrary(_entries(), LibrarySortOrder.updated)), [
      'alpha Game',
      'Charlie Game',
      'Bravo Game',
    ]);
  });

  test('recently added puts the newest addition first', () {
    expect(_titles(sortLibrary(_entries(), LibrarySortOrder.added)), [
      'Bravo Game',
      'Charlie Game',
      'alpha Game',
    ]);
  });

  test('title sorts case-insensitively', () {
    expect(_titles(sortLibrary(_entries(), LibrarySortOrder.title)), [
      'alpha Game',
      'Bravo Game',
      'Charlie Game',
    ]);
  });

  test('ties fall back to the thread id and the input is untouched', () {
    final entries = [
      LibraryEntry(game: _game(9, title: 'Same')),
      LibraryEntry(game: _game(4, title: 'same')),
    ];
    final sorted = sortLibrary(entries, LibrarySortOrder.title);

    expect(sorted.map((entry) => entry.game.threadId), [4, 9]);
    expect(entries.map((entry) => entry.game.threadId), [9, 4]);
  });
}
