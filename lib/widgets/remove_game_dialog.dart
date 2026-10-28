import 'package:flutter/material.dart';

import '../i18n/i18n.dart';

/// The choice a user makes when removing a library entry.
enum RemoveChoice { keepFiles, deleteFiles }

/// Confirm dialog for removing a game: keep the local files, or delete them.
///
/// Extracted so the choice semantics (keep vs delete) and the confirmation UI
/// can be golden-previewed in isolation. Pops with a [RemoveChoice], or `null`
/// on cancel.
class RemoveGameDialog extends StatelessWidget {
  const RemoveGameDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.library.removeTitle),
      content: Text(t.library.removeConfirm(title: title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(RemoveChoice.keepFiles),
          child: Text(t.buttons.keepFiles),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(RemoveChoice.deleteFiles),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(t.buttons.deleteFiles),
        ),
      ],
    );
  }
}
