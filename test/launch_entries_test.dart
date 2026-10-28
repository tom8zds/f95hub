import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:f95hub/domain/launch_entries.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('f95hub_scan_');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<String> write(String relative) async {
    final file = File(p.join(root.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString('');
    return p.normalize(file.path);
  }

  test('finds .exe/.bat case-insensitively, top level first then sorted',
      () async {
    final game = await write('game.EXE');
    final launcher = await write('launcher.bat');
    final helper = await write('bin/helper.exe');
    await write('readme.txt');

    final entries = await scanLaunchEntries(root.path);

    expect(entries, [game, launcher, helper]);
  });

  test('skips system and hidden directories', () async {
    final game = await write('Game.exe');
    await write('windows/evil.exe');
    await write('system32/evil.exe');
    await write(r'$RECYCLE.BIN/old.exe');
    await write('.git/hooks/hook.exe');

    final entries = await scanLaunchEntries(root.path);

    expect(entries, [game]);
  });

  test('maxDepth limits the walk', () async {
    final shallow = await write('one/two/game.exe');
    await write('one/two/three/deep.exe');

    expect(await scanLaunchEntries(root.path, maxDepth: 2), [shallow]);
    expect(
      await scanLaunchEntries(root.path, maxDepth: 3),
      hasLength(2),
    );
  });

  test('maxCount caps the result', () async {
    for (final name in ['a.exe', 'b.exe', 'c.exe', 'd.exe', 'e.exe']) {
      await write(name);
    }

    expect(await scanLaunchEntries(root.path, maxCount: 2), hasLength(2));
    expect(await scanLaunchEntries(root.path, maxCount: 0), isEmpty);
  });

  test('returns an empty list for a missing install folder', () async {
    expect(
      await scanLaunchEntries(p.join(root.path, 'nope')),
      isEmpty,
    );
  });

  group('defaultLaunchEntry', () {
    test('picks 与工具一同启动.bat by basename', () {
      final entries = [
        r'C:\games\game7\Game.exe',
        r'C:\games\game7\与工具一同启动.bat',
      ];

      expect(defaultLaunchEntry(entries), r'C:\games\game7\与工具一同启动.bat');
    });

    test('matches case-insensitively in a nested folder', () {
      final entries = [
        r'C:\games\game7\Game.exe',
        r'C:\games\game7\bin\与工具一同启动.BAT',
      ];

      expect(defaultLaunchEntry(entries), r'C:\games\game7\bin\与工具一同启动.BAT');
    });

    test('returns null when no entry matches', () {
      final entries = [
        r'C:\games\game7\Game.exe',
        r'C:\games\game7\launcher.bat',
      ];

      expect(defaultLaunchEntry(entries), isNull);
      expect(defaultLaunchEntry(const []), isNull);
    });

    test('does not match a different filename containing the text', () {
      expect(
        defaultLaunchEntry([r'C:\games\game7\与工具一同启动(备份).bat']),
        isNull,
      );
    });

    test('finds the default bat in a real scan', () async {
      await write('Game.exe');
      final bat = await write('与工具一同启动.bat');

      expect(defaultLaunchEntry(await scanLaunchEntries(root.path)), bat);
    });
  });
}
