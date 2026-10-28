import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library_filter.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/game_index.dart';
import '../state/library.dart';
import '../state/library_view.dart';
import '../theme/tokens.dart';
import '../widgets/format.dart';
import '../widgets/page_frame.dart';

/// The dashboard: an at-a-glance overview with quick access into the app.
///
/// Layout follows the "personal hub" reference: an asymmetric grid of big
/// expressive cards (28dp corners) — a colored hero card for the library, a
/// stats card with large numbers, two accent tiles, and a quick-access row —
/// all colored from the active theme's containers so every preset and both
/// brightness modes stay coherent.
///
/// Shown as the shell's first destination; every number reads a provider the
/// app already maintains, so the stats are always live.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, this.leading, this.onOpenDestination});

  /// Optional leading widget for the page's title bar (a drawer hamburger in
  /// the shell's narrow layout).
  final Widget? leading;

  /// Opens a shell destination (0 dashboard … 4 settings), used by the hero
  /// card and quick-access tiles.
  final ValueChanged<int>? onOpenDestination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final entries =
        ref.watch(libraryEntriesProvider).value ??
        [for (final game in library.games) LibraryEntry(game: game)];
    final index = ref.watch(gameIndexProvider);
    final playtime =
        ref.watch(libraryPlaytimeProvider).value ?? const LibraryPlaytime();

    final updates = entries.where((e) => e.hasUpdate).length;

    Widget left = _HeroCard(
      libraryCount: library.games.length,
      updates: updates,
      onOpen: () => onOpenDestination?.call(2),
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        _StatsCard(playtime: playtime),
        _AccentCard(
          key: const Key('dashboard-card-index'),
          icon: Icons.storage,
          value: '${index.count}',
          label: context.t.dashboard.gameIndex,
          subtitle: index.lastUpdated == null
              ? context.t.dashboard.never
              : context.t.dashboard.lastUpdated(
                  time: _formatDate(index.lastUpdated!),
                ),
          container: false,
          onTap: () => onOpenDestination?.call(3),
        ),
        _QuickAccessCard(onOpenDestination: onOpenDestination),
      ],
    );

    return PageFrame(
      leading: leading,
      title: context.t.nav.dashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                left,
                const SizedBox(height: AppSpacing.md),
                right,
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(flex: 5, child: left),
                    Expanded(flex: 6, child: right),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime at) =>
      '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
}

/// The library hero: a big colored card (primary container) with the
/// collection size, a one-line subtitle and a jump-in button.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.libraryCount,
    required this.updates,
    required this.onOpen,
  });

  final int libraryCount;
  final int updates;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = scheme.onPrimaryContainer;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.cardXL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('dashboard-hero'),
        onTap: onOpen,
        child: Stack(
          fit: StackFit.loose,
          children: [
            // Oversized decorative glyph anchored bottom-right.
            Positioned(
              right: -16,
              bottom: -20,
              child: Icon(
                Icons.sports_esports_outlined,
                size: 160,
                color: foreground.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: foreground, size: 22),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.t.nav.library,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.t.dashboard.manageLibrary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$libraryCount',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.t.dashboard.libraryGames,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      if (updates > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: foreground.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$updates ${context.t.dashboard.updatesAvailable}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      _RoundAction(
                        icon: Icons.arrow_forward,
                        onTap: onOpen,
                        foreground: foreground,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular action button used on the cards.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: foreground.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

/// The stats card: two big numbers side by side on a tonal surface.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.playtime});

  final LibraryPlaytime playtime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.cardXL),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BigStat(
              icon: Icons.timer_outlined,
              value: formatPlaytime(playtime.total),
              label: context.t.dashboard.playTime,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _BigStat(
              icon: Icons.sports_esports_outlined,
              value: '${playtime.gamesPlayed}',
              label: context.t.dashboard.gamesPlayed,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// An accent tile: icon, big value, label (and optional subtitle), tappable.
class _AccentCard extends StatelessWidget {
  const _AccentCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.container = true,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;

  /// True paints a colored container (tertiary); false stays tonal neutral.
  final bool container;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = container
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHigh;
    final fg = container ? scheme.onTertiaryContainer : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.cardXL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: fg, size: 22),
                  Icon(
                    Icons.arrow_outward,
                    size: 16,
                    color: fg.withValues(alpha: 0.5),
                  ),
                ],
              ),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: 0.8),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-access row: a tonal card with three destinations (browse, downloads,
/// settings).
class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.onOpenDestination});

  final ValueChanged<int>? onOpenDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = context.t;
    final tiles = <(IconData, String, int)>[
      (Icons.explore_outlined, t.nav.games, 1),
      (Icons.settings_outlined, t.nav.settings, 3),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.cardXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              t.dashboard.quickAccess,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              for (final (icon, label, index) in tiles)
                Expanded(
                  child: InkWell(
                    key: Key('dashboard-tile-$index'),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => onOpenDestination?.call(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        spacing: 6,
                        children: [
                          Icon(icon, color: scheme.primary),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
