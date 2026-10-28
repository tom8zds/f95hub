import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library_filter.dart';
import '../domain/library_sort.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/detail_tabs.dart';
import '../state/library.dart';
import '../state/library_view.dart';
import '../widgets/game_grid.dart';
import '../widgets/import_game_dialog.dart';
import '../widgets/detail_pane.dart';
import '../widgets/library_detail.dart';
import '../widgets/library_filter_drawer.dart';
import '../widgets/library_sort_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_frame.dart';
import '../widgets/search_field.dart';
import '../widgets/skeleton.dart';
import 'directory_import_page.dart';
import 'library_detail_page.dart';

/// The local library: every game that has been scraped into the store.
///
/// Lists the games in a [GameGrid] (reusing the listing's card), flags the ones
/// the catalogue reports as outdated, and narrows the grid by title, tags and
/// update state. Search lives in the AppBar title, 过滤器 opens a right end
/// drawer and 排序 opens a bottom sheet (ticket 58), matching the games page.
/// Still offers the manual import flows.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.leading});

  /// Optional leading widget for the page's title bar (a drawer hamburger in
  /// the shell's narrow layout).
  final Widget? leading;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  /// Key to the page's [Scaffold], used to open the filter end drawer.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Focuses the AppBar search field (Ctrl+F).
  final FocusNode _searchFocus = FocusNode();

  LibraryFilter _filter = const LibraryFilter();
  LibrarySortOrder _sort = LibrarySortOrder.updated;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(libraryProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final dir = await ref.read(directoryPickerProvider)();
    if (dir == null || dir.isEmpty || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => ImportGameDialog(installPath: dir),
    );
  }

  Future<void> _importFromDirectory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DirectoryImportPage()),
    );
  }

  /// Opens the 过滤器 end drawer hosting [LibraryFilterDrawer].
  void _openFilters() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  /// Opens the 排序 bottom sheet listing the library's sort orders.
  void _openSort() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => LibrarySortSheet(
        current: _sort,
        onSelected: (order) => setState(() => _sort = order),
      ),
    );
  }

  void _setQuery(String query) {
    setState(() => _filter = _filter.copyWith(query: query));
  }

  void _toggleTag(String tag) {
    final tags = {..._filter.tags};
    if (!tags.remove(tag)) {
      tags.add(tag);
    }
    setState(() => _filter = _filter.copyWith(tags: tags));
  }

  void _setOnlyUpdates(bool onlyUpdates) {
    setState(() => _filter = _filter.copyWith(onlyUpdates: onlyUpdates));
  }

  /// Whether the latest layout pass was wide enough for the grid + detail
  /// pane split (set during [build]).
  bool _dual = false;

  /// Opens [game]'s complete detail: a right-hand pane tab on wide windows,
  /// a modal dialog without leaving the grid otherwise.
  void _open(Game game) {
    if (_dual) {
      ref.read(detailTabsProvider(DetailPaneScope.library).notifier).open(game);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LibraryDetailPage(game: game)),
    );
  }

  /// Desktop context menu for a library card (right-click).
  Future<void> _openCardMenu(Game game, Offset position) async {
    final t = context.t;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
      items: [
        PopupMenuItem(
          key: Key('library-card-menu-detail-${game.threadId}'),
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
          value: 'openFolder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18),
              const SizedBox(width: 8),
              Text(t.buttons.openFolder),
            ],
          ),
        ),
      ],
    );
    if (action == 'openFolder') {
      ref.read(libraryProvider.notifier).openFolder(game);
    } else if (action == 'detail' && mounted) {
      _open(game);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    // The update flags arrive asynchronously from the catalogue index; while
    // they load, show the plain games so the grid never flashes empty.
    final entries =
        ref.watch(libraryEntriesProvider).value ??
        [for (final game in state.games) LibraryEntry(game: game)];
    final body = _body(state, entries);
    final tabs = ref.watch(detailTabsProvider(DetailPaneScope.library));

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
          endDrawer: LibraryFilterDrawer(
            tagOptions: libraryTagOptions(state.games),
            selectedTags: _filter.tags,
            onTagToggled: _toggleTag,
            onlyUpdates: _filter.onlyUpdates,
            onOnlyUpdatesChanged: _setOnlyUpdates,
          ),
          leading: widget.leading,
          titleWidget: SearchField(
            fieldKey: const Key('library-search-field'),
            focusNode: _searchFocus,
            hintText: context.t.library.searchHint,
            onChanged: _setQuery,
          ),
          loading: state.loading,
          actions: [
            IconButton(
              key: const Key('library-import-folder-button'),
              onPressed: _import,
              icon: const Icon(Icons.create_new_folder),
              tooltip: context.t.library.importFolder,
            ),
            IconButton(
              key: const Key('library-import-directory-button'),
              onPressed: _importFromDirectory,
              icon: const Icon(Icons.folder_copy),
              tooltip: context.t.library.importFromDirectory,
            ),
            IconButton(
              key: const Key('library-filter-button'),
              onPressed: _openFilters,
              // Active-filter count, so the drawer's state is visible at a
              // glance.
              icon: Badge.count(
                count: _filter.tags.length + (_filter.onlyUpdates ? 1 : 0),
                isLabelVisible: _filter.tags.isNotEmpty || _filter.onlyUpdates,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: context.t.library.filters,
            ),
            IconButton(
              key: const Key('library-sort-button'),
              onPressed: _openSort,
              icon: const Icon(Icons.sort),
              tooltip: context.t.library.sort,
            ),
          ],
          child: body,
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
        return Row(
          children: [
            Expanded(child: listFrame),
            SizedBox(
              width: kDetailPaneWidth,
              child: DetailTabsPane(
                scope: DetailPaneScope.library,
                tabBuilder: (game) => LibraryDetailPaneTab(
                  game: game,
                  onClose: () => ref
                      .read(detailTabsProvider(DetailPaneScope.library).notifier)
                      .close(game.threadId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(LibraryState state, List<LibraryEntry> entries) {
    if (state.loading && state.games.isEmpty) {
      return const SkeletonGrid();
    }
    if (state.error != null && state.games.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: context.t.library.loadFailed,
        actionLabel: context.t.common.retry,
        onAction: () => ref.read(libraryProvider.notifier).refresh(),
      );
    }
    if (state.games.isEmpty) {
      return EmptyState(
        icon: Icons.library_books,
        title: context.t.library.empty,
      );
    }
    final visible = sortLibrary(filterLibrary(entries, _filter), _sort);
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: context.t.common.noMatches,
      );
    }
    return LibraryView(
      entries: visible,
      onTap: _open,
      onCardMenu: _openCardMenu,
    );
  }
}

/// The library grid, extracted for isolated rendering/golden preview.
class LibraryView extends StatelessWidget {
  const LibraryView({
    super.key,
    required this.entries,
    this.onTap,
    this.onCardMenu,
  });

  final List<LibraryEntry> entries;
  final ValueChanged<Game>? onTap;

  /// Opens the desktop context menu for a card (right-click).
  final void Function(Game game, Offset position)? onCardMenu;

  @override
  Widget build(BuildContext context) {
    final updates = {
      for (final entry in entries) entry.game.threadId: entry.hasUpdate,
    };
    return GameGrid(
      games: [for (final entry in entries) entry.game],
      hasUpdate: (game) => updates[game.threadId] ?? false,
      onTap: onTap,
      onSecondaryTapUp: onCardMenu,
    );
  }
}
