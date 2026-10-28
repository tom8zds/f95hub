import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import 'format.dart';

/// Playtime summary for a library game: total time, the remembered launch
/// entry, and every recorded session (started/ended/duration).
///
/// Pure presentation — stats and callbacks are injected so the section renders
/// in isolation for a golden preview and the page owns scanning/persistence.
class PlaySessionsSection extends StatelessWidget {
  const PlaySessionsSection({
    super.key,
    this.stats = const PlayStats(),
    this.launchPath,
    this.onPickLaunchEntry,
    this.loading = false,
  });

  final PlayStats stats;
  final String? launchPath;

  /// Opens the launch-entry picker; null disables the button (no install path).
  final VoidCallback? onPickLaunchEntry;

  /// Whether the stats are still loading (shown instead of the session list).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLaunchPath = launchPath != null && launchPath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.t.library.playTime, style: theme.textTheme.titleMedium),
            const Spacer(),
            // Flexible so the total wraps instead of overflowing narrow
            // sidebars.
            Flexible(
              child: Text(
                context.t.library.totalPlayTime(
                  duration: formatPlaytime(stats.total),
                ),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Label row + value row: a single row would overflow narrow detail
        // sidebars (label, path, and the change button are all fixed-width).
        Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 20,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.t.library.launchEntry,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                hasLaunchPath ? p.basename(launchPath!) : context.t.library.noLaunchEntry,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (onPickLaunchEntry != null)
              // Flexible so an oversized label wraps instead of overflowing
              // the sidebar.
              Flexible(
                child: TextButton(
                  onPressed: onPickLaunchEntry,
                  child: Text(
                    hasLaunchPath
                        ? context.t.library.changeLaunchEntry
                        : context.t.library.chooseLaunchEntry,
                  ),
                ),
              ),
          ],
        ),
        const Divider(height: 24),
        Text(
          context.t.library.playSessions,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (loading)
          const LinearProgressIndicator()
        else if (stats.sessions.isEmpty)
          Text(
            context.t.library.noPlaySessions,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          for (final session in stats.sessions)
            _SessionRow(key: ValueKey(session.id), session: session),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({super.key, required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );
    final endedAt = session.endedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDateTime(session.startedAt)),
                Text(
                  endedAt == null
                      ? context.t.library.inProgress
                      : '→ ${formatDateTime(endedAt)}',
                  style: muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            session.duration == null
                ? '—'
                : formatPlaytime(session.duration!),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
