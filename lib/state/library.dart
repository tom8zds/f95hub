import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../adapters/app_launcher.dart';
import '../adapters/drift_library_store.dart';
import '../adapters/library_database.dart';
import '../domain/library_management.dart';
import '../domain/launch_entries.dart';
import '../domain/ports.dart';
import '../domain/scraper.dart';
import 'config.dart';
import 'game_list.dart';

/// Picks a directory from the OS (wrapped so tests can override it).
typedef DirectoryPicker = Future<String?> Function();

/// The OS directory picker (file_selector). Overridden in tests.
final directoryPickerProvider = Provider<DirectoryPicker>(
  (ref) => () => getDirectoryPath(),
);

/// Wall clock used to stamp play sessions. Overridden in tests so a session's
/// `startedAt`/`endedAt`/duration are deterministic.
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// The [AppLauncher] used to open folders. Tests inject a fake to verify
/// routing.
final appLauncherProvider = Provider<AppLauncher>(
  (ref) => const ProcessAppLauncher(),
);

/// The [ProcessRunner] used to launch games and observe their exit. Tests
/// inject a fake whose `exitCode` future they complete by hand.
final processRunnerProvider = Provider<ProcessRunner>(
  (ref) => const SystemProcessRunner(),
);

/// Scans an install folder for `.exe`/`.bat` launch entries.
///
/// Wrapped in a provider so widget tests can return a fixed list instead of
/// driving real filesystem I/O through the fake-async test zone.
typedef LaunchEntryScanner = Future<List<String>> Function(String installPath);

final launchEntryScannerProvider = Provider<LaunchEntryScanner>(
  (ref) => (installPath) => scanLaunchEntries(installPath),
);

/// The configured library root: the directory under which game installs live.
///
/// Taken from the configured storage directory, falling back to the download
/// directory when no storage directory has been set. Delete-files refuses to
/// touch anything outside this root. It is `null` until one of the two is
/// configured; with no root, destructive deletes are refused rather than
/// guessed.
final libraryRootProvider = Provider<String?>((ref) {
  final storageDir = ref.watch(
    configProvider.select((s) => s.config?.storageDir),
  );
  final downloadDir = ref.watch(
    configProvider.select((s) => s.config?.downloadDir),
  );
  return storageDir ?? downloadDir;
});

/// The drift database shared by the library store and the game index cache.
/// Tests override this with `LibraryDatabase(NativeDatabase.memory())`.
final libraryDatabaseProvider = Provider<LibraryDatabase>((ref) {
  final db = LibraryDatabase(_openConnection());
  ref.onDispose(db.close);
  return db;
});

/// The [LibraryStore] used by the app: drift over a file-backed SQLite db in
/// the platform's application-support directory. Tests override this with an
/// in-memory database.
final libraryStoreProvider = Provider<LibraryStore>(
  (ref) => DriftLibraryStore(ref.watch(libraryDatabaseProvider)),
);

/// Total playtime plus the session list for one library game, reloaded
/// whenever a launch starts/finishes (see [LibraryController.launch]).
final playStatsProvider = FutureProvider.family<PlayStats, int>((ref, threadId) async {
  final store = ref.watch(libraryStoreProvider);
  final sessions = await store.sessionsFor(threadId);
  final total = await store.totalDuration(threadId);
  return PlayStats(total: total, sessions: sessions);
});

/// Aggregate playtime across the whole library, for the dashboard.
///
/// Re-runs when the library changes (added/removed games) and when
/// `_invalidateStats` fires after a session finishes, so the totals stay live.
final libraryPlaytimeProvider = FutureProvider<LibraryPlaytime>((ref) async {
  ref.watch(libraryProvider);
  final store = ref.watch(libraryStoreProvider);
  return store.playtime();
});

/// Opens the database lazily so the (async) support-directory lookup happens
/// only on first real use, never in tests (which override [libraryStoreProvider]).
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'f95hub.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Immutable library-page state.
class LibraryState {
  const LibraryState({this.games = const [], this.loading = false, this.error});

  final List<Game> games;
  final bool loading;
  final Object? error;

  LibraryState copyWith({List<Game>? games, bool? loading, Object? error}) {
    return LibraryState(
      games: games ?? this.games,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

/// A game launch that has started a process.
///
/// [exitCode] completes when the process quits; [done] completes once the play
/// session has been closed (its `endedAt`/duration persisted). The UI ignores
/// [done] — a game may run for hours — while tests await it for determinism.
class LaunchHandle {
  const LaunchHandle({required this.exitCode, required this.done});

  final Future<int> exitCode;
  final Future<void> done;
}

/// Drives the library page and the shared "scrape + persist" flow used by both
/// the detail-page "加入库" button and manual import.
class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() => const LibraryState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final games = await ref.read(libraryStoreProvider).listGames();
      state = state.copyWith(loading: false, games: games);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Scrapes [listing] into a library [Game] and persists it, then reloads.
  ///
  /// Returns the persisted game. The thread's description and the tag table are
  /// fetched from [MetadataSource]; [installPath] is set for manual imports and
  /// [version] overrides the locally installed version (defaults to the
  /// listing's).
  Future<Game> scrapeAndStore(
    Game listing, {
    String? installPath,
    String? version,
  }) async {
    final source = ref.read(metadataSourceProvider);
    final thread = await source.getThread(listing.threadId);
    final table = await source.getTagTable();
    final game = scrapeToLibraryGame(
      listing,
      thread,
      table,
      installPath: installPath,
      version: version,
    );
    await ref.read(libraryStoreProvider).upsertGame(game);
    await refresh();
    return game;
  }

  /// Removes a game from the library, optionally deleting its local files.
  ///
  /// [deleteFiles] triggers a guarded `Directory.delete` of the install path:
  /// the path must sit under [libraryRootProvider] (see
  /// `deleteInstallFiles`), so a corrupted `installPath` can never cascade
  /// into deleting unrelated user data.
  Future<void> remove(
    Game game, {
    required bool deleteFiles,
  }) async {
    if (deleteFiles) {
      final installPath = game.installPath;
      if (installPath != null && installPath.isNotEmpty) {
        await deleteInstallFiles(
          root: ref.read(libraryRootProvider),
          path: installPath,
        );
      }
    }
    await ref.read(libraryStoreProvider).removeGame(game.threadId);
    await refresh();
  }

  /// Opens the game's install folder in the OS file manager.
  Future<void> openFolder(Game game) async {
    final path = game.installPath;
    if (path == null || path.isEmpty) {
      return;
    }
    await ref.read(appLauncherProvider).openFolder(path);
  }

  /// Persists [launchPath] as [game]'s remembered launch entry (cleared when
  /// null/blank) and reloads the library so the detail page reflects it.
  Future<void> setLaunchPath(Game game, String? launchPath) async {
    await ref
        .read(libraryStoreProvider)
        .upsertGame(game.withLaunchPath(launchPath));
    await refresh();
  }

  /// Persists [version] as the locally installed version of the game with
  /// [threadId] and reloads the library.
  ///
  /// The value is free text (never parsed or ordered) and may be empty, which
  /// clears the local version. A thread that is not in the library is a no-op.
  Future<void> setVersion(int threadId, String version) async {
    final store = ref.read(libraryStoreProvider);
    final game = await store.getGame(threadId);
    if (game == null) {
      return;
    }
    await store.upsertGame(game.withVersion(version));
    await refresh();
  }

  /// Launches [game]'s remembered launch entry (or [executablePath]) and
  /// records a play session.
  ///
  /// The session is inserted as soon as the process starts; its `endedAt` and
  /// duration are written once [RunningProcess.exitCode] completes, in the
  /// background (the caller gets a [LaunchHandle] immediately). Returns null
  /// when there is nothing to launch.
  Future<LaunchHandle?> launch(Game game, {String? executablePath}) async {
    final path = executablePath ?? game.launchPath;
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    final runner = ref.read(processRunnerProvider);
    final process = await runner.start(path);

    final store = ref.read(libraryStoreProvider);
    final sessionId = await store.addSession(
      PlaySession(
        threadId: game.threadId,
        startedAt: ref.read(clockProvider)(),
      ),
    );
    _invalidateStats(game.threadId);

    final done = () async {
      await process.exitCode;
      await store.finishSession(sessionId, ref.read(clockProvider)());
      _invalidateStats(game.threadId);
    }();
    return LaunchHandle(exitCode: process.exitCode, done: done);
  }

  void _invalidateStats(int threadId) {
    ref.invalidate(playStatsProvider(threadId));
    ref.invalidate(libraryPlaytimeProvider);
  }
}

final libraryProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);
