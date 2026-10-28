import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../state/directory_import.dart';

/// The state-dependent progress/status line of an [ImportItem], shared by the
/// candidate card and the matched-item list.
///
/// Shows the move progress with a cancel action, a scraping spinner, the
/// imported title, the cancellation, or the failure message.
class ImportItemStatus extends StatelessWidget {
  const ImportItemStatus({
    super.key,
    required this.item,
    required this.onCancel,
  });

  final ImportItem item;

  /// Cancels the in-flight move for [item].
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    switch (item.phase) {
      case ImportItemPhase.pending:
        return const SizedBox.shrink();
      case ImportItemPhase.moving:
        return Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 4,
              ),
            ),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel),
              tooltip: t.common.cancel,
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      case ImportItemPhase.scraping:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(t.import.scraping),
          ],
        );
      case ImportItemPhase.done:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.import.imported(title: item.game?.title ?? item.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      case ImportItemPhase.cancelled:
        return Text(t.import.cancelled);
      case ImportItemPhase.failed:
        return Text(
          t.import.failed(error: item.error!),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
    }
  }
}
