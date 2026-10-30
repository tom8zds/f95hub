import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/import.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/library.dart';
import 'install_path_dialog.dart';

/// Shared "加入库" flow: confirm an install path, move the picked folder into
/// the library root, and scrape [game] into a persisted library entry.
///
/// Used by the games grid's right-click context menu. Surfaces the outcome via
/// a snackbar.
Future<void> addGameToLibrary(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  final result = await showDialog<({String path, String version})>(
    context: context,
    builder: (_) => const InstallPathDialog(),
  );
  if (result == null || !context.mounted) {
    return;
  }
  try {
    // "加入库" moves the picked folder into the library root (named after the
    // game) instead of leaving it scattered; without a storage root the
    // folder stays where it is.
    final installPath = result.path.isEmpty
        ? null
        : await moveIntoLibraryRoot(
            root: ref.read(libraryRootProvider),
            title: game.title,
            source: result.path,
          );
    await ref
        .read(libraryProvider.notifier)
        .scrapeAndStore(
          game,
          installPath: installPath,
          // Keep the dialog's version even when empty: falling back to null
          // would use the catalogue's latest as the local version.
          version: result.version,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.import.added)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.import.addFailed(error: e))),
    );
  }
}
