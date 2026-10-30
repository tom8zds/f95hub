import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/import.dart';
import '../domain/models.dart';
import '../domain/scraper.dart';
import '../i18n/i18n.dart';
import '../state/library.dart';
import 'game_search_list.dart';

/// Lets the user search the f95zone listing and pick a game to import into the
/// library at [installPath].
///
/// Pops with the imported [Game] on success, or null on cancel. The search is
/// the local game index (ticket 30): the folder name is parsed into a title,
/// matched against the cached catalogue, and the picked listing is scraped
/// online via `scrapeAndStore`. The local version defaults to a best-effort
/// parse from the folder name and can be edited.
class ImportGameDialog extends ConsumerStatefulWidget {
  const ImportGameDialog({super.key, required this.installPath});

  final String installPath;

  @override
  ConsumerState<ImportGameDialog> createState() => _ImportGameDialogState();
}

class _ImportGameDialogState extends ConsumerState<ImportGameDialog> {
  final _versionController = TextEditingController();
  int? _busyThreadId;

  @override
  void initState() {
    super.initState();
    _versionController.text = parseVersionFromName(widget.installPath);
  }

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _select(Game game) async {
    setState(() => _busyThreadId = game.threadId);
    try {
      final version = _versionController.text.trim();
      // Move the picked folder under the library root, like the card menu's
      // "加入库": the stored install path must be the post-import location.
      final installPath = widget.installPath.isEmpty
          ? null
          : await moveIntoLibraryRoot(
              root: ref.read(libraryRootProvider),
              title: game.title,
              source: widget.installPath,
              version: version,
            );
      final imported = await ref.read(libraryProvider.notifier).scrapeAndStore(
            game,
            installPath: installPath,
            // Pass the folder's version (even when empty) so an unknown local
            // version is not silently replaced by the catalogue's latest —
            // that made every import look up to date.
            version: version,
          );
      if (!mounted) return;
      Navigator.of(context).pop(imported);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyThreadId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.t.import.failedImport(error: e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.import.title),
      content: SizedBox(
        width: 480,
        height: 420,
        child: GameSearchList(
          onSelect: _select,
          busyThreadId: _busyThreadId,
          initialQuery: parseFolderName(widget.installPath).title,
          header: TextField(
            controller: _versionController,
            decoration: InputDecoration(
              labelText: t.import.localVersion,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}
