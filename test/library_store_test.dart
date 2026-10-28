import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/ports.dart';

Game _game(
  int threadId, {
  String? title,
  String? installPath,
  String? launchPath,
  List<String>? tags,
  List<int>? tagIds,
  List<int>? prefixIds,
}) => Game(
  threadId: threadId,
  title: title ?? 'Game $threadId',
  creator: 'Creator $threadId',
  version: 'v0.0.1',
  latestVersion: 'v0.0.2',
  cover: 'https://example.com/cover-$threadId.png',
  screens: ['https://example.com/a.png', 'https://example.com/b.png'],
  tags: tags ?? const ['rpg', '3dcg'],
  tagIds: tagIds ?? const [45, 107],
  prefixIds: prefixIds ?? const [3],
  engine: 'Unity',
  developer: 'Dev $threadId',
  description: 'A description for $threadId.',
  installPath: installPath,
  launchPath: launchPath,
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 25),
);

void main() {
  late LibraryDatabase db;
  late DriftLibraryStore store;

  setUp(() {
    db = LibraryDatabase(NativeDatabase.memory());
    store = DriftLibraryStore(db);
  });

  tearDown(() => db.close());

  test('upsert + list + get round-trips every game field', () async {
    await store.upsertGame(_game(1));

    final list = await store.listGames();
    expect(list, hasLength(1));

    final game = await store.getGame(1);
    expect(game, isNotNull);
    expect(game!.threadId, 1);
    expect(game.title, 'Game 1');
    expect(game.creator, 'Creator 1');
    expect(game.version, 'v0.0.1');
    expect(game.latestVersion, 'v0.0.2');
    expect(game.cover, 'https://example.com/cover-1.png');
    expect(game.screens, ['https://example.com/a.png', 'https://example.com/b.png']);
    expect(game.tags, ['rpg', '3dcg']);
    expect(game.tagIds, [45, 107]);
    expect(game.prefixIds, [3]);
    expect(game.engine, 'Unity');
    expect(game.developer, 'Dev 1');
    expect(game.description, 'A description for 1.');
    expect(game.installPath, isNull);
    expect(game.createdAt, DateTime(2026, 10, 24));
    expect(game.updatedAt, DateTime(2026, 10, 25));
  });

  test('upsert on the same threadId updates rather than duplicates', () async {
    await store.upsertGame(_game(1, title: 'Old title'));
    await store.upsertGame(
      _game(1, title: 'New title', installPath: 'C:/games/1'),
    );

    final list = await store.listGames();
    expect(list, hasLength(1));
    expect(list.single.title, 'New title');
    expect(list.single.installPath, 'C:/games/1');
  });

  test('getGame returns null for an unknown threadId', () async {
    expect(await store.getGame(999), isNull);
  });

  test('launchPath round-trips and can be cleared', () async {
    await store.upsertGame(_game(1, launchPath: r'C:\games\1\Game.exe'));

    final withPath = await store.getGame(1);
    expect(withPath!.launchPath, r'C:\games\1\Game.exe');
    expect(withPath.hasLaunchPath, isTrue);

    await store.upsertGame(withPath.withLaunchPath(null));
    expect((await store.getGame(1))!.launchPath, isNull);
  });

  test('play sessions round-trip started/ended/duration', () async {
    final started = DateTime(2026, 10, 24, 20);
    final id = await store.addSession(
      PlaySession(threadId: 1, startedAt: started),
    );
    expect(id, greaterThan(0));

    var sessions = await store.sessionsFor(1);
    expect(sessions, hasLength(1));
    expect(sessions.single.id, id);
    expect(sessions.single.startedAt, started);
    expect(sessions.single.endedAt, isNull);
    expect(sessions.single.isRunning, isTrue);
    expect(await store.totalDuration(1), Duration.zero);

    await store.finishSession(id, started.add(const Duration(minutes: 90)));

    sessions = await store.sessionsFor(1);
    expect(sessions.single.endedAt, started.add(const Duration(minutes: 90)));
    expect(sessions.single.durationSeconds, 90 * 60);
    expect(sessions.single.duration, const Duration(minutes: 90));
    expect(await store.totalDuration(1), const Duration(minutes: 90));
    expect(await store.sessionsFor(2), isEmpty);
  });

  test('finishSession is a no-op for an unknown session id', () async {
    await store.finishSession(999, DateTime(2026, 10, 24));
    expect(await store.totalDuration(1), Duration.zero);
  });

  test('removing a game deletes its play sessions', () async {
    await store.upsertGame(_game(1));
    await store.addSession(
      PlaySession(threadId: 1, startedAt: DateTime(2026, 10, 24)),
    );

    await store.removeGame(1);

    expect(await store.sessionsFor(1), isEmpty);
    expect(await store.totalDuration(1), Duration.zero);
  });

  test('removeGame deletes only the matching game', () async {
    await store.upsertGame(_game(1));
    await store.upsertGame(_game(2));

    await store.removeGame(1);

    final list = await store.listGames();
    expect(list.map((g) => g.threadId), [2]);
  });

  test('addVersion + listVersions round-trips versions in order', () async {
    await store.addVersion(1, const Version(value: 'v1.0.0'));
    await store.addVersion(1, const Version(value: 'v1.1.0'));

    final versions = await store.listVersions(1);
    expect(versions.map((v) => v.value), ['v1.0.0', 'v1.1.0']);
    expect(await store.listVersions(2), isEmpty);
  });

  test('downloads CRUD round-trips status and progress', () async {
    final download = Download(
      gid: 'abc123',
      threadId: 1,
      status: DownloadStatus.active,
      progress: 0.5,
      targetDir: 'C:/downloads',
      createdAt: DateTime(2026, 10, 24),
      updatedAt: DateTime(2026, 10, 25),
    );
    await store.upsertDownload(download);

    final list = await store.listDownloads();
    expect(list, hasLength(1));

    final fetched = await store.getDownload('abc123');
    expect(fetched, isNotNull);
    expect(fetched!.gid, 'abc123');
    expect(fetched.threadId, 1);
    expect(fetched.status, DownloadStatus.active);
    expect(fetched.progress, 0.5);
    expect(fetched.targetDir, 'C:/downloads');

    await store.removeDownload('abc123');
    expect(await store.listDownloads(), isEmpty);
  });
}
