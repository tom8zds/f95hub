import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ports.dart';
import '../i18n/i18n.dart';
import '../state/game_detail.dart';
import '../theme/tokens.dart';
import '../widgets/open_in_browser_button.dart';
import '../widgets/cover_image.dart';
import '../widgets/detail_layout.dart';
import '../widgets/detail_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_section.dart';
import '../widgets/meta_list.dart';
import '../widgets/screenshot_gallery.dart';
import '../widgets/skeleton.dart';
import '../widgets/tag_chips.dart';

/// Game detail: cover, screenshot gallery, tags, category, engine, developer,
/// version and description (the latter scraped from the thread page).
///
/// Hosted full-screen (narrow windows). Wide windows open detail tabs in the
/// page's right-hand pane instead.
class GameDetailPage extends StatelessWidget {
  const GameDetailPage({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: OpenInBrowserButton(game: game),
      body: GameDetailContent(
        game: game,
        showTitle: false,
        topBar: DetailTopBar(title: game.title),
      ),
    );
  }
}

/// The detail content plus its load lifecycle, reusable by the pushed page and
/// the wide layout's right-hand tab pane.
///
/// Loads per-thread state ([gameDetailProvider]/[mirrorListProvider] are
/// family-keyed by thread id, so several of these coexist cleanly).
class GameDetailContent extends ConsumerStatefulWidget {
  const GameDetailContent({
    super.key,
    required this.game,
    this.showTitle = true,
    this.topBar,
  });

  final Game game;

  /// Whether to render the game title in the content header (false when the
  /// hosting route's top bar already shows it).
  final bool showTitle;

  /// Optional pinned bar above the content column (the route's back + title).
  final Widget? topBar;

  @override
  ConsumerState<GameDetailContent> createState() => _GameDetailContentState();
}

class _GameDetailContentState extends ConsumerState<GameDetailContent> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    Future.microtask(
      () => ref.read(gameDetailProvider(widget.game.threadId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final threadId = widget.game.threadId;
    return _body(ref.watch(gameDetailProvider(threadId)));
  }

  Widget _body(GameDetailState state) {
    if (state.loading && state.thread == null) {
      return DetailSkeleton(topBar: widget.topBar);
    }
    if (state.error != null && state.thread == null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: context.t.detail.loadFailed,
        actionLabel: context.t.common.retry,
        onAction: _load,
      );
    }

    final table = state.tagTable ?? const TagTable(tags: {}, prefixes: {});
    final details = resolveGameDetails(widget.game, table);
    return GameDetailView(
      game: widget.game,
      details: details,
      description: state.thread?.description ?? '',
      showTitle: widget.showTitle,
      topBar: widget.topBar,
    );
  }
}

/// The game-detail content: header, sidebar (cover + metadata), and sections.
///
/// Extracted from [GameDetailPage] so it can be rendered in isolation for a
/// golden preview. Wide windows lay it out as two panes via [DetailLayout].
class GameDetailView extends StatelessWidget {
  const GameDetailView({
    super.key,
    required this.game,
    required this.details,
    required this.description,
    this.showTitle = true,
    this.topBar,
  });

  final Game game;
  final ResolvedDetails details;
  final String description;

  /// Whether to render the game title in the content header. The pushed route
  /// shows it in its top bar instead, so it is not duplicated.
  final bool showTitle;

  /// Optional pinned bar above the content column (the route's back + title).
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final developer = game.developer.isNotEmpty ? game.developer : game.creator;
    final version = game.displayVersion;

    return DetailLayout(
      topBar: topBar,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(game.title, style: theme.textTheme.headlineSmall),
            if (developer.isNotEmpty) const SizedBox(height: AppSpacing.xs),
          ],
          if (developer.isNotEmpty)
            Text(
              developer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      sidebar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // f95 covers are wide banners (like the list cards): 16:9, rounded.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CoverImage(url: game.cover),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MetaList(
            entries: [
              MetaEntry(t.detail.version, version),
              MetaEntry(t.detail.category, details.categories.join(', ')),
              MetaEntry(t.detail.engine, details.engines.join(', ')),
              MetaEntry(t.detail.releaseDate, _formatDate(game.createdAt)),
              MetaEntry(t.detail.lastUpdated, _formatDate(game.updatedAt)),
              // The header already shows the creator when no developer exists.
              MetaEntry(
                t.detail.author,
                game.creator == developer ? '' : game.creator,
              ),
            ],
          ),
        ],
      ),
      sections: [
        if (game.screens.isNotEmpty)
          InfoSection(
            title: t.detail.screenshots,
            child: ScreenshotGallery(
              cover: game.cover,
              screens: game.screens,
            ),
          ),
        if (details.tags.isNotEmpty)
          InfoSection(
            title: t.detail.tags,
            child: TagChips(tags: details.tags),
          ),
        if (description.isNotEmpty)
          InfoSection(title: t.detail.description, child: Text(description)),
      ],
    );
  }
}

/// `yyyy-mm-dd`, or empty for a missing (epoch-zero) timestamp so [MetaList]
/// omits the row.
String _formatDate(DateTime at) => at.millisecondsSinceEpoch == 0
    ? ''
    : '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
