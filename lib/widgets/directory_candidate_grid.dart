import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../state/directory_import.dart';
import 'directory_candidate_card.dart';

/// A responsive grid of [DirectoryCandidateCard]s for the left (unmatched)
/// pane of the directory import.
///
/// Uses [SliverGridDelegateWithMaxCrossAxisExtent] so the column count grows
/// and shrinks with the pane width while each card stays at most ~300px wide
/// ([_maxCardWidth]), mirroring [GameGrid]'s layout pattern.
class DirectoryCandidateGrid extends StatelessWidget {
  const DirectoryCandidateGrid({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onCancel,
  });

  /// Cards never exceed this cross-axis extent; the grid derives the column
  /// count from the available width.
  static const double _maxCardWidth = 300;

  final List<ImportItem> items;

  /// Taps a candidate: matches it and moves it to the right pane.
  final ValueChanged<ImportItem> onSelect;

  /// Cancels an in-flight move.
  final ValueChanged<ImportItem> onCancel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(context.t.import.leftEmpty));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _maxCardWidth,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Card = 16:9 cover + name/version/path + status, so taller than the
        // listing cards.
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return DirectoryCandidateCard(
          item: item,
          onSelect: () => onSelect(item),
          onCancel: () => onCancel(item),
        );
      },
    );
  }
}
