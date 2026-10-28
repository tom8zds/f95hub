import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/library.dart';
import '../theme/tokens.dart';
import 'cover_image.dart';
import 'detail_layout.dart';
import 'info_section.dart';
import 'library_actions.dart';
import 'library_detail_actions.dart';
import 'play_sessions_section.dart';
import 'screenshot_gallery.dart';
import 'tag_chips.dart';
import 'version_side_by_side.dart';
import 'open_in_browser_button.dart';

/// A library detail hosted in the wide layout's right-hand pane and by the
/// narrow layout's pushed route: the complete view, with removing the game
/// closing its tab/route.
class LibraryDetailPaneTab extends ConsumerWidget {
  const LibraryDetailPaneTab({
    super.key,
    required this.game,
    this.cacheManager,
    required this.onClose,
    this.showTitle = true,
    this.topBar,
  });

  final Game game;

  /// Cache manager for the cover/gallery; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  /// Closes this tab (called after the entry was removed).
  final VoidCallback onClose;

  /// Whether the content header renders the game title (false when the host
  /// route's top bar already shows it).
  final bool showTitle;

  /// Optional pinned bar above the content column (the route's back + title).
  final Widget? topBar;

  Game _currentGame(WidgetRef ref) {
    final games = ref.watch(libraryProvider).games;
    for (final candidate in games) {
      if (candidate.threadId == game.threadId) {
        return candidate;
      }
    }
    return game;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(libraryProvider.notifier);
    final game = _currentGame(ref);
    final stats = ref.watch(playStatsProvider(game.threadId));
    final hasInstallPath =
        game.installPath != null && game.installPath!.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: OpenInBrowserButton(game: game),
      body: LibraryDetailView(
        game: game,
        cacheManager: cacheManager,
        showTitle: showTitle,
        topBar: topBar,
        stats: stats.value ?? const PlayStats(),
        statsLoading: stats.isLoading && !stats.hasValue,
        onPickLaunchEntry: hasInstallPath
            ? () => pickLaunchEntry(context, ref, game)
            : null,
        onOpenFolder: () => controller.openFolder(game),
        onLaunch: () => launchGame(context, ref, game),
        onEditVersion: () => editLibraryVersion(context, ref, game),
        onRemove: () => removeLibraryGame(context, ref, game, onRemoved: onClose),
      ),
    );
  }
}

/// The library-detail content: title/creator header, sidebar (cover, versions,
/// playtime, actions) and content sections (gallery, tags, description).
///
/// Extracted so the complete detail can be rendered in isolation for a
/// golden preview; the hosts own scanning/persistence. Wide windows lay it
/// out as two panes via [DetailLayout].
class LibraryDetailView extends StatelessWidget {
  const LibraryDetailView({
    super.key,
    required this.game,
    required this.onOpenFolder,
    required this.onLaunch,
    required this.onRemove,
    required this.onEditVersion,
    this.stats = const PlayStats(),
    this.statsLoading = false,
    this.onPickLaunchEntry,
    this.cacheManager,
    this.showTitle = true,
    this.topBar,
  });

  final Game game;
  final PlayStats stats;
  final bool statsLoading;
  final VoidCallback? onPickLaunchEntry;
  final VoidCallback onOpenFolder;
  final VoidCallback onLaunch;
  final VoidCallback onRemove;
  final VoidCallback onEditVersion;

  /// Cache manager for the cover/gallery; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  /// Whether to render the title in the header (false when the hosting route's
  /// top bar already shows it).
  final bool showTitle;

  /// Optional pinned bar above the content column (the route's back + title).
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final hasPath =
        game.installPath != null && game.installPath!.isNotEmpty;
    final cover = game.cover;
    final hasCover = cover != null && cover.isNotEmpty;
    return DetailLayout(
      topBar: topBar,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(game.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            game.creator.isEmpty ? '—' : game.creator,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      sidebar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCover)
            // f95 covers are wide banners (like the list cards): 16:9, rounded.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CoverImage(url: cover, cacheManager: cacheManager),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          VersionSideBySide(
            version: game.version,
            latestVersion: game.latestVersion,
            onEditVersion: onEditVersion,
          ),
          const SizedBox(height: AppSpacing.lg),
          PlaySessionsSection(
            stats: stats,
            loading: statsLoading,
            launchPath: game.launchPath,
            onPickLaunchEntry: onPickLaunchEntry,
          ),
          const SizedBox(height: AppSpacing.lg),
          LibraryActions(
            hasInstallPath: hasPath,
            onOpenFolder: onOpenFolder,
            onLaunch: onLaunch,
            onRemove: onRemove,
          ),
        ],
      ),
      sections: [
        if (game.screens.isNotEmpty)
          InfoSection(
            title: t.detail.screenshots,
            child: ScreenshotGallery(
              cover: cover,
              screens: game.screens,
              cacheManager: cacheManager,
            ),
          ),
        if (game.tags.isNotEmpty)
          InfoSection(title: t.detail.tags, child: TagChips(tags: game.tags)),
        if (game.description.trim().isNotEmpty)
          InfoSection(
            title: t.detail.description,
            child: Text(game.description),
          ),
      ],
    );
  }
}
