/// Client-side ordering for the local library (ticket 58).
///
/// Pure: no I/O and no Flutter dependencies, so the ordering rules are
/// unit-testable without a widget tree.
library;

import 'library_filter.dart';

/// The sort orders offered by the library page's 排序 sheet.
enum LibrarySortOrder {
  /// Most recently stored game first (`Game.updatedAt`).
  updated,

  /// Most recently added game first (`Game.createdAt`).
  added,

  /// Title A→Z, case-insensitive.
  title,
}

/// Orders [entries] by [order], leaving the input list untouched.
///
/// Ties fall back to the thread id so the result is stable regardless of the
/// order the store returned.
List<LibraryEntry> sortLibrary(
  List<LibraryEntry> entries,
  LibrarySortOrder order,
) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byOrder = switch (order) {
      LibrarySortOrder.updated => b.game.updatedAt.compareTo(a.game.updatedAt),
      LibrarySortOrder.added => b.game.createdAt.compareTo(a.game.createdAt),
      LibrarySortOrder.title => a.game.title.toLowerCase().compareTo(
        b.game.title.toLowerCase(),
      ),
    };
    return byOrder != 0 ? byOrder : a.game.threadId.compareTo(b.game.threadId);
  });
  return sorted;
}
