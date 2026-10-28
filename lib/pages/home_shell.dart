import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/i18n.dart';
import 'dashboard_page.dart';
import '../widgets/theme_mode_toggle.dart';
import 'games_page.dart';
import 'library_page.dart';
import 'settings_page.dart';

/// Width at or above which the shell switches to a left-hand sidebar; below
/// it an [AppBar] hamburger opens the drawer as a modal.
const double kRailBreakpoint = 840;

/// The app shell: switches between Dashboard / Games / Library / Downloads /
/// Settings.
///
/// BOTH layouts use the official [NavigationDrawer] as the sidebar — wide
/// layouts host it inline as a permanent left pane (no NavigationRail), and
/// narrow layouts expose the same widget through a hamburger. The active
/// destination's full-row indicator and the bottom-pinned theme toggle come
/// from `navigationDrawerTheme` in [buildThemes].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// The scaffold that hosts the drawer in the narrow layout. Attached in both
  /// layouts so `closeDrawer` stays a harmless no-op on wide screens.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<IconData> _destinations = [
    Icons.dashboard,
    Icons.explore,
    Icons.library_books,
    Icons.settings,
  ];

  /// Outlined twins of [_destinations]: the unselected icon (the official
  /// navigation-drawer sample pairs outlined/filled icons).
  static const List<IconData> _destinationsOutlined = [
    Icons.dashboard_outlined,
    Icons.explore_outlined,
    Icons.library_books_outlined,
    Icons.settings_outlined,
  ];

  void _select(int index) {
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final labels = [
      t.nav.dashboard,
      t.nav.games,
      t.nav.library,
      t.nav.settings,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kRailBreakpoint;
        final pages = <Widget>[
          DashboardPage(
            leading: _drawerButton(context, wide),
            onOpenDestination: _select,
          ),
          GamesPage(leading: _drawerButton(context, wide)),
          LibraryPage(leading: _drawerButton(context, wide)),
          SettingsPage(leading: _drawerButton(context, wide)),
        ];

        return Scaffold(
          key: _scaffoldKey,
          drawer: wide ? null : _drawer(context, labels),
          // Wide layouts: the SAME navigation drawer hosted inline as the
          // permanent left pane — one sidebar everywhere, no NavigationRail.
          body: wide
              ? Row(
                  children: [
                    SizedBox(width: 304, child: _drawer(context, labels)),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ],
                )
              : IndexedStack(index: _index, children: pages),
        );
      },
    );
  }

  /// The official M3 navigation drawer, shared by both layouts: the header
  /// and destinations flow in the drawer's list, and the theme toggle rides
  /// in the drawer's `footer` slot — which the widget places AFTER its
  /// scrollable area, i.e. pinned to the very bottom.
  Widget _drawer(BuildContext context, List<String> labels) {
    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: _select,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text('f95hub', style: Theme.of(context).textTheme.titleSmall),
      ),
      footer: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ThemeModeSwitcher(),
        ),
      ),
      children: [
        for (var i = 0; i < _destinations.length; i++)
          NavigationDrawerDestination(
            icon: Icon(_destinationsOutlined[i]),
            selectedIcon: Icon(_destinations[i]),
            label: Text(labels[i]),
          ),
      ],
    );
  }

  /// The hamburger shown in the page title bar on narrow layouts; `null` on
  /// wide layouts (where the sidebar is always visible).
  Widget? _drawerButton(BuildContext context, bool wide) {
    if (wide) return null;
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget previews
// ---------------------------------------------------------------------------

/// Narrow shell preview (hamburger + [AppDrawer] layout).
@Preview(name: 'Narrow — drawer', group: 'HomeShell', size: Size(400, 720))
Widget homeShellNarrowPreview() => _homeShellPreview();

/// Wide shell preview (left [NavigationRail] layout).
@Preview(name: 'Wide — rail', group: 'HomeShell', size: Size(1200, 800))
Widget homeShellWidePreview() => _homeShellPreview();

/// Shared preview wrapper: the shell's pages read Riverpod providers, so it is
/// wrapped in a [ProviderScope]. Rendering real data in the widget previewer
/// needs the same in-memory provider overrides as the golden tests (see
/// `test/home_shell_test.dart`); those goldens remain the CI pixel baseline.
Widget _homeShellPreview() =>
    const MaterialApp(home: ProviderScope(child: HomeShell()));
