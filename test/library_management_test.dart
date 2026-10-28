import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/domain/library_management.dart';
import 'package:f95hub/widgets/version_side_by_side.dart';

void main() {
  group('versionsDiffer', () {
    test('flags a difference between local and latest', () {
      expect(
        versionsDiffer(version: 'v0.0.1', latestVersion: 'v0.0.2'),
        isTrue,
      );
    });

    test('is false when versions match', () {
      expect(
        versionsDiffer(version: 'v1.2', latestVersion: 'v1.2'),
        isFalse,
      );
    });

    test('is false when latest version is unknown', () {
      expect(versionsDiffer(version: 'v1.2', latestVersion: ''), isFalse);
    });

    test('trims whitespace before comparing', () {
      expect(
        versionsDiffer(version: ' v1 ', latestVersion: 'v1'),
        isFalse,
      );
    });
  });

  group('isWithinRoot', () {
    test('accepts the root itself', () {
      expect(isWithinRoot(r'C:\games', r'C:\games'), isTrue);
    });

    test('accepts a descendant', () {
      expect(isWithinRoot(r'C:\games', r'C:\games\game7'), isTrue);
    });

    test('rejects a sibling with a common prefix', () {
      expect(isWithinRoot(r'C:\games', r'C:\games_other\game'), isFalse);
    });

    test('rejects a path outside the root', () {
      expect(isWithinRoot(r'C:\games', r'C:\Users'), isFalse);
    });
  });

  group('deleteInstallFiles', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('f95hub_del_');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('deletes files inside the root', () async {
      final target = Directory(p.join(tempRoot.path, 'game7'));
      await target.create(recursive: true);
      await File(p.join(target.path, 'data.bin')).writeAsBytes([1, 2, 3]);

      await deleteInstallFiles(root: tempRoot.path, path: target.path);

      expect(await target.exists(), isFalse);
    });

    test('refuses to delete outside the root', () async {
      final outside = Directory(
        p.join(Directory.systemTemp.path, 'f95hub_outside_${DateTime.now().microsecondsSinceEpoch}'),
      );
      await outside.create(recursive: true);
      addTearDown(() async {
        if (await outside.exists()) await outside.delete(recursive: true);
      });

      await expectLater(
        deleteInstallFiles(root: tempRoot.path, path: outside.path),
        throwsArgumentError,
      );
      expect(await outside.exists(), isTrue);
    });

    test('refuses to delete when no root is configured', () async {
      final target = Directory(p.join(tempRoot.path, 'game7'));
      await target.create(recursive: true);

      await expectLater(
        deleteInstallFiles(root: null, path: target.path),
        throwsArgumentError,
      );
      expect(await target.exists(), isTrue);
    });
  });
}
