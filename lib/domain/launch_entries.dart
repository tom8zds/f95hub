/// Scanning a game's install folder for launch entries (`.exe` / `.bat`).
///
/// Pure `dart:io` helpers with no Flutter/Riverpod dependencies, so the scan
/// semantics can be unit-tested directly (see `test/launch_entries_test.dart`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory names that never contain a game's own launch entry: OS/system
/// folders plus VCS/dependency trees that may sit inside an unpacked archive.
/// Matched case-insensitively against the directory's basename.
const Set<String> _skippedDirectoryNames = {
  r'$recycle.bin',
  'system volume information',
  'windows',
  'system32',
  'syswow64',
  'winsxs',
  'node_modules',
  '.git',
  '.svn',
};

/// Lower-case extensions considered launchable.
const Set<String> _launchExtensions = {'.exe', '.bat'};

/// The launcher some releases ship to start the game together with its
/// bundled tools. When a scan finds it, it is selected automatically as the
/// remembered launch entry instead of asking the user.
const String kDefaultLaunchBat = '与工具一同启动.bat';

/// The scan result that should be selected by default, or `null` when the
/// scan contains no [kDefaultLaunchBat].
///
/// Matching is by basename and case-insensitive, so `与工具一同启动.BAT` also
/// qualifies and the file may live in a nested subfolder.
String? defaultLaunchEntry(Iterable<String> entries) {
  final wanted = kDefaultLaunchBat.toLowerCase();
  for (final entry in entries) {
    if (p.basename(entry).toLowerCase() == wanted) {
      return entry;
    }
  }
  return null;
}

/// Lists candidate launch entries under [installPath].
///
/// Walks the tree breadth-first, returning `.exe`/`.bat` files found at
/// *depth 0* (directly in the folder) up to [maxDepth] levels of
/// subdirectories. Directories in [_skippedDirectoryNames] and hidden (dot)
/// directories are skipped; unreadable directories are ignored rather than
/// failing the whole scan. Results are capped at [maxCount].
///
/// The list is sorted by folder depth first, then case-insensitively by
/// relative path, so the game's own launcher (usually at the top level) ranks
/// before helpers in nested `bin/`/`lib/` folders. Returns an empty list when
/// [installPath] does not exist.
Future<List<String>> scanLaunchEntries(
  String installPath, {
  int maxDepth = 3,
  int maxCount = 50,
}) async {
  if (installPath.trim().isEmpty || maxCount <= 0) {
    return const [];
  }
  final root = Directory(installPath);
  if (!await root.exists()) {
    return const [];
  }

  final found = <_Candidate>[];
  await _scan(root, 0, maxDepth, maxCount, found);
  found.sort((a, b) {
    final byDepth = a.depth.compareTo(b.depth);
    if (byDepth != 0) return byDepth;
    return a.relative.toLowerCase().compareTo(b.relative.toLowerCase());
  });
  return [for (final candidate in found) candidate.path];
}

Future<void> _scan(
  Directory dir,
  int depth,
  int maxDepth,
  int maxCount,
  List<_Candidate> found,
) async {
  if (found.length >= maxCount) {
    return;
  }
  final List<FileSystemEntity> entries;
  try {
    entries = await dir.list(followLinks: false).toList();
  } on FileSystemException {
    // Permission denied / vanished mid-scan: that subtree is simply skipped.
    return;
  }

  for (final entity in entries) {
    if (found.length >= maxCount) return;
    if (entity is File) {
      final extension = p.extension(entity.path).toLowerCase();
      if (!_launchExtensions.contains(extension)) continue;
      found.add(
        _Candidate(
          path: entity.path,
          relative: p.relative(entity.path, from: dir.path),
          depth: depth,
        ),
      );
    }
  }

  if (depth >= maxDepth) return;
  for (final entity in entries) {
    if (found.length >= maxCount) return;
    if (entity is! Directory) continue;
    final name = p.basename(entity.path).toLowerCase();
    if (name.startsWith('.') || _skippedDirectoryNames.contains(name)) {
      continue;
    }
    await _scan(entity, depth + 1, maxDepth, maxCount, found);
  }
}

class _Candidate {
  const _Candidate({
    required this.path,
    required this.relative,
    required this.depth,
  });

  final String path;
  final String relative;
  final int depth;
}
