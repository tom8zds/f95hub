import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../theme/tokens.dart';

/// A self-contained multi-select field: selected values render as chips in a
/// tappable field, and tapping opens a searchable checkbox dialog.
///
/// Deliberately avoids overlay/portal-based dropdowns (the previous
/// `multi_dropdown` package anchored its list in an overlay, which misbehaved
/// — errors and hangs — inside the filter drawer). A plain dialog behaves the
/// same everywhere: the drawer, the pane, and widget tests.
class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.title,
    required this.hint,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.searchable = false,
  });

  /// Dialog title (the section label).
  final String title;

  /// Placeholder shown when nothing is selected.
  final String hint;

  final List<({int id, String name})> items;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  /// Whether the dialog offers a search field (for long lists like tags).
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = [
      for (final item in items)
        if (selected.contains(item.id)) item.name,
    ];
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _MultiSelectDialog(
            title: title,
            items: items,
            selected: selected,
            onChanged: onChanged,
            searchable: searchable,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: names.isEmpty
                    ? Text(
                        hint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final name in names)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.searchable,
  });

  final String title;
  final List<({int id, String name})> items;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool searchable;

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late final Set<int> _selected = {...widget.selected};
  String _query = '';

  void _emit() => widget.onChanged({..._selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final item in widget.items)
        if (query.isEmpty || item.name.toLowerCase().contains(query)) item,
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: theme.textTheme.titleMedium),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(_selected.clear);
                      _emit();
                    },
                    child: Text(context.t.filters.clear),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.t.filters.search,
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        context.t.common.noMatches,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selected.contains(item.id),
                          title: Text(item.name),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selected.add(item.id);
                              } else {
                                _selected.remove(item.id);
                              }
                            });
                            _emit();
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
