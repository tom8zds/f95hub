import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/domain/import.dart';

void main() {
  group('scanDirectories', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('f95hub_scan_');
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    Future<Directory> dir(String name) async {
      final d = Directory(p.join(root.path, name));
      await d.create();
      return d;
    }

    test('lists depth-1 subdirectories sorted by name', () async {
      await dir('beta');
      await dir('alpha');
      await dir('gamma');
      await File(p.join(root.path, 'alpha', 'a.txt')).writeAsString('x');
      await File(p.join(root.path, 'beta', 'a.txt')).writeAsString('x');
      await File(p.join(root.path, 'gamma', 'a.txt')).writeAsString('x');

      final candidates = await scanDirectories(root.path);

      expect(candidates.map((c) => c.name).toList(), ['alpha', 'beta', 'gamma']);
    });

    test('skips hidden/dot directories', () async {
      await dir('.hidden');
      await dir('visible');
      await File(p.join(root.path, '.hidden', 'x')).writeAsString('x');
      await File(p.join(root.path, 'visible', 'x')).writeAsString('x');

      final candidates = await scanDirectories(root.path);

      expect(candidates.map((c) => c.name).toList(), ['visible']);
    });

    test('skips empty directories', () async {
      await dir('empty');
      await dir('full');
      await File(p.join(root.path, 'full', 'x')).writeAsString('x');

      final candidates = await scanDirectories(root.path);

      expect(candidates.map((c) => c.name).toList(), ['full']);
    });

    test('ignores plain files and does not recurse', () async {
      await dir('top');
      await dir('nested');
      await dir('nested/inner');
      await File(p.join(root.path, 'a.txt')).writeAsString('x');
      await File(p.join(root.path, 'top', 'a.txt')).writeAsString('x');
      await File(p.join(root.path, 'nested', 'inner', 'a.txt')).writeAsString('x');

      final candidates = await scanDirectories(root.path);

      // `nested` has an immediate entry (its `inner` subdirectory) so it is
      // non-empty under the shallow check; `top` too; the plain file is not a
      // candidate and the scan never recurses into `nested/inner`.
      expect(candidates.map((c) => c.name).toList(), ['nested', 'top']);
    });

    test('does not recurse into deep subtrees (shallow emptiness check)',
        () async {
      // A candidate whose only content is a deep chain of empty subdirectories
      // is still kept: its immediate child is present, so the shallow check
      // sees it as non-empty. A recursive size scan would report 0 and skip it,
      // so keeping it proves the scan never walks the subtree.
      await dir('deep');
      await Directory(p.join(root.path, 'deep', 'a', 'b', 'c')).create(
        recursive: true,
      );

      final candidates = await scanDirectories(root.path);

      expect(candidates.map((c) => c.name).toList(), ['deep']);
    });

    test('scans a large/deep tree quickly without walking it', () async {
      // Build a candidate with a wide, deep subtree; the shallow scan must
      // return it immediately (it only lists the top-level entry) rather than
      // recursing through thousands of files.
      await dir('game');
      var cursor = p.join(root.path, 'game');
      for (var i = 0; i < 50; i++) {
        cursor = p.join(cursor, 'level$i');
        await Directory(cursor).create();
        await File(p.join(cursor, 'file.txt')).writeAsString('x');
      }

      final candidates = await scanDirectories(root.path);

      expect(candidates.map((c) => c.name).toList(), ['game']);
    });

    test('returns empty for a missing root', () async {
      final candidates = await scanDirectories(
        p.join(root.path, 'does-not-exist'),
      );
      expect(candidates, isEmpty);
    });
  });

  group('safeFolderName', () {
    test('replaces filesystem-illegal characters', () {
      expect(safeFolderName('a:b*c?d"e<f>g|h\\i/j'), 'a_b_c_d_e_f_g_h_i_j');
    });

    test('collapses whitespace and trims', () {
      expect(safeFolderName('  My   Game  '), 'My Game');
    });

    test('strips trailing dots and spaces', () {
      expect(safeFolderName('Game...  '), 'Game');
    });

    test('falls back to a non-empty name', () {
      expect(safeFolderName('...'), 'game');
      expect(safeFolderName('   '), 'game');
      expect(safeFolderName(''), 'game');
    });

    test('keeps ordinary names intact', () {
      expect(safeFolderName('Devoted Wife 0.56'), 'Devoted Wife 0.56');
    });
  });

  group('moveDirectory', () {
    late Directory src;
    late Directory dst;

    setUp(() async {
      src = await Directory.systemTemp.createTemp('f95hub_move_src_');
      dst = await Directory.systemTemp.createTemp('f95hub_move_dst_');
    });

    tearDown(() async {
      for (final dir in [src, dst]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    Future<void> populate(Directory dir) async {
      await File(p.join(dir.path, 'a.txt')).writeAsString('a');
      await Directory(p.join(dir.path, 'sub')).create();
      await File(p.join(dir.path, 'sub', 'b.txt')).writeAsString('b');
    }

    test('renames the source into place on the same volume', () async {
      await populate(src);

      await moveDirectory(src.path, p.join(dst.path, 'out'));

      expect(await Directory(src.path).exists(), isFalse);
      expect(await File(p.join(dst.path, 'out', 'a.txt')).exists(), isTrue);
      expect(
        await File(p.join(dst.path, 'out', 'sub', 'b.txt')).readAsString(),
        'b',
      );
    });

    test('falls back to copy + delete across volumes', () async {
      await populate(src);
      final progress = <(int, int)>[];

      await moveDirectory(
        src.path,
        p.join(dst.path, 'out'),
        rename: (from, to) async =>
            throw const FileSystemException('cross-device link'),
        onProgress: (copied, total) => progress.add((copied, total)),
      );

      expect(await Directory(src.path).exists(), isFalse);
      expect(
        await File(p.join(dst.path, 'out', 'sub', 'b.txt')).readAsString(),
        'b',
      );
      expect(progress, [(0, 2), (1, 2), (2, 2)]);
    });

    test('refuses an existing target and keeps the source intact', () async {
      await populate(src);
      final target = Directory(p.join(dst.path, 'out'));
      await target.create();
      await File(p.join(target.path, 'existing.txt')).writeAsString('keep');

      await expectLater(
        moveDirectory(src.path, target.path),
        throwsA(isA<FileSystemException>()),
      );

      expect(await File(p.join(src.path, 'a.txt')).exists(), isTrue);
      expect(await File(p.join(target.path, 'existing.txt')).exists(), isTrue);
    });

    test('keeps the source when the copy fallback is cancelled', () async {
      await populate(src);

      await expectLater(
        moveDirectory(
          src.path,
          p.join(dst.path, 'out'),
          rename: (from, to) async =>
              throw const FileSystemException('cross-device link'),
          isCancelled: () => true,
        ),
        throwsA(isA<CopyCancelledException>()),
      );

      expect(await File(p.join(src.path, 'a.txt')).exists(), isTrue);
      expect(await File(p.join(src.path, 'sub', 'b.txt')).exists(), isTrue);
    });

    test('keeps the source when the copy fallback cannot complete', () async {
      await populate(src);
      // Block the target's parent with a plain file, so the copy (and its
      // directory creation) fails.
      final blocker = await File(p.join(dst.path, 'blocker')).writeAsString('x');

      await expectLater(
        moveDirectory(
          src.path,
          p.join(blocker.path, 'out'),
          rename: (from, to) async =>
              throw const FileSystemException('cross-device link'),
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await File(p.join(src.path, 'a.txt')).exists(), isTrue);
    });
  });

  group('moveIntoLibraryRoot', () {
    late Directory storage;
    late Directory picked;

    setUp(() async {
      storage = await Directory.systemTemp.createTemp('f95hub_lib_');
      picked = await Directory.systemTemp.createTemp('f95hub_picked_');
      await File(p.join(picked.path, 'a.txt')).writeAsString('a');
    });

    tearDown(() async {
      for (final dir in [storage, picked]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    test('moves the folder under the root, named after the game title',
        () async {
      final path = await moveIntoLibraryRoot(
        root: storage.path,
        title: 'My Game',
        source: picked.path,
      );

      expect(path, p.join(storage.path, 'My Game'));
      expect(await Directory(picked.path).exists(), isFalse);
      expect(await File(p.join(path, 'a.txt')).exists(), isTrue);
    });

    test('keeps the folder in place without a storage root', () async {
      final path = await moveIntoLibraryRoot(
        root: '  ',
        title: 'My Game',
        source: picked.path,
      );

      expect(path, picked.path);
      expect(await Directory(picked.path).exists(), isTrue);
    });

    test('skips the move when the folder already is the target', () async {
      final target = Directory(p.join(storage.path, 'My Game'));
      await picked.rename(target.path);

      final path = await moveIntoLibraryRoot(
        root: storage.path,
        title: 'My Game',
        source: target.path,
      );

      expect(path, target.path);
      expect(await File(p.join(target.path, 'a.txt')).exists(), isTrue);
    });

    test('refuses to overwrite an existing target', () async {
      final existing = Directory(p.join(storage.path, 'My Game'));
      await existing.create();
      await File(p.join(existing.path, 'old.txt')).writeAsString('old');

      await expectLater(
        moveIntoLibraryRoot(
          root: storage.path,
          title: 'My Game',
          source: picked.path,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await File(p.join(existing.path, 'old.txt')).exists(), isTrue);
      expect(await File(p.join(picked.path, 'a.txt')).exists(), isTrue);
    });
  });

  group('copyDirectory', () {
    late Directory src;
    late Directory dst;

    setUp(() async {
      src = await Directory.systemTemp.createTemp('f95hub_copy_src_');
      dst = await Directory.systemTemp.createTemp('f95hub_copy_dst_');
    });

    tearDown(() async {
      await src.delete(recursive: true);
      await dst.delete(recursive: true);
    });

    test('copies files and subdirectories and reports progress', () async {
      await File(p.join(src.path, 'a.txt')).writeAsString('a');
      await Directory(p.join(src.path, 'sub')).create();
      await File(p.join(src.path, 'sub', 'b.txt')).writeAsString('b');
      final progress = <(int, int)>[];

      await copyDirectory(src.path, p.join(dst.path, 'out'),
          onProgress: (copied, total) => progress.add((copied, total)));

      expect(await File(p.join(dst.path, 'out', 'a.txt')).exists(), isTrue);
      expect(await File(p.join(dst.path, 'out', 'sub', 'b.txt')).exists(), isTrue);
      expect(
        await File(p.join(dst.path, 'out', 'sub', 'b.txt')).readAsString(),
        'b',
      );
      // 0/2 before, then 1/2 and 2/2.
      expect(progress, [(0, 2), (1, 2), (2, 2)]);
    });

    test('leaves the source intact', () async {
      await File(p.join(src.path, 'a.txt')).writeAsString('a');
      final before = await File(p.join(src.path, 'a.txt')).readAsString();

      await copyDirectory(src.path, p.join(dst.path, 'out'));

      expect(await File(p.join(src.path, 'a.txt')).exists(), isTrue);
      expect(await File(p.join(src.path, 'a.txt')).readAsString(), before);
    });

    test('honours cancellation and leaves the source intact', () async {
      await File(p.join(src.path, 'a.txt')).writeAsString('a');
      await File(p.join(src.path, 'b.txt')).writeAsString('b');
      await File(p.join(src.path, 'c.txt')).writeAsString('c');
      var cancelled = false;

      await expectLater(
        copyDirectory(
          src.path,
          p.join(dst.path, 'out'),
          onProgress: (copied, total) {
            if (copied >= 1) cancelled = true;
          },
          isCancelled: () => cancelled,
        ),
        throwsA(isA<CopyCancelledException>()),
      );

      // All three source files remain.
      expect(await File(p.join(src.path, 'a.txt')).exists(), isTrue);
      expect(await File(p.join(src.path, 'b.txt')).exists(), isTrue);
      expect(await File(p.join(src.path, 'c.txt')).exists(), isTrue);
    });
  });
}
