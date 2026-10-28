import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/detail_tabs.dart';
import '../theme/tokens.dart';

/// Width at or above which the games/library pages split into
/// list + right-hand detail pane.
const double kDualPaneBreakpoint = 1000;

/// The right-hand pane's width in the dual layout.
const double kDetailPaneWidth = 560;

/// The right-hand side of the dual layout: a scrollable tab strip over every
/// opened detail, plus the active tab's content.
///
/// Content widgets are hosted in an [IndexedStack] keyed by thread id, so
/// switching tabs does not reload a detail (per-thread providers keep their
/// state and each tab's element stays alive).
///
/// [tabBuilder] builds one tab's content; the pane is hidden (zero size) when
/// no tabs are open, so the page collapses back to a single column.
class DetailTabsPane extends ConsumerWidget {
  const DetailTabsPane({
    super.key,
    required this.scope,
    required this.tabBuilder,
  });

  /// Which page's tab strip this pane shows.
  final DetailPaneScope scope;

  /// Builds the content for one open tab.
  final Widget Function(Game game) tabBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detailTabsProvider(scope));
    if (state.isEmpty) {
      return const SizedBox.shrink();
    }
    final activeIndex = state.tabs.indexWhere(
      (t) => t.threadId == state.activeThreadId,
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppRadius.cardXL),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TabStrip(scope: scope, tabs: state.tabs, activeIndex: activeIndex),
          Expanded(
            child: IndexedStack(
              index: activeIndex.clamp(0, state.tabs.length - 1),
              children: [
                for (final game in state.tabs)
                  KeyedSubtree(
                    key: ValueKey('detail-tab-${game.threadId}'),
                    child: tabBuilder(game),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One scrollable row of pill-shaped tab chips: title (activate on tap,
/// ellipsized) plus a per-tab close button and a trailing collapse-all button.
///
/// Keeps the active tab in view and shows a `<<`/`>>` hint at an edge when
/// chips are hidden beyond it.
class _TabStrip extends ConsumerStatefulWidget {
  const _TabStrip({
    required this.scope,
    required this.tabs,
    required this.activeIndex,
  });

  final DetailPaneScope scope;
  final List<Game> tabs;
  final int activeIndex;

  @override
  ConsumerState<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends ConsumerState<_TabStrip> {
  static const double _stripHeight = 44;
  static const double _chipHeight = 32;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _activeKey = GlobalKey();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncHints);
    _afterLayout();
  }

  @override
  void didUpdateWidget(covariant _TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex ||
        oldWidget.tabs.length != widget.tabs.length) {
      _afterLayout();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _afterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealActive();
      _syncHints();
    });
  }

  void _revealActive() {
    final activeContext = _activeKey.currentContext;
    if (activeContext == null) return;
    Scrollable.ensureVisible(
      activeContext,
      alignment: 0.5,
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
    );
  }

  void _syncHints() {
    if (!mounted || !_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    final left = _scroll.offset > 0.5;
    final right =
        _scroll.offset + position.viewportDimension <
            position.maxScrollExtent - 0.5;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(detailTabsProvider(widget.scope).notifier);
    return SizedBox(
      height: _stripHeight,
      child: Row(
        children: [
          _scrollButton(
            key: const Key('detail-tabs-scroll-left'),
            icon: Icons.keyboard_double_arrow_left,
            enabled: _canScrollLeft,
            onPressed: () => _page(-1),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 6,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < widget.tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    _tabChip(
                      context,
                      scheme,
                      controller,
                      widget.tabs[i],
                      i == widget.activeIndex,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _scrollButton(
            key: const Key('detail-tabs-scroll-right'),
            icon: Icons.keyboard_double_arrow_right,
            enabled: _canScrollRight,
            onPressed: () => _page(1),
          ),
          IconButton(
            key: const Key('detail-pane-close-all'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            tooltip: context.t.common.close,
            onPressed: controller.closeAll,
          ),
        ],
      ),
    );
  }

  /// Steps the strip by most of a viewport in [direction] (-1 left, 1 right).
  void _page(int direction) {
    if (!_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    final target =
        (_scroll.offset + direction * position.viewportDimension * 0.8).clamp(
          0.0,
          position.maxScrollExtent,
        );
    _scroll.animateTo(
      target,
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
    );
  }

  /// A permanent scroll control beside the strip: disabled (greyed) when the
  /// strip cannot scroll that way, so it never covers the chips.
  Widget _scrollButton({
    required Key key,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18),
      onPressed: enabled ? onPressed : null,
    );
  }

  Widget _tabChip(
    BuildContext context,
    ColorScheme scheme,
    DetailTabsController controller,
    Game game,
    bool active,
  ) {
    return Material(
      key: active ? _activeKey : null,
      color: active ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('detail-tab-chip-${game.threadId}'),
        customBorder: const StadiumBorder(),
        onTap: () => controller.activate(game.threadId),
        child: SizedBox(
          height: _chipHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              _TabCloseIcon(onClose: () => controller.close(game.threadId)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCloseIcon extends StatelessWidget {
  const _TabCloseIcon({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onClose,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.close, size: 14),
      ),
    );
  }
}
