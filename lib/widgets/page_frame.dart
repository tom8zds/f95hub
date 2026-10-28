import 'package:flutter/material.dart';

/// Page skeleton: a title bar plus a content slot.
///
/// Every top-level page composes its content inside a [PageFrame]; grids and
/// cards are nested in the [child] slot. This enforces the "never one giant
/// widget" decomposition convention.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.actions,
    this.leading,
    this.scaffoldKey,
    this.endDrawer,
    this.floatingActionButton,
    this.loading = false,
  }) : assert(
         title != null || titleWidget != null,
         'title or titleWidget must be provided',
       );

  /// The page's plain-text title (mutually exclusive with [titleWidget]).
  final String? title;

  /// A custom title widget (e.g. a search field) shown in place of [title].
  final Widget? titleWidget;

  /// The page's content (typically an `XxxGrid`).
  final Widget child;

  /// Optional trailing actions in the title bar.
  final List<Widget>? actions;

  /// Optional leading widget in the title bar (e.g. a drawer hamburger when
  /// the page is hosted in the shell's narrow layout).
  final Widget? leading;

  /// Optional key to the page's [Scaffold], so callers can open its drawers
  /// programmatically (e.g. `openEndDrawer`).
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Optional right-hand drawer hosted by the page's [Scaffold] (e.g. the
  /// games filter drawer).
  final Widget? endDrawer;

  /// Optional floating action button hosted by the page's [Scaffold].
  final Widget? floatingActionButton;

  /// Whether the page is busy (initial fetch, refresh, or an in-flight
  /// action). When true a thin [PageLoadingBar] sits under the title bar.
  ///
  /// Pages read this from their own state, so a tab that is still loading
  /// shows the bar as soon as it is switched to.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        leading: leading,
        title: titleWidget ?? Text(title!),
        actions: actions,
        bottom: loading ? const PageLoadingBar() : null,
        forceMaterialTransparency: true,
        elevation: 0,
      ),
      body: child,
    );
  }
}

/// The thin indeterminate progress bar shown under a page's title bar.
///
/// A [PreferredSizeWidget] so it can be handed to [AppBar.bottom]; it keeps
/// the title-bar height fixed while the page loads and disappears afterwards.
class PageLoadingBar extends StatelessWidget implements PreferredSizeWidget {
  const PageLoadingBar({super.key});

  /// Height of the bar in logical pixels.
  static const double barHeight = 3;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: barHeight,
      child: LinearProgressIndicator(minHeight: barHeight),
    );
  }
}
