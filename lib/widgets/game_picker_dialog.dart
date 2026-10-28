import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import 'game_search_list.dart';

/// Modal that lets the user search the local game index and pick a [Game].
///
/// Pops with the selected [Game], or null on cancel. It reuses [GameSearchList]
/// for the search/select UI; the caller (directory import) decides what to do
/// with the chosen game (copy + scrape + persist).
class GamePickerDialog extends ConsumerWidget {
  const GamePickerDialog({super.key, this.initialQuery});

  /// Guessed title pre-filled into the search field (from the candidate folder
  /// name); null leaves the search empty.
  final String? initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(context.t.import.associateTitle),
      content: SizedBox(
        width: 480,
        height: 420,
        child: GameSearchList(
          onSelect: (game) => Navigator.of(context).pop(game),
          initialQuery: initialQuery,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
      ],
    );
  }
}
