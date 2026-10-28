import 'package:flutter/material.dart';

import '../domain/ports.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import 'multi_select_field.dart';

/// Server-side list filters: a 类别 tag multi-select, two prefix-group
/// sections (引擎/状态), and a "last N days" date control (spec stories 2 +
/// 4 + 17).
///
/// Multi-selects render as [MultiSelectField] — a chip field opening a
/// searchable checkbox dialog — instead of an overlay dropdown, which was
/// error-prone (crashes/hangs) inside the filter drawer. The 类别 section is
/// searchable for its ~150 options. Changing any filter triggers a server-side
/// reload via the callbacks: tags drive `listGames(tags: ...)`, 引擎/状态 drive
/// `listGames(prefixes: ...)` — two independent, AND-combined filters.
class GameFilters extends StatelessWidget {
  const GameFilters({
    super.key,
    required this.tagTable,
    required this.selectedTags,
    required this.selectedPrefixes,
    required this.date,
    required this.onTagsChanged,
    required this.onPrefixesChanged,
    required this.onDateChanged,
  });

  /// Static id→name table (tag names + the games prefix groups).
  final TagTable tagTable;

  /// Selected tag ids (server-side AND filter).
  final Set<int> selectedTags;

  /// Selected prefix ids across all sections (server-side AND filter).
  final Set<int> selectedPrefixes;

  /// "Last N days" window, or null for anytime.
  final int? date;

  final ValueChanged<Set<int>> onTagsChanged;
  final ValueChanged<Set<int>> onPrefixesChanged;
  final ValueChanged<int?> onDateChanged;

  /// The two f95zone prefix groups rendered as sections (research 01 §4.2).
  static const List<String> _sections = ['Engine', 'Status'];

  /// Localized heading for a prefix group.
  static String _sectionLabel(Translations t, String group) =>
      group == 'Engine' ? t.filters.engine : t.filters.status;

  /// Finds a games prefix group by name (null when the table lacks it).
  PrefixGroup? _group(String name) {
    for (final group in tagTable.prefixGroupItems(GameCategory.games)) {
      if (group.name == name) {
        return group;
      }
    }
    return null;
  }

  /// The prefixes of [groupName] as `(id, name)` items (empty when absent).
  List<({int id, String name})> _prefixItems(String groupName) {
    final group = _group(groupName);
    if (group == null) {
      return const [];
    }
    return [for (final p in group.prefixes) (id: p.id, name: p.name)];
  }

  @override
  Widget build(BuildContext context) {
    final tagItems = tagTable.tagItems();
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tagItems.isNotEmpty) ...[
          _dropdownSection(
            context,
            t.filters.category,
            tagItems,
            selectedTags,
            onTagsChanged,
            searchEnabled: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final group in _sections) ...[
          _dropdownSection(
            context,
            _sectionLabel(t, group),
            _prefixItems(group),
            selectedPrefixes,
            onPrefixesChanged,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<DateFilter>(
            value: DateFilter.fromDays(date),
            onChanged: (value) {
              if (value != null) onDateChanged(value.days);
            },
            items: [
              for (final filter in DateFilter.values)
                DropdownMenuItem(
                  value: filter,
                  child: Text(_dateLabel(t, filter)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// One multi-select section: a label over a [MultiSelectField].
  Widget _dropdownSection(
    BuildContext context,
    String label,
    List<({int id, String name})> items,
    Set<int> selected,
    ValueChanged<Set<int>> onChanged, {
    bool searchEnabled = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        MultiSelectField(
          key: ValueKey('filter-section-$label'),
          title: label,
          hint: context.t.filters.all,
          items: items,
          selected: selected,
          onChanged: onChanged,
          searchable: searchEnabled,
        ),
      ],
    );
  }
}

/// The "最近 N 天" options (spec story 4). [days] is the server `date` value;
/// null means "anytime" (no date filter).
enum DateFilter {
  today(1),
  last7(7),
  last30(30),
  anytime(null);

  const DateFilter(this.days);

  final int? days;

  static DateFilter fromDays(int? days) {
    for (final filter in DateFilter.values) {
      if (filter.days == days) {
        return filter;
      }
    }
    return DateFilter.anytime;
  }
}

/// Localized label for the date-window dropdown.
String _dateLabel(Translations t, DateFilter filter) => switch (filter) {
      DateFilter.today => t.filters.date.today,
      DateFilter.last7 => t.filters.date.last7,
      DateFilter.last30 => t.filters.date.last30,
      DateFilter.anytime => t.filters.date.anytime,
    };
