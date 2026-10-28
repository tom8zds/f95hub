import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ports.dart';
import '../i18n/i18n.dart';
import '../state/detail_tabs.dart';
import '../state/game_list.dart';
import '../widgets/add_game_to_library.dart';
import '../widgets/open_in_browser_button.dart';
import '../widgets/detail_pane.dart';
import '../widgets/game_filters.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/game_grid.dart';
import '../widgets/page_frame.dart';
import '../widgets/page_controls.dart';
import '../widgets/search_field.dart';
import '../widgets/skeleton.dart';
import '../widgets/sort_sheet.dart';
import 'game_detail_page.dart';

/// The f95zone games listing: covers/titles/versions with server-side sort,
/// a paged footer (上一页/下一页), and a local title filter.
///
/// Search lives in the AppBar title; 过滤器 opens a right end drawer (ticket
/// 25) and 排序 opens a bottom sheet (ticket 22).
class GamesPage extends ConsumerStatefulWidget {
  const GamesPage({super.key, this.leading});

  /// Optional leading widget for the page's title bar (a drawer hamburger in
  /// the shell's narrow layout).
  final Widget? leading;

  @override
  ConsumerState<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends ConsumerState<GamesPage> {
  /// Key to the page's [Scaffold], used to open the filter end drawer.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Focuses the AppBar search field (Ctrl+F).
  final FocusNode _searchFocus = FocusNode();

  /// Scrolls the games grid; reset when the page changes.
  final ScrollController _gridScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gameListProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  /// Opens the 过滤器 end drawer hosting [GameFilters].
  void _openFilters() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  /// Opens the 排序 bottom sheet listing the sort orders.
  void _openSort(SortOrder current, GameListController notifier) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SortSheet(current: current, onSelected: notifier.setSort),
    );
  }

  /// Resets the grid's scroll offset when the page changes so the new page
  /// starts at the top.
  void _scrollTop() {
    if (_gridScroll.hasClients) {
      _gridScroll.jumpTo(0);
    }
  }

  /// Desktop context menu for a game card (right-click).
  Future<void> _openCardMenu(Game game, Offset position) async {
    final t = context.t;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
      items: [
        PopupMenuItem(
          key: Key('card-menu-detail-${game.threadId}'),
          value: 'detail',
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Text(t.common.viewDetail),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add',
          child: Row(
            children: [
              const Icon(Icons.library_add, size: 18),
              const SizedBox(width: 8),
              Text(t.buttons.addToLibrary),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'detail':
        _openDetail(game);
      case 'add':
        addGameToLibrary(context, ref, game);
    }
  }

  /// Whether the latest layout pass was wide enough for the list + detail
  /// pane split (set during [build]).
  bool _dual = false;

  /// Opens a game's detail: a right-hand pane tab on wide windows, a pushed
  /// page otherwise.
  void _openDetail(Game game) {
    if (_dual) {
      ref.read(detailTabsProvider(DetailPaneScope.games).notifier).open(game);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GameDetailPage(game: game)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameListProvider);
    final notifier = ref.read(gameListProvider.notifier);
    final tabs = ref.watch(detailTabsProvider(DetailPaneScope.games));

    final list = Column(
      children: [
        if (state.throttled)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top, size: 16),
                const SizedBox(width: 6),
                Text(
                  context.t.games.throttled,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _Listing(
            state: state,
            controller: _gridScroll,
            onCardMenu: _openCardMenu,
            onOpenDetail: _openDetail,
          ),
        ),
        if (state.totalPages > 0)
          SizedBox(
            height: kToolbarHeight,
            child: PageControls(
              page: state.page,
              totalPages: state.totalPages,
              onPrev: () {
                notifier.prevPage();
                _scrollTop();
              },
              onNext: () {
                notifier.nextPage();
                _scrollTop();
              },
            ),
          ),
      ],
    );

    final listFrame = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _searchFocus.requestFocus(),
      },
      // Autofocus lands on a node INSIDE CallbackShortcuts, so key events
      // bubble through it and Ctrl+F works before the user clicks anywhere.
      child: Focus(
        autofocus: true,
        child: PageFrame(
          scaffoldKey: _scaffoldKey,
          endDrawer: FilterDrawer(),
          leading: widget.leading,
          titleWidget: SearchField(
            fieldKey: const Key('games-search-field'),
            focusNode: _searchFocus,
            hintText: context.t.games.searchHint,
            onChanged: notifier.setQuery,
          ),
          loading: state.loading,
          actions: [
            IconButton(
              key: const Key('games-refresh-button'),
              icon: const Icon(Icons.refresh),
              tooltip: context.t.games.refresh,
              onPressed: state.loading ? null : notifier.refresh,
            ),
            IconButton(
              key: const Key('games-filter-button'),
              // Active-filter count, so the drawer's state is visible at a
              // glance.
              icon: Badge.count(
                count:
                    state.selectedTags.length +
                    state.selectedPrefixes.length +
                    (state.date != null ? 1 : 0),
                isLabelVisible:
                    state.selectedTags.isNotEmpty ||
                    state.selectedPrefixes.isNotEmpty ||
                    state.date != null,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: context.t.games.filters,
              onPressed: _openFilters,
            ),
            IconButton(
              key: const Key('games-sort-button'),
              icon: const Icon(Icons.sort),
              tooltip: context.t.games.sort,
              onPressed: () => _openSort(state.sort, notifier),
            ),
          ],
          child: list,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Constraint-based (not window-based): the split follows the space this
        // page actually has.
        final dual = constraints.maxWidth >= kDualPaneBreakpoint;
        _dual = dual;
        if (!dual || tabs.isEmpty) {
          return listFrame;
        }
        // The pane spans the full height beside the title bar and matches the
        // navigation drawer's panel styling.
        return Row(
          children: [
            Expanded(child: listFrame),
            SizedBox(
              width: kDetailPaneWidth,
              child: DetailTabsPane(
                scope: DetailPaneScope.games,
                tabBuilder: (game) => _GamesPaneTab(game: game),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The scrollable content: grid of games, or skeleton / error / empty states.
class _Listing extends ConsumerWidget {
  const _Listing({
    required this.state,
    this.controller,
    this.onCardMenu,
    this.onOpenDetail,
  });

  final GameListState state;

  /// Scroll controller for the grid (the page resets it on page changes).
  final ScrollController? controller;

  /// Opens the desktop context menu for a card (right-click).
  final void Function(Game game, Offset position)? onCardMenu;

  /// Opens a game's detail (pane tab on wide windows, route otherwise).
  final ValueChanged<Game>? onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading && state.games.isEmpty) {
      // Skeleton tiles preview the grid geometry instead of a bare spinner.
      return const SkeletonGrid();
    }
    if (state.error != null && state.games.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: context.t.games.loadFailed,
        actionLabel: context.t.common.retry,
        onAction: () => ref.read(gameListProvider.notifier).load(),
      );
    }

    final games = state.filteredGames;
    if (games.isEmpty) {
      return EmptyState(
        icon: state.query.isEmpty ? Icons.videogame_asset : Icons.search_off,
        title: context.t.games.empty,
      );
    }

    return GameGrid(
      games: games,
      controller: controller,
      onTap: onOpenDetail,
      onSecondaryTapUp: onCardMenu,
    );
  }
}

/// One games-pane tab: the shared detail content with the 加入库 action on
/// top.
class _GamesPaneTab extends StatelessWidget {
  const _GamesPaneTab({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent so the pane's rounded panel background shows through.
      backgroundColor: Colors.transparent,
      body: GameDetailContent(game: game),
      floatingActionButton: OpenInBrowserButton(game: game),
    );
  }
}
