import 'package:flutter/material.dart';

import '../i18n/i18n.dart';

/// Edits a library game's locally installed version.
///
/// The version is free text and is popped verbatim: an empty field clears it,
/// and nothing is parsed or normalised. Pops null when cancelled.
class EditVersionDialog extends StatefulWidget {
  const EditVersionDialog({super.key, required this.initialVersion});

  /// The current local version the field is pre-filled with.
  final String initialVersion;

  @override
  State<EditVersionDialog> createState() => _EditVersionDialogState();
}

class _EditVersionDialogState extends State<EditVersionDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialVersion,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t.library.editVersionTitle),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.t.library.versionFieldLabel,
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(context.t.common.save),
        ),
      ],
    );
  }
}
