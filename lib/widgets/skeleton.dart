import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/tokens.dart';
import 'detail_layout.dart';

/// A static skeleton placeholder block.
///
/// Deliberately not animated (no ticker): the pages hosting skeletons pump to
/// quiescence in widget tests, where a repeating shimmer animation would never
/// settle. The tonal block alone reads as "content is coming".
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height, this.radius});

  /// Block width; null stretches to the parent's width constraint.
  final double? width;

  /// Block height; null collapses to the parent's height constraint.
  final double? height;

  /// Corner radius; defaults to [AppRadius.chip].
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.chip),
      ),
    );
  }
}

/// A skeleton shaped like a [GameCard]: 16:9 cover block plus two tag-line
/// blocks, so loading grids preview the exact tile geometry.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(aspectRatio: 16 / 9, child: Skeleton(radius: 0));
  }
}

/// A loading placeholder that mirrors [GameGrid]'s layout: the same delegate
/// (max card width, aspect ratio, gutters) filled with [SkeletonCard]s, so the
/// transition from loading to loaded doesn't reflow.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 12});

  /// How many placeholder tiles to render.
  final int count;

  /// Must match [GameGrid._maxCardWidth] so the column count lines up.
  static const double _maxCardWidth = 300;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _maxCardWidth,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 16 / 9,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

/// A loading placeholder for the two-pane detail layout: a portrait cover and
/// metadata lines in the sidebar, title/gallery/text lines in the content
/// column. Stacks to one column below [kDetailWideBreakpoint].
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key, this.topBar});

  /// Optional pinned bar above the content column, mirroring [DetailLayout].
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(
          aspectRatio: 16 / 9,
          child: Skeleton(radius: AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final w in const [120.0, 96.0, 140.0]) ...[
          Skeleton(height: 10, width: w * 0.6),
          const SizedBox(height: AppSpacing.xs),
          Skeleton(height: 14, width: w),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(height: 24, width: 320),
        const SizedBox(height: AppSpacing.xs),
        const Skeleton(height: 14, width: 160),
        const SizedBox(height: AppSpacing.xl),
        const Skeleton(height: 160, radius: 0),
        const SizedBox(height: AppSpacing.xl),
        for (final w in const [null, 0.9, 0.7]) ...[
          Skeleton(height: 12, width: w == null ? null : 400 * w),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kDetailWideBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: kDetailSidebarWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: sidebar,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (topBar != null) topBar!,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            if (topBar != null) topBar!,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(height: 24, width: 260),
                    const SizedBox(height: AppSpacing.xs),
                    const Skeleton(height: 14, width: 160),
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kDetailSidebarNarrowWidth,
                      ),
                      child: sidebar,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Skeleton(height: 140, radius: 0),
                    const SizedBox(height: AppSpacing.xl),
                    const Skeleton(height: 12),
                    const SizedBox(height: AppSpacing.sm),
                    const Skeleton(height: 12, width: 280),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget previews
// ---------------------------------------------------------------------------

/// Loading grid placeholder preview (mirrors the games/library grid).
@Preview(name: 'Grid', group: 'Skeletons', size: Size(640, 480))
Widget skeletonGridPreview() => const MaterialApp(
  home: Scaffold(body: SkeletonGrid(count: 8)),
);

/// Two-pane detail placeholder preview.
@Preview(name: 'Detail (wide)', group: 'Skeletons', size: Size(1200, 800))
Widget skeletonDetailPreview() => const MaterialApp(
  home: Scaffold(body: DetailSkeleton()),
);

/// Stacked detail placeholder preview (narrow window).
@Preview(name: 'Detail (narrow)', group: 'Skeletons', size: Size(480, 800))
Widget skeletonDetailNarrowPreview() => const MaterialApp(
  home: Scaffold(body: DetailSkeleton()),
);
