import 'package:flutter/material.dart';

import '../domain/library_sort.dart';
import '../i18n/i18n.dart';

/// A single-select sort chooser for the local library, rendered inside a
/// bottom sheet (ticket 58).
///
/// Mirrors the games listing's [SortSheet], but over the library's local
/// orders (recently updated / recently added / title) instead of f95zone's
/// server-side ones. The caller closes the sheet.
class LibrarySortSheet extends StatelessWidget {
  const LibrarySortSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  /// The currently active sort order (shown with a check).
  final LibrarySortOrder current;

  /// Invoked with the tapped sort order.
  final ValueChanged<LibrarySortOrder> onSelected;

  static String _label(Translations t, LibrarySortOrder order) =>
      switch (order) {
        LibrarySortOrder.updated => t.library.sortUpdated,
        LibrarySortOrder.added => t.library.sortAdded,
        LibrarySortOrder.title => t.library.sortTitle,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(t.sort.heading, style: theme.textTheme.titleMedium),
          ),
          for (final order in LibrarySortOrder.values)
            ListTile(
              key: Key('library-sort-${order.name}'),
              selected: order == current,
              title: Text(_label(t, order)),
              trailing: order == current ? const Icon(Icons.check) : null,
              onTap: () {
                onSelected(order);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
