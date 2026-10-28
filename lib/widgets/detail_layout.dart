import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Width at or above which detail views render as two panes: a fixed-width
/// tinted sidebar (cover, metadata, actions) next to a scrolling content
/// column. Below it the same slots stack into a single scrolling column.
///
/// Matches the shell's rail breakpoint so "wide" means the same thing
/// app-wide.
const double kDetailWideBreakpoint = 840;

/// Sidebar (cover/meta/actions) width in the wide layout.
const double kDetailSidebarWidth = 300;

/// Cap on the sidebar block in the narrow (stacked) layout, so the portrait
/// cover stays a sensible size instead of dominating the column.
const double kDetailSidebarNarrowWidth = 240;

/// A responsive detail layout: [header] on top, then [sidebar] and [sections].
///
/// Wide (≥ [kDetailWideBreakpoint]): the sidebar becomes a fixed-width,
/// independently scrolling, tinted left pane and the header + [sections]
/// scroll in the remaining column — the desktop arrangement that keeps wide
/// windows from degenerating into a single sparse centered column.
///
/// Narrow: everything stacks in one scrolling column (header → sidebar →
/// sections), with the sidebar constrained to [kDetailSidebarWidth] so the
/// cover stays a reasonable size.
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    super.key,
    required this.header,
    required this.sidebar,
    required this.sections,
    this.topBar,
  });

  /// Title block: top of the content pane (wide) or the column (narrow).
  final Widget header;

  /// Cover / metadata / actions block; left pane when wide.
  final Widget sidebar;

  /// Content sections (gallery, tags, description, …), stacked with
  /// [AppSpacing.xl] between them.
  final List<Widget> sections;

  /// Optional pinned bar above the content column (the route's back + title).
  /// The sidebar still spans the full height, so the bar sits over the content
  /// column only when wide.
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Constraint-based (not window-based) so the layout adapts to the
        // slot it is hosted in — a dialog narrower than the window, or a
        // test surface — the same way the shell's rail does.
        final wide = constraints.maxWidth >= kDetailWideBreakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.cardXL),
                ),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: SizedBox(
                    width: kDetailSidebarWidth,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: sidebar,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (topBar != null) topBar!,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            header,
                            const SizedBox(height: AppSpacing.xl),
                            ..._joined(sections),
                          ],
                        ),
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
                    header,
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kDetailSidebarNarrowWidth,
                      ),
                      child: sidebar,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ..._joined(sections),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [sections] with the standard inter-section gap between them.
  static List<Widget> _joined(List<Widget> sections) => [
    for (var i = 0; i < sections.length; i++) ...[
      if (i > 0) const SizedBox(height: AppSpacing.xl),
      sections[i],
    ],
  ];
}
