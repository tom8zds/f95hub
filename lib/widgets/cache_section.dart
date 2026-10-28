import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/i18n.dart';
import '../state/game_index.dart';
import 'settings_section.dart';

/// Settings block for the local game index: how many games are cached, when it
/// was last refreshed, and the build/refresh/clear actions.
///
/// Presentational: [CacheSettingsSection] wires it to the game index provider.
class CacheSection extends StatelessWidget {
  const CacheSection({
    super.key,
    required this.count,
    required this.lastUpdated,
    required this.busy,
    required this.page,
    required this.total,
    required this.lastBuiltPage,
    required this.totalPages,
    required this.error,
    required this.onBuild,
    required this.onRefresh,
    required this.onClear,
    required this.onCancel,
  });

  /// Cached row count.
  final int count;

  /// When the index was last built/refreshed; null when never built.
  final DateTime? lastUpdated;

  /// True while a build/refresh runs.
  final bool busy;

  /// Progress of the running operation (1-based page and page count).
  final int page;
  final int total;

  /// Last page a full build finished writing and the total it saw; equal when
  /// the cache is complete.
  final int lastBuiltPage;
  final int totalPages;

  /// The last cache operation's error, if any.
  final Object? error;

  final VoidCallback onBuild;
  final VoidCallback onRefresh;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    final last = lastUpdated;
    final incomplete = totalPages > 0 && lastBuiltPage < totalPages;
    final resumable = incomplete && lastBuiltPage > 0;

    return SettingsSection(
      title: t.cache.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, size: 18),
              const SizedBox(width: 8),
              Text(
                t.cache.gamesCached(n: count),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            last == null
                ? t.cache.lastUpdatedNever
                : t.cache.lastUpdated(date: _format(last)),
            style: theme.textTheme.bodySmall?.copyWith(color: outline),
          ),
          if (!busy && incomplete) ...[
            const SizedBox(height: 4),
            Text(
              t.cache.reached(
                page: lastBuiltPage,
                total: totalPages,
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: outline),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? page / total : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    total > 0
                        ? t.cache.page(page: page, total: total)
                        : t.cache.fetchingPageCount,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: Text(t.common.cancel),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              t.cache.failed(error: error!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onBuild,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(
                  resumable ? t.buttons.continueBuild : t.buttons.createCache,
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy || count == 0 ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(t.buttons.refreshCache),
              ),
              OutlinedButton.icon(
                onPressed: busy || (count == 0 && lastBuiltPage == 0)
                    ? null
                    : onClear,
                icon: const Icon(Icons.delete_outline),
                label: Text(t.buttons.deleteCache),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)} '
        '${two(at.hour)}:${two(at.minute)}';
  }
}

/// [CacheSection] wired to the game index controller; loads the current count
/// and last-updated stamp when it first appears.
class CacheSettingsSection extends ConsumerStatefulWidget {
  const CacheSettingsSection({super.key});

  @override
  ConsumerState<CacheSettingsSection> createState() =>
      _CacheSettingsSectionState();
}

class _CacheSettingsSectionState extends ConsumerState<CacheSettingsSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gameIndexProvider.notifier).loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameIndexProvider);
    final controller = ref.read(gameIndexProvider.notifier);

    return CacheSection(
      count: state.count,
      lastUpdated: state.lastUpdated,
      busy: state.busy,
      page: state.page,
      total: state.total,
      lastBuiltPage: state.lastBuiltPage,
      totalPages: state.totalPages,
      error: state.error,
      onBuild: controller.buildAll,
      onRefresh: controller.refreshIncremental,
      onClear: controller.clear,
      onCancel: controller.cancel,
    );
  }
}
