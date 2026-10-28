import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../theme/tokens.dart';

/// The three library-management actions for a game entry: open the install
/// folder, launch the game, and remove the entry.
///
/// All callbacks are injected so this component renders in isolation for a
/// golden preview and the real wiring (OS launch via [AppLauncher], guarded
/// delete via the library controller) stays testable behind seams.
class LibraryActions extends StatelessWidget {
  const LibraryActions({
    super.key,
    required this.onOpenFolder,
    required this.onLaunch,
    required this.onRemove,
    this.hasInstallPath = true,
  });

  final VoidCallback onOpenFolder;
  final VoidCallback onLaunch;
  final VoidCallback onRemove;

  /// When false, the open-folder action is disabled (no install path).
  final bool hasInstallPath;

  @override
  Widget build(BuildContext context) {
    // Wrap (not Row): the three buttons stack inside narrow detail sidebars.
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: hasInstallPath ? onOpenFolder : null,
          icon: const Icon(Icons.folder_open),
          label: Text(context.t.buttons.openFolder),
        ),
        FilledButton.icon(
          onPressed: onLaunch,
          icon: const Icon(Icons.play_arrow),
          label: Text(context.t.buttons.launchGame),
        ),
        TextButton.icon(
          onPressed: onRemove,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(context.t.buttons.remove),
        ),
      ],
    );
  }
}
