import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

/// Which page's right-hand detail pane a tab set belongs to (each page keeps
/// its own tabs).
enum DetailPaneScope { games, library }

/// Immutable tab-strip state of one detail pane.
class DetailTabsState {
  const DetailTabsState({this.tabs = const [], this.activeThreadId});

  /// Open tabs, oldest first.
  final List<Game> tabs;

  /// The [Game.threadId] shown in the pane; null when no tabs are open.
  final int? activeThreadId;

  Game? get active {
    final id = activeThreadId;
    for (final game in tabs) {
      if (game.threadId == id) {
        return game;
      }
    }
    return null;
  }

  bool get isEmpty => tabs.isEmpty;

  DetailTabsState copyWith({List<Game>? tabs, int? activeThreadId}) {
    return DetailTabsState(
      tabs: tabs ?? this.tabs,
      activeThreadId: activeThreadId ?? this.activeThreadId,
    );
  }
}

/// Drives a right-hand detail pane's tabs: opening a game activates its tab
/// (or appends one), closing picks a neighbour, and everything can be closed
/// at once to collapse the pane.
class DetailTabsController extends Notifier<DetailTabsState> {
  DetailTabsController(this.scope);

  /// The page this tab strip belongs to.
  final DetailPaneScope scope;

  @override
  DetailTabsState build() => const DetailTabsState();

  /// Shows [game]: activates its tab when one is already open, otherwise
  /// appends a new tab and activates it.
  void open(Game game) {
    final tabs = state.tabs;
    final existing = tabs.any((t) => t.threadId == game.threadId);
    state = DetailTabsState(
      tabs: existing ? tabs : [...tabs, game],
      activeThreadId: game.threadId,
    );
  }

  /// Activates the tab for [threadId] (no-op when not open).
  void activate(int threadId) {
    if (!state.tabs.any((t) => t.threadId == threadId)) {
      return;
    }
    state = state.copyWith(activeThreadId: threadId);
  }

  /// Closes the tab for [threadId]; when it was active the neighbour to its
  /// left becomes active (else the right neighbour, else nothing).
  void close(int threadId) {
    final tabs = state.tabs;
    final index = tabs.indexWhere((t) => t.threadId == threadId);
    if (index < 0) {
      return;
    }
    final remaining = [...tabs]..removeAt(index);
    int? nextActive = state.activeThreadId;
    if (nextActive == threadId) {
      nextActive = remaining.isEmpty
          ? null
          : remaining[(index - 1).clamp(0, remaining.length - 1)].threadId;
    }
    state = DetailTabsState(tabs: remaining, activeThreadId: nextActive);
  }

  /// Closes every tab, collapsing the pane.
  void closeAll() {
    state = const DetailTabsState();
  }
}

/// The tab state of the [scope] page's right-hand detail pane.
final detailTabsProvider =
    NotifierProvider.family<DetailTabsController, DetailTabsState,
        DetailPaneScope>(DetailTabsController.new);
