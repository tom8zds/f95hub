import 'package:flutter/material.dart';

import '../i18n/i18n.dart';

/// A bottom pagination bar for the games listing: 上一页 / "第 X / Y 页" /
/// 下一页, with each navigation button disabled at its boundary (first/last
/// page). Shown only once a page count is known.
class PageControls extends StatelessWidget {
  const PageControls({
    super.key,
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  /// Current 1-based page.
  final int page;

  /// Total page count reported by the server.
  final int totalPages;

  /// Called when 上一页 is pressed (only enabled past the first page).
  final VoidCallback? onPrev;

  /// Called when 下一页 is pressed (only enabled before the last page).
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirst = page <= 1;
    final isLast = page >= totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            key: const Key('page-prev'),
            onPressed: isFirst ? null : onPrev,
            child: Text(context.t.pagination.previous),
          ),
          SizedBox.fromSize(size: const Size(16, 0)),
          Chip(key: const Key('page-current'), label: Text(page.toString())),
          SizedBox.fromSize(size: const Size(16, 0)),
          Text('/', style: theme.textTheme.bodyLarge),
          SizedBox.fromSize(size: const Size(16, 0)),
          Chip(
            key: const Key('page-total'),
            label: Text(totalPages.toString()),
            padding: const EdgeInsets.all(8),
          ),
          SizedBox.fromSize(size: const Size(16, 0)),
          ElevatedButton(
            key: const Key('page-next'),
            onPressed: isLast ? null : onNext,
            child: Text(context.t.pagination.next),
          ),
        ],
      ),
    );
  }
}
