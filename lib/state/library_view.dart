import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library_filter.dart';
import 'game_index.dart';
import 'library.dart';

/// Looks up the catalogue's latest version for a thread id (null when the
/// thread is not cached or carries no version).
typedef LatestVersionLookup = Future<String?> Function(int threadId);

/// The lookup the library page uses for update detection.
///
/// Backed by the [GameIndexStore] cache; tests override it with a plain
/// function so no database is needed.
final latestVersionLookupProvider = Provider<LatestVersionLookup>(
  (ref) => ref.watch(gameIndexStoreProvider).latestVersionFor,
);

/// The library's games paired with their update flags: every stored game is
/// looked up in the catalogue index by `threadId`, and its local version is
/// compared against the cached latest (ticket 53).
///
/// Recomputes whenever the library's game list changes. A failed lookup only
/// downgrades that game to its scrape-time `latestVersion`; it never breaks
/// the list.
final libraryEntriesProvider = FutureProvider.autoDispose<List<LibraryEntry>>((
  ref,
) async {
  final games = ref.watch(libraryProvider.select((state) => state.games));
  if (games.isEmpty) {
    return const [];
  }
  final lookup = ref.watch(latestVersionLookupProvider);
  final versions = <int, String?>{};
  await Future.wait([
    for (final game in games)
      () async {
        String? version;
        try {
          version = await lookup(game.threadId);
        } catch (_) {
          version = null;
        }
        versions[game.threadId] = version;
      }(),
  ]);
  return [
    for (final game in games) libraryEntryFor(game, versions[game.threadId]),
  ];
});
