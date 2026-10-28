/// Client-side filtering for the local library (ticket 53): a library entry
/// pairs a stored [Game] with the update flag computed against the catalogue
/// index, and [LibraryFilter] narrows the list by title, tags and/or updates.
///
/// Pure: no I/O and no Flutter dependencies, so the rules are unit-testable
/// without a widget tree.
library;

import 'models.dart';

/// A library game plus whether f95zone reports a newer version.
class LibraryEntry {
  const LibraryEntry({required this.game, this.hasUpdate = false});

  final Game game;

  /// True when the local installed version differs from the catalogue's
  /// latest (see [hasUpdateFor]).
  final bool hasUpdate;
}

/// Whether [localVersion] differs from the catalogue's [latestVersion].
///
/// Both sides must be non-empty: a game whose install has not been versioned
/// yet is never flagged, and an index without a version tells us nothing.
bool hasUpdateFor({required String localVersion, String? latestVersion}) =>
    localVersion.isNotEmpty &&
    latestVersion != null &&
    latestVersion.isNotEmpty &&
    latestVersion != localVersion;

/// Builds a [LibraryEntry] from a stored [game] and the index's latest
/// version for it.
///
/// [indexLatest] (the cached catalogue version) wins when present; otherwise
/// the game's own scrape-time [Game.latestVersion] is used, so a library that
/// predates the catalogue cache still gets update detection.
LibraryEntry libraryEntryFor(Game game, String? indexLatest) {
  final latest = indexLatest != null && indexLatest.isNotEmpty
      ? indexLatest
      : game.latestVersion;
  return LibraryEntry(
    game: game,
    hasUpdate: hasUpdateFor(localVersion: game.version, latestVersion: latest),
  );
}

/// The library filter: a title query, a multi-select tag set and a
/// "has update" switch. All three combine with AND; within [tags] a game
/// matches when it carries *any* selected tag.
class LibraryFilter {
  const LibraryFilter({
    this.query = '',
    this.tags = const <String>{},
    this.onlyUpdates = false,
  });

  final String query;
  final Set<String> tags;
  final bool onlyUpdates;

  /// True when the filter would narrow the list.
  bool get isActive =>
      query.trim().isNotEmpty || tags.isNotEmpty || onlyUpdates;

  LibraryFilter copyWith({
    String? query,
    Set<String>? tags,
    bool? onlyUpdates,
  }) {
    return LibraryFilter(
      query: query ?? this.query,
      tags: tags ?? this.tags,
      onlyUpdates: onlyUpdates ?? this.onlyUpdates,
    );
  }
}

/// Narrows [entries] to the ones matching every active dimension of [filter].
///
/// The title match is a case-insensitive substring test on [Game.title]; tags
/// match when any selected name is present on the game.
List<LibraryEntry> filterLibrary(
  List<LibraryEntry> entries,
  LibraryFilter filter,
) {
  final needle = filter.query.trim().toLowerCase();
  return entries
      .where((entry) {
        if (filter.onlyUpdates && !entry.hasUpdate) {
          return false;
        }
        if (needle.isNotEmpty &&
            !entry.game.title.toLowerCase().contains(needle)) {
          return false;
        }
        if (filter.tags.isNotEmpty &&
            !entry.game.tags.any(filter.tags.contains)) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

/// The tag names present across [games], de-duplicated and case-insensitively
/// sorted: the options of the library's tag filter.
List<String> libraryTagOptions(Iterable<Game> games) {
  final tags = <String>{for (final game in games) ...game.tags};
  final sorted = tags.toList(growable: false)
    ..sort((a, b) {
      final byName = a.toLowerCase().compareTo(b.toLowerCase());
      return byName != 0 ? byName : a.compareTo(b);
    });
  return sorted;
}
