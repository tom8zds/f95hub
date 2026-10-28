import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One labelled row of a [MetaList].
class MetaEntry {
  const MetaEntry(this.label, this.value);

  /// Short field label (e.g. "开发者").
  final String label;

  /// Field value; empty entries are skipped by [MetaList.of].
  final String value;
}

/// A compact label-over-value metadata list, used in detail sidebars.
///
/// Labels sit above their values so long values (paths, dates, version
/// strings) wrap instead of truncating.
class MetaList extends StatelessWidget {
  const MetaList({super.key, required this.entries});

  final List<MetaEntry> entries;

  /// [entries] with empty values filtered out.
  static List<MetaEntry> of(List<MetaEntry> entries) =>
      entries.where((e) => e.value.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = of(entries);
    if (shown.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Text(
            shown[i].label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(shown[i].value, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}
