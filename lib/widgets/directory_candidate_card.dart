import 'package:flutter/material.dart';

import '../domain/scraper.dart';
import '../i18n/i18n.dart';
import '../state/directory_import.dart';
import 'cover_image.dart';
import 'import_item_status.dart';

/// One scanned candidate directory in the directory-import left pane: a cover
/// (placeholder before matching), the parsed title and version, the local path,
/// and a state-dependent progress/status display with a cancel action while
/// moving.
///
/// Tapping the card selects it ([onSelect]); selection is single-item, so there
/// is no checkbox.
class DirectoryCandidateCard extends StatelessWidget {
  const DirectoryCandidateCard({
    super.key,
    required this.item,
    required this.onSelect,
    required this.onCancel,
  });

  final ImportItem item;

  /// Taps the card: matches the candidate and moves it to the right pane.
  final VoidCallback onSelect;

  /// Cancels the in-flight move.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = parseFolderName(item.name);
    final matched = item.matchedGame;
    final title = matched != null
        ? matched.title
        : (parsed.title.isNotEmpty ? parsed.title : item.name);
    final version = matched != null && matched.latestVersion.isNotEmpty
        ? matched.latestVersion
        : parsed.version;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CoverImage(url: item.game?.cover ?? matched?.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            version.isEmpty ? '—' : version,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _MatchBadge(matched: matched != null),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    ImportItemStatus(item: item, onCancel: onCancel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the candidate is matched to a cached catalogue game.
class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.matched});

  final bool matched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = matched ? Colors.green : theme.colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(matched ? Icons.link : Icons.link_off, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          matched ? context.t.import.matched : context.t.import.noMatch,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
