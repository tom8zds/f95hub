import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scraper.dart';
import '../i18n/i18n.dart';
import '../state/library.dart';

/// A dialog that lets the user enter (or browse to) a local install path plus
/// the locally installed version.
///
/// Pops with a `(path, version)` record on confirm, or null on cancel. An
/// empty path is a valid confirm (adding metadata without a known install
/// location); the version is pre-filled with a best-effort parse from the
/// folder name when the path is browsed to.
class InstallPathDialog extends ConsumerStatefulWidget {
  const InstallPathDialog({super.key});

  @override
  ConsumerState<InstallPathDialog> createState() => _InstallPathDialogState();
}

class _InstallPathDialogState extends ConsumerState<InstallPathDialog> {
  final _controller = TextEditingController();
  final _versionController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    final dir = await ref.read(directoryPickerProvider)();
    if (dir != null && dir.isNotEmpty) {
      _controller.text = dir;
      _versionController.text = parseVersionFromName(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.buttons.addToLibrary),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: t.import.installPath,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _versionController,
            decoration: InputDecoration(
              labelText: t.import.localVersion,
              isDense: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _browse,
              icon: const Icon(Icons.folder_open),
              label: Text(t.common.browse),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (
              path: _controller.text.trim(),
              version: _versionController.text.trim(),
            ),
          ),
          child: Text(t.common.add),
        ),
      ],
    );
  }
}
