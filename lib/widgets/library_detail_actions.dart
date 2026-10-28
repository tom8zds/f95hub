import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/launch_entries.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/library.dart';
import 'edit_version_dialog.dart';
import 'launch_entry_dialog.dart';
import 'remove_game_dialog.dart';

/// Shared library-entry action flows, used by both hosts of a library detail
/// (the modal dialog on narrow windows and the right-hand pane tab on wide
/// ones). Extracted so the two hosts stay thin.
///
/// [removeLibraryGame] takes the host's follow-up ([onRemoved]: the dialog
/// pops itself, the pane closes the tab).

/// Scans the install folder and remembers a launch entry.
///
/// A `与工具一同启动.bat` found by the scan is persisted right away and
/// returned without showing the picker; otherwise the user chooses from the
/// scanned list. Returns the selected path (null when cancelled or nothing
/// was found).
Future<String?> pickLaunchEntry(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  final installPath = game.installPath;
  if (installPath == null || installPath.trim().isEmpty) {
    return null;
  }
  final entries = await ref.read(launchEntryScannerProvider)(installPath);
  if (!context.mounted) {
    return null;
  }
  if (entries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.library.noLaunchEntries)),
    );
    return null;
  }
  // First selection: the bundled "launch with tools" batch wins over asking.
  final preferred = game.hasLaunchPath ? null : defaultLaunchEntry(entries);
  if (preferred != null) {
    await ref.read(libraryProvider.notifier).setLaunchPath(game, preferred);
    return preferred;
  }
  final selected = await showDialog<String>(
    context: context,
    builder: (_) => LaunchEntryDialog(
      entries: entries,
      selectedPath: game.launchPath,
    ),
  );
  if (selected == null || selected.isEmpty || !context.mounted) {
    return null;
  }
  await ref.read(libraryProvider.notifier).setLaunchPath(game, selected);
  return selected;
}

/// Launches [game], picking (and persisting) a launch entry first when none
/// is remembered.
Future<void> launchGame(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  var target = game;
  if (!target.hasLaunchPath) {
    final picked = await pickLaunchEntry(context, ref, target);
    if (picked == null) {
      return;
    }
    target = target.withLaunchPath(picked);
  }
  try {
    await ref.read(libraryProvider.notifier).launch(target);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.library.launchFailed(error: e))));
  }
}

/// Opens the version editor pre-filled with [game]'s current version and
/// persists whatever text was saved (empty clears it).
Future<void> editLibraryVersion(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  final version = await showDialog<String>(
    context: context,
    builder: (_) => EditVersionDialog(initialVersion: game.version),
  );
  if (version == null || !context.mounted) {
    return;
  }
  await ref.read(libraryProvider.notifier).setVersion(game.threadId, version);
}

/// Removes [game] (after the keep/delete-files confirmation) and notifies the
/// host via [onRemoved].
Future<void> removeLibraryGame(
  BuildContext context,
  WidgetRef ref,
  Game game, {
  required VoidCallback onRemoved,
}) async {
  final choice = await showDialog<RemoveChoice>(
    context: context,
    builder: (_) => RemoveGameDialog(title: game.title),
  );
  if (choice == null) {
    return;
  }
  final controller = ref.read(libraryProvider.notifier);
  try {
    await controller.remove(
      game,
      deleteFiles: choice == RemoveChoice.deleteFiles,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.library.removeFailed(error: e))),
    );
    return;
  }
  onRemoved();
}
