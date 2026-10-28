/// Pure helpers for destructive library operations (deleting a game's local
/// install files).
///
/// These have no Flutter/Riverpod dependencies so the remove semantics can be
/// unit-tested directly (see `test/library_management_test.dart`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// True when [path] is [root] itself or a descendant of [root].
///
/// Comparison is on absolute, normalized paths so `C:\lib\game` is considered
/// inside `C:\lib` but `C:\library` is not.
bool isWithinRoot(String root, String path) {
  final rootAbs = p.normalize(p.absolute(root));
  final pathAbs = p.normalize(p.absolute(path));
  if (pathAbs == rootAbs) {
    return true;
  }
  final prefix = rootAbs.endsWith(p.separator)
      ? rootAbs
      : '$rootAbs${p.separator}';
  return pathAbs.startsWith(prefix);
}

/// Deletes the directory at [path] recursively, refusing to touch anything
/// outside the configured library [root].
///
/// Throws [ArgumentError] when [root] is null/empty (no library root
/// configured) or when [path] is outside [root]. This guard means a corrupted
/// `installPath` can never cascade into deleting unrelated user data.
Future<void> deleteInstallFiles({
  required String? root,
  required String path,
}) async {
  if (root == null || root.trim().isEmpty) {
    throw ArgumentError('No library root configured; refusing to delete files');
  }
  if (!isWithinRoot(root, path)) {
    throw ArgumentError(
      'Refusing to delete outside the library root: $path (root: $root)',
    );
  }
  final dir = Directory(path);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
