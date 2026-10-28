import 'package:flutter/material.dart';

import '../domain/ports.dart';
import '../i18n/i18n.dart';

/// A single-select sort chooser rendered inside a bottom sheet (ticket 22).
///
/// Lists the five server-side sort orders (date/likes/views/title/rating) and
/// reports the tapped choice via [onSelected]; the caller closes the sheet.
class SortSheet extends StatelessWidget {
  const SortSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  /// The currently active sort order (shown with a check).
  final SortOrder current;

  /// Invoked with the tapped sort order.
  final ValueChanged<SortOrder> onSelected;

  static String _label(Translations t, SortOrder order) => switch (order) {
        SortOrder.date => t.sort.date,
        SortOrder.likes => t.sort.likes,
        SortOrder.views => t.sort.views,
        SortOrder.title => t.sort.title,
        SortOrder.rating => t.sort.rating,
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
          for (final order in SortOrder.values)
            ListTile(
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
