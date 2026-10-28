import 'package:flutter/material.dart';

import '../i18n/i18n.dart';

/// The local library's right-hand end drawer: the 有更新 switch and one
/// multi-select chip per tag present in the library, closed by 应用
/// (ticket 58).
///
/// Purely presentational: the page owns the filter and rebuilds the grid as
/// these callbacks fire.
class LibraryFilterDrawer extends StatelessWidget {
  const LibraryFilterDrawer({
    super.key,
    required this.tagOptions,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onlyUpdates,
    required this.onOnlyUpdatesChanged,
  });

  /// Every tag name present in the library, de-duplicated and sorted.
  final List<String> tagOptions;

  final Set<String> selectedTags;

  /// Called with a tag name when its chip is toggled.
  final ValueChanged<String> onTagToggled;

  final bool onlyUpdates;
  final ValueChanged<bool> onOnlyUpdatesChanged;

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilterChip(
                        key: const Key('library-only-updates'),
                        selected: onlyUpdates,
                        onSelected: onOnlyUpdatesChanged,
                        avatar: const Icon(Icons.arrow_circle_up, size: 18),
                        label: Text(t.library.onlyUpdates),
                      ),
                      if (tagOptions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(t.library.tags, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in tagOptions)
                              FilterChip(
                                key: Key('library-tag-$tag'),
                                selected: selectedTags.contains(tag),
                                onSelected: (_) => onTagToggled(tag),
                                label: Text(tag),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('library-filter-apply'),
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
