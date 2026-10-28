import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ports.dart';
import '../i18n/i18n.dart';
import '../state/game_list.dart';
import 'game_filters.dart';

/// A right-hand end drawer wrapping [GameFilters]: a "过滤器" header, the
/// scrollable filter controls, and a full-width "应用" button that closes the
/// drawer (ticket 25).
///
/// Reads the list state reactively so chip selections update live as the user
/// toggles them (each change also triggers a server-side reload); "应用" simply
/// closes the drawer.
class FilterDrawer extends ConsumerWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameListProvider);
    final notifier = ref.read(gameListProvider.notifier);
    final theme = Theme.of(context);
    final t = context.t;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.filters.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: GameFilters(
                    tagTable: state.tagTable ?? const TagTable(tags: {}, prefixes: {}),
                    selectedTags: state.selectedTags,
                    selectedPrefixes: state.selectedPrefixes,
                    date: state.date,
                    onTagsChanged: notifier.setTags,
                    onPrefixesChanged: notifier.setPrefixes,
                    onDateChanged: notifier.setDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('filter-apply'),
                onPressed: () => Scaffold.of(context).closeEndDrawer(),
                child: Text(t.common.apply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
