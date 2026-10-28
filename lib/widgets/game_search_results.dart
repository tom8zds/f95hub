import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import 'cover_image.dart';

/// The result list of [GameSearchList].
///
/// Extracted so the search state (debounce, index queries) and the pure
/// presentation (tiles, busy spinner) can be tested independently.
class GameSearchResults extends StatelessWidget {
  const GameSearchResults({
    super.key,
    required this.games,
    required this.onSelect,
    this.busyThreadId,
    this.highlightedThreadIds = const {},
    this.cacheManager,
  });

  final List<Game> games;

  /// Called with the tapped game.
  final ValueChanged<Game> onSelect;

  /// Thread currently being imported; every tile is disabled while non-null.
  final int? busyThreadId;

  /// Rows that are an exact title match for the query; rendered highlighted.
  final Set<int> highlightedThreadIds;

  /// Cache manager the cover thumbnails load through; null uses the shared
  /// disk cache. Tests inject a fake to stay offline.
  final BaseCacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final busy = busyThreadId == game.threadId;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CoverImage(url: game.cover, cacheManager: cacheManager),
            ),
          ),
          title: Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(game.creator),
          selected: highlightedThreadIds.contains(game.threadId),
          enabled: busyThreadId == null,
          trailing: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: () => onSelect(game),
        );
      },
    );
  }
}

/// Empty state shown when the local game index has never been built.
///
/// The import search is fully local, so an empty cache would otherwise look
/// like "no matches"; pointing at Settings makes the remedy discoverable.
class GameIndexEmptyHint extends StatelessWidget {
  const GameIndexEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      key: const ValueKey('game-index-empty'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              t.games.indexEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(t.games.indexEmptyMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Explains that the cached catalogue is only partially built.
///
/// A short cache makes a missing match look like "this game does not exist",
/// so the import surfaces spell out how much of the listing is cached. Renders
/// nothing once every catalogue page is cached (or when no build has run).
class GameIndexCompletenessHint extends StatelessWidget {
  const GameIndexCompletenessHint({
    super.key,
    required this.lastBuiltPage,
    required this.totalPages,
  });

  /// Last page a full build wrote; `0` when never built.
  final int lastBuiltPage;

  /// Catalogue page count seen by the build; `0` when unknown.
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 0 || lastBuiltPage >= totalPages) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('game-index-incomplete'),
      children: [
        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.t.import.cacheIncomplete(
              built: lastBuiltPage,
              total: totalPages,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty state shown when a non-blank query matches no cached title.
class GameSearchNoMatches extends StatelessWidget {
  const GameSearchNoMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(context.t.common.noMatches));
  }
}
