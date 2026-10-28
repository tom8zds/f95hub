import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../i18n/i18n.dart';

/// Picks one scanned launch entry from [entries].
///
/// Pops with the chosen absolute path, or null on cancel. The remembered
/// [selectedPath] is highlighted (check icon) so re-opening the picker shows
/// the current choice.
class LaunchEntryDialog extends StatelessWidget {
  const LaunchEntryDialog({
    super.key,
    required this.entries,
    this.selectedPath,
  });

  final List<String> entries;
  final String? selectedPath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t.library.chooseLaunchEntry),
      content: SizedBox(
        width: 560,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in entries)
              ListTile(
                dense: true,
                selected: entry == selectedPath,
                leading: const Icon(Icons.terminal),
                title: Text(
                  p.basename(entry),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(entry, overflow: TextOverflow.ellipsis),
                trailing: entry == selectedPath
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(entry),
              ),
          ],
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
