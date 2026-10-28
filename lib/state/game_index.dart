import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/game_index_codec.dart';
import '../adapters/game_index_store.dart';
import 'game_list.dart';
import 'library.dart';

/// Loads the catalogue snapshot bundled inside the app (`null` when absent —
/// e.g. a build shipped without an export). Fresh installs seed their empty
/// index from it instead of crawling every page; tests override this.
final gameIndexSeedAssetProvider =
    Provider<Future<Uint8List?> Function()>((ref) => _loadBundledSnapshot);

Future<Uint8List?> _loadBundledSnapshot() async {
  try {
    final data = await rootBundle.load('assets/game_index.json.gz');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } on Exception {
    // AssetNotFoundError (or anything else): no snapshot bundled.
    return null;
  }
}

/// The [GameIndexStore] used by the app: the shared library database plus the
/// live metadata source. Tests override this with an in-memory store.
final gameIndexStoreProvider = Provider<GameIndexStore>((ref) {
  return GameIndexStore(
    ref.watch(libraryDatabaseProvider),
    ref.watch(metadataSourceProvider),
  );
});

/// Immutable game-index state: the cached row count, the last refresh time,
/// the full-build resume point, and progress of a running build/refresh.
class GameIndexState {
  const GameIndexState({
    this.count = 0,
    this.lastUpdated,
    this.busy = false,
    this.page = 0,
    this.total = 0,
    this.lastBuiltPage = 0,
    this.totalPages = 0,
    this.error,
  });

  final int count;
  final DateTime? lastUpdated;
  final bool busy;

  /// 1-based page of the running operation (`0` before the first page).
  final int page;

  /// Total pages of the running operation (`0` until known).
  final int total;

  /// Last page a full build finished writing (`0` when never built).
  final int lastBuiltPage;

  /// Total catalogue pages the last build saw (`0` when never built).
  final int totalPages;

  final Object? error;

  bool get hasCache => count > 0;

  /// True when a full build has written every page the catalogue had.
  bool get complete => totalPages > 0 && lastBuiltPage >= totalPages;

  static const _keep = Object();

  /// Sentinel-based copy: pass `lastUpdated: null` / `error: null` to clear.
  GameIndexState copyWith({
    int? count,
    Object? lastUpdated = _keep,
    bool? busy,
    int? page,
    int? total,
    int? lastBuiltPage,
    int? totalPages,
    Object? error = _keep,
  }) {
    return GameIndexState(
      count: count ?? this.count,
      lastUpdated: identical(lastUpdated, _keep)
          ? this.lastUpdated
          : lastUpdated as DateTime?,
      busy: busy ?? this.busy,
      page: page ?? this.page,
      total: total ?? this.total,
      lastBuiltPage: lastBuiltPage ?? this.lastBuiltPage,
      totalPages: totalPages ?? this.totalPages,
      error: identical(error, _keep) ? this.error : error,
    );
  }
}

/// Drives the settings-page cache block: loads the current index stats and
/// runs create (full build) / refresh (incremental) / delete (clear).
class GameIndexController extends Notifier<GameIndexState> {
  bool _cancelRequested = false;

  /// Completed by [cancel]; raced against every in-flight page request so a
  /// cache operation stops immediately instead of after the current request
  /// (or a 429 backoff) finishes. Null while idle.
  Completer<void>? _cancelSignal;

  @override
  GameIndexState build() => const GameIndexState();

  GameIndexStore get _store => ref.read(gameIndexStoreProvider);

  /// Reloads the cached count, last-updated stamp and build resume point.
  ///
  /// An empty index is first seeded from the bundled snapshot (best effort:
  /// any failure leaves the stats untouched), so a fresh install starts with
  /// the full catalogue instead of nothing.
  Future<void> loadStats() async {
    try {
      var count = await _store.count();
      if (count == 0) {
        count = await _seedFromBundle();
      }
      final lastUpdated = await _store.lastUpdated();
      final lastBuiltPage = await _store.lastBuiltPage();
      final totalPages = await _store.totalPages();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        count: count,
        lastUpdated: lastUpdated,
        lastBuiltPage: lastBuiltPage,
        totalPages: totalPages,
        error: null,
      );
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(error: e);
      }
    }
  }

  /// Seeds an empty index from the bundled snapshot; returns the row count
  /// afterwards (0 when there was nothing to seed or it failed).
  Future<int> _seedFromBundle() async {
    try {
      final bytes = await ref.read(gameIndexSeedAssetProvider)();
      if (bytes == null || bytes.isEmpty) {
        return 0;
      }
      return await _store.seed(decodeGameIndexSnapshot(bytes));
    } catch (_) {
      // A broken/missing snapshot must never break the page.
      return 0;
    }
  }

  /// Builds the full catalogue index (all pages, title order).
  Future<void> buildAll() => _run(_store.buildAll);

  /// Merges the newest [GameIndexStore.incrementalPages] pages into the index.
  Future<void> refreshIncremental() => _run(_store.refreshIncremental);

  /// Asks the running operation to stop immediately.
  ///
  /// The flag stops the loop at the next page boundary; completing the signal
  /// also aborts an in-flight request (and any 429 backoff) right away.
  void cancel() {
    if (!state.busy) {
      return;
    }
    _cancelRequested = true;
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
  }

  /// Empties the index and reloads the stats.
  Future<void> clear() async {
    if (state.busy) {
      return;
    }
    try {
      await _store.clear();
      await loadStats();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(error: e);
      }
    }
  }

  Future<void> _run(
    Future<int> Function({
      GameIndexProgress? onProgress,
      GameIndexCancelCheck? isCancelled,
      Future<void>? cancelSignal,
    }) task,
  ) async {
    if (state.busy) {
      return;
    }
    _cancelRequested = false;
    final cancelSignal = Completer<void>();
    _cancelSignal = cancelSignal;
    state = state.copyWith(busy: true, page: 0, total: 0, error: null);

    try {
      await task(
        onProgress: (page, total, count) {
          if (ref.mounted) {
            state = state.copyWith(
              page: page,
              total: total,
              count: count,
              lastBuiltPage: page,
              totalPages: total,
            );
          }
        },
        isCancelled: () => _cancelRequested,
        cancelSignal: cancelSignal.future,
      );
      await loadStats();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(error: e);
      }
    } finally {
      if (identical(_cancelSignal, cancelSignal)) {
        _cancelSignal = null;
      }
      if (ref.mounted) {
        state = state.copyWith(busy: false, page: 0, total: 0);
      }
    }
  }
}

final gameIndexProvider = NotifierProvider<GameIndexController, GameIndexState>(
  GameIndexController.new,
);
