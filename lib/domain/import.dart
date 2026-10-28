/// Pure helpers for directory import: scanning a source tree for candidates,
/// sanitizing folder names, and moving directories into the library root.
///
/// No Flutter/Riverpod dependencies, so the scan/sanitize/move semantics can be
/// unit-tested directly (see `test/import_helpers_test.dart`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// A directory that can be imported into the library.
class ImportCandidate {
  const ImportCandidate({required this.path, required this.name});

  /// Absolute path of the candidate directory.
  final String path;

  /// The directory's basename (its display name).
  final String name;
}

/// Thrown by [copyDirectory] when its [isCancelled] callback returns true.
class CopyCancelledException implements Exception {
  const CopyCancelledException();

  @override
  String toString() => 'CopyCancelledException';
}

/// Lists the depth-1 immediate subdirectories of [root] as import candidates.
///
/// Hidden/dot entries (names starting with `.`) and truly-empty directories
/// (those with no immediate entries at all) are skipped. The scan is
/// **shallow** — it only lists each depth-1 child once to test emptiness, so
/// it never walks nested subtrees (which used to hang on large trees). Only
/// direct children of [root] are returned, sorted by name (case-insensitive)
/// for a stable, predictable order. Returns an empty list when [root] does not
/// exist.
Future<List<ImportCandidate>> scanDirectories(String root) async {
  final dir = Directory(root);
  if (!await dir.exists()) {
    return const [];
  }
  final candidates = <ImportCandidate>[];
  await for (final entity in dir.list(followLinks: false)) {
    if (entity is! Directory) continue;
    final name = p.basename(entity.path);
    if (name.startsWith('.')) continue;
    // Shallow emptiness check: skip only directories with no entries at all.
    // This is a single non-recursive listing, so a deep subtree inside a
    // candidate is never walked.
    if (Directory(entity.path).listSync(followLinks: false).isEmpty) continue;
    candidates.add(ImportCandidate(path: entity.path, name: name));
  }
  candidates.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return candidates;
}

/// Sanitizes [title] into a non-empty, filesystem-safe folder name.
///
/// Replaces characters that are illegal in Windows file names (and path
/// separators), collapses runs of whitespace, and strips trailing dots/spaces
/// (which Windows silently drops). Falls back to `game` when nothing usable
/// remains, so the result is always non-empty.
String safeFolderName(String title) {
  var name = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '');
  return name.isEmpty ? 'game' : name;
}

/// Recursively copies the directory at [src] into [dst], files + subdirectories.
///
/// Reports progress via [onProgress] as `(copied, total)` file counts (called
/// once with `(0, total)` before copying and once per file after). [isCancelled]
/// is polled between files; when it returns true the copy aborts by throwing
/// [CopyCancelledException] (any already-copied files remain, but the source is
/// never modified or deleted).
Future<void> copyDirectory(
  String src,
  String dst, {
  void Function(int copied, int total)? onProgress,
  bool Function()? isCancelled,
}) async {
  final files = <File>[];
  await _collectFiles(Directory(src), files);
  final total = files.length;
  onProgress?.call(0, total);
  var copied = 0;
  for (final file in files) {
    if (isCancelled?.call() ?? false) {
      throw const CopyCancelledException();
    }
    final rel = p.relative(file.path, from: src);
    final target = File(p.join(dst, rel));
    await target.parent.create(recursive: true);
    await file.copy(target.path);
    copied++;
    onProgress?.call(copied, total);
  }
}

/// Moves the directory at [src] to [dst], preserving its contents.
///
/// Tries [Directory.rename] first (an atomic same-volume move). When that
/// fails — the usual cross-volume case — it falls back to [copyDirectory]
/// followed by deleting the source, so the source is only removed once every
/// file landed under [dst].
///
/// Refuses to run when [dst] already exists (throws [FileSystemException] and
/// leaves both sides untouched), and never deletes [src] before the copy
/// completed. [onProgress]/[isCancelled] are forwarded to the copy fallback;
/// a cancelled copy throws [CopyCancelledException] with the source intact.
///
/// [rename] is a test seam overriding the platform rename (defaults to
/// `Directory(src).rename(dst)`), so the cross-volume fallback can be exercised
/// deterministically.
Future<void> moveDirectory(
  String src,
  String dst, {
  void Function(int copied, int total)? onProgress,
  bool Function()? isCancelled,
  Future<void> Function(String from, String to)? rename,
}) async {
  if (await FileSystemEntity.type(dst) != FileSystemEntityType.notFound) {
    throw FileSystemException('Destination already exists', dst);
  }
  final doRename = rename ?? (from, to) => Directory(from).rename(to);
  try {
    await Directory(p.dirname(dst)).create(recursive: true);
    await doRename(src, dst);
    return;
  } on FileSystemException {
    // Cross-volume rename (or a rename the platform refused): fall back to a
    // copy + delete. Any other failure surfaces again from the copy.
  }
  // A failed rename must not have left a partially populated target behind;
  // refuse rather than merge into it.
  if (await FileSystemEntity.type(dst) != FileSystemEntityType.notFound) {
    throw FileSystemException('Destination already exists', dst);
  }
  await copyDirectory(
    src,
    dst,
    onProgress: onProgress,
    isCancelled: isCancelled,
  );
  await Directory(src).delete(recursive: true);
}

/// Moves the picked install folder [source] under the library [root] as
/// `<root>/<safeFolderName(title)>` and returns the resulting install path.
///
/// Used by "加入库": the folder is *moved* into the library instead of being
/// referenced in place. When [root] is null/blank (no storage root configured)
/// the folder stays where it is and [source] is returned unchanged. When the
/// folder already is the target directory the move is skipped. A conflicting
/// target throws (via [moveDirectory]) without deleting the source.
Future<String> moveIntoLibraryRoot({
  required String? root,
  required String title,
  required String source,
}) async {
  final base = root?.trim();
  if (base == null || base.isEmpty) {
    return source;
  }
  final dst = p.join(base, safeFolderName(title));
  if (p.equals(p.normalize(dst), p.normalize(source))) {
    return dst;
  }
  await moveDirectory(source, dst);
  return dst;
}

Future<void> _collectFiles(Directory dir, List<File> out) async {
  await for (final entity in dir.list(followLinks: false)) {
    if (entity is File) {
      out.add(entity);
    } else if (entity is Directory) {
      await _collectFiles(entity, out);
    }
  }
}
