import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/ports.dart';

import 'support/fake_metadata_source.dart';

void main() {
  test('tagNamesFor resolves ids to names and drops unknown ids', () {
    final table = makeTagTable();
    expect(table.tagNamesFor([45, 107, 9999]), ['rpg', '3dcg']);
    expect(table.tagNamesFor(const []), isEmpty);
  });

  test('tagItems enumerates the flat tag map in order', () {
    final table = makeTagTable();
    expect(table.tagItems(), [
      (id: 45, name: 'rpg'),
      (id: 107, name: '3dcg'),
      (id: 1507, name: '2dcg'),
    ]);
  });

  test('prefixesFor resolves ids to (group, name) pairs per category', () {
    final table = makeTagTable();

    final games = table.prefixesFor(GameCategory.games, [3, 13, 9999]);
    expect(games, [
      (group: 'Engine', name: 'Unity'),
      (group: 'Other', name: 'VN'),
    ]);

    // Unknown category resolves nothing.
    expect(table.prefixesFor(GameCategory.comics, [3, 13]), isEmpty);
  });

  test('prefixGroupItems returns the groups for a category in order', () {
    final table = makeTagTable();

    final games = table.prefixGroupItems(GameCategory.games);
    expect(games.map((g) => g.name), ['Other', 'Engine', 'Status']);
    expect(games[1].prefixes.map((p) => p.name), ['Unity', "Ren'Py"]);

    // Unknown category yields an empty list.
    expect(table.prefixGroupItems(GameCategory.comics), isEmpty);
  });
}
