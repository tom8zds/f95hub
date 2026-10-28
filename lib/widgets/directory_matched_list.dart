import 'package:flutter/material.dart';

import '../domain/scraper.dart';
import '../i18n/i18n.dart';
import '../state/directory_import.dart';
import 'cover_image.dart';
import 'import_item_status.dart';

/// The right pane of the directory import: matched candidates queued for
/// import, each with the matched game title/version, its progress, a
/// change-match action and a remove action (which sends it back to the left
/// pane).
class DirectoryMatchedList extends StatelessWidget {
  const DirectoryMatchedList({
    super.key,
    required this.items,
    required this.onChangeMatch,
    required this.onRemove,
    required this.onCancel,
  });

  final List<ImportItem> items;

  /// Opens the game picker to replace the current match.
  final ValueChanged<ImportItem> onChangeMatch;

  /// Moves the item back to the left pane, clearing its match.
  final ValueChanged<ImportItem> onRemove;

  /// Cancels the in-flight move.
  final ValueChanged<ImportItem> onCancel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(context.t.import.rightEmpty));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) => _MatchedTile(
        item: items[index],
        onChangeMatch: () => onChangeMatch(items[index]),
        onRemove: () => onRemove(items[index]),
        onCancel: () => onCancel(items[index]),
      ),
    );
  }
}

class _MatchedTile extends StatelessWidget {
  const _MatchedTile({
    required this.item,
    required this.onChangeMatch,
    required this.onRemove,
    required this.onCancel,
  });

  static const double _coverWidth = 72;

  final ImportItem item;
  final VoidCallback onChangeMatch;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matched = item.matchedGame;
    final parsed = parseFolderName(item.name);
    final title = matched?.title ?? parsed.title;
    final version =
        (matched != null && matched.latestVersion.isNotEmpty)
            ? matched.latestVersion
            : parsed.version;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _coverWidth,
              height: _coverWidth,
              child: CoverImage(url: item.game?.cover ?? matched?.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? item.name : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    version.isEmpty ? '—' : version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.phase != ImportItemPhase.pending) ...[
                    const SizedBox(height: 6),
                    ImportItemStatus(item: item, onCancel: onCancel),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onChangeMatch,
              icon: const Icon(Icons.swap_horiz),
              tooltip: context.t.import.changeMatch,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: context.t.buttons.remove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
