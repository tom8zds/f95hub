import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../adapters/game_index_mapping.dart';
import '../domain/import.dart';
import '../domain/models.dart';
import '../domain/scraper.dart';
import 'game_index.dart';
import 'library.dart';

/// Lifecycle phase of a single directory-import item.
enum ImportItemPhase { pending, moving, scraping, done, cancelled, failed }

/// Outcome of selecting a candidate in the left (unmatched) pane.
enum LeftMatchOutcome {
  /// Exactly one catalogue hit: the item was auto-matched into the right pane.
  matched,

  /// Several catalogue hits: the caller should open the game picker, then
  /// resolve with [DirectoryImportController.matchLeft].
  ambiguous,

  /// Nothing in the cache matched: the caller should open the game picker so
  /// the user can search manually; the item stays in the left pane until then.
  noMatch,
}

/// One candidate directory and its import progress.
class ImportItem {
  const ImportItem({
    required this.path,
    required this.name,
    this.phase = ImportItemPhase.pending,
    this.progress = 0,
    this.error,
    this.game,
    this.matchedGame,
  });

  final String path;
  final String name;

  final ImportItemPhase phase;

  /// Move completion ratio in `0.0 .. 1.0`.
  final double progress;

  final Object? error;

  /// The associated game once scraping has completed.
  final Game? game;

  /// The catalogue game matched from the folder name (auto-matched or picked
  /// manually); null while the item still sits in the left pane. Right-pane
  /// items always carry one, so batch import never asks again.
  final Game? matchedGame;

  ImportItem copyWith({
    ImportItemPhase? phase,
    double? progress,
    Object? error,
    Game? game,
    Game? matchedGame,
  }) {
    return ImportItem(
      path: path,
      name: name,
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      error: error,
      game: game ?? this.game,
      matchedGame: matchedGame ?? this.matchedGame,
    );
  }
}

/// Immutable directory-import state.
class DirectoryImportState {
  const DirectoryImportState({
    this.sourceDir,
    this.scanning = false,
    this.scanError,
    this.autoMatching = false,
    this.autoMatchTotal = 0,
    this.autoMatchDone = 0,
    this.left = const [],
    this.right = const [],
    this.lastBuiltPage = 0,
    this.totalPages = 0,
  });

  final String? sourceDir;
  final bool scanning;
  final Object? scanError;

  /// True while the automatic per-candidate catalogue pass is running.
  final bool autoMatching;

  /// Number of candidates the auto-match pass started with.
  final int autoMatchTotal;

  /// Number of candidates the auto-match pass has checked so far.
  final int autoMatchDone;

  /// Scanned candidates that are not matched yet (the left pane).
  final List<ImportItem> left;

  /// Matched candidates queued for import (the right pane).
  final List<ImportItem> right;

  /// The last fully cached catalogue page and the catalogue's total pages,
  /// read when the scan ran so the UI can warn that auto-matching may miss
  /// later letters.
  final int lastBuiltPage;
  final int totalPages;

  /// True while at least one right-pane item is being moved/scraped.
  bool get importing => right.any(
        (item) =>
            item.phase == ImportItemPhase.moving ||
            item.phase == ImportItemPhase.scraping,
      );

  DirectoryImportState copyWith({
    String? sourceDir,
    bool? scanning,
    Object? scanError,
    bool? autoMatching,
    int? autoMatchTotal,
    int? autoMatchDone,
    List<ImportItem>? left,
    List<ImportItem>? right,
    int? lastBuiltPage,
    int? totalPages,
  }) {
    return DirectoryImportState(
      sourceDir: sourceDir ?? this.sourceDir,
      scanning: scanning ?? this.scanning,
      scanError: scanError,
      autoMatching: autoMatching ?? this.autoMatching,
      autoMatchTotal: autoMatchTotal ?? this.autoMatchTotal,
      autoMatchDone: autoMatchDone ?? this.autoMatchDone,
      left: left ?? this.left,
      right: right ?? this.right,
      lastBuiltPage: lastBuiltPage ?? this.lastBuiltPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

/// Drives the two-pane directory-import flow: pick a source directory, scan its
/// depth-1 subdirectories into the left pane, then automatically match each
/// candidate the catalogue knows under exactly one hit (moving it into the
/// right pane); the rest stay left for manual matching. The right pane is then
/// batch-imported — each source folder is *moved* into the storage root and the
/// associated game is scraped into the library.
///
/// The auto-match pass and the moving batch both report per-item progress and
/// can be cancelled cooperatively; a source folder is only deleted once every
/// file landed in the target.
class DirectoryImportController extends Notifier<DirectoryImportState> {
  final Map<String, bool> _cancelled = {};
  bool _autoMatchCancelled = false;

  @override
  DirectoryImportState build() => const DirectoryImportState();

  /// Picks a source directory, scans it for candidates, then runs the
  /// automatic per-candidate match pass over the left pane.
  ///
  /// No-op when the picker is cancelled. Replaces any previous items. A
  /// candidate whose parsed title has exactly one catalogue hit is moved to
  /// the right pane; ambiguous and unknown candidates stay on the left for
  /// [selectLeft].
  Future<void> pickAndScan() async {
    final dir = await ref.read(directoryPickerProvider)();
    if (dir == null || dir.isEmpty) return;
    _autoMatchCancelled = false;
    state = state.copyWith(
      sourceDir: dir,
      scanning: true,
      scanError: null,
      autoMatching: false,
      autoMatchTotal: 0,
      autoMatchDone: 0,
      left: const [],
      right: const [],
    );
    try {
      final candidates = await scanDirectories(dir);
      final index = ref.read(gameIndexStoreProvider);
      final lastBuiltPage = await index.lastBuiltPage();
      final totalPages = await index.totalPages();
      final items = [
        for (final candidate in candidates)
          ImportItem(path: candidate.path, name: candidate.name),
      ];
      if (!ref.mounted) return;
      state = state.copyWith(
        scanning: false,
        left: items,
        lastBuiltPage: lastBuiltPage,
        totalPages: totalPages,
      );
      await _autoMatchLeft();
    } catch (e) {
      state = state.copyWith(scanning: false, autoMatching: false, scanError: e);
    }
  }

  /// Checks every left-pane candidate against the cached catalogue, one at a
  /// time, and moves the unique hits to the right pane as they are found.
  ///
  /// The pass yields on every catalogue query, so the UI keeps repainting and
  /// [state.left]/[state.right] shrink and grow progressively. It stops early
  /// when [cancelAutoMatch] is called or the provider is disposed; checked
  /// candidates that did not match exactly one game stay on the left.
  Future<void> _autoMatchLeft() async {
    final candidates = state.left.toList(growable: false);
    if (candidates.isEmpty) return;
    state = state.copyWith(
      autoMatching: true,
      autoMatchTotal: candidates.length,
      autoMatchDone: 0,
    );
    final index = ref.read(gameIndexStoreProvider);
    for (var i = 0; i < candidates.length; i++) {
      if (_autoMatchCancelled || !ref.mounted) break;
      final item = candidates[i];
      // The item may have been matched or removed manually while the pass ran.
      if (!state.left.any((left) => left.path == item.path)) {
        state = state.copyWith(autoMatchDone: i + 1);
        continue;
      }
      final title = parseFolderName(item.name).title;
      try {
        final matches = await index.search(title);
        if (!ref.mounted) return;
        if (_autoMatchCancelled) break;
        if (matches.length == 1) {
          matchLeft(item, gameFromIndexRow(matches.single));
        }
      } catch (_) {
        // A failed lookup leaves the candidate for manual matching instead of
        // aborting the whole pass.
        if (!ref.mounted) return;
      }
      state = state.copyWith(autoMatchDone: i + 1);
    }
    if (!ref.mounted) return;
    state = state.copyWith(autoMatching: false);
  }

  /// Requests cancellation of the running auto-match pass.
  ///
  /// The in-flight catalogue query is allowed to finish, but no further
  /// candidates are checked and the current one is not moved.
  void cancelAutoMatch() => _autoMatchCancelled = true;

  /// Searches the catalogue for [item]'s parsed title.
  ///
  /// Exactly one hit is auto-matched and moved to the right pane
  /// ([LeftMatchOutcome.matched]); several hits leave the choice to the caller
  /// ([LeftMatchOutcome.ambiguous]); none also leaves it to the caller
  /// ([LeftMatchOutcome.noMatch]).
  Future<LeftMatchOutcome> selectLeft(ImportItem item) async {
    final title = parseFolderName(item.name).title;
    final matches = await ref.read(gameIndexStoreProvider).search(title);
    if (!ref.mounted) return LeftMatchOutcome.noMatch;
    if (matches.isEmpty) {
      return LeftMatchOutcome.noMatch;
    }
    if (matches.length > 1) {
      return LeftMatchOutcome.ambiguous;
    }
    matchLeft(item, gameFromIndexRow(matches.single));
    return LeftMatchOutcome.matched;
  }

  /// Matches the left-pane [item] with [game] and moves it to the right pane.
  void matchLeft(ImportItem item, Game game) {
    final source = state.left.where((i) => i.path == item.path).firstOrNull;
    if (source == null) return;
    state = state.copyWith(
      left: state.left.where((i) => i.path != item.path).toList(growable: false),
      right: [
        ...state.right,
        source.copyWith(matchedGame: game),
      ],
    );
  }

  /// Moves the right-pane [item] back to the left pane, clearing its match.
  void removeRight(ImportItem item) {
    if (!state.right.any((i) => i.path == item.path)) return;
    final left = [
      ...state.left,
      ImportItem(path: item.path, name: item.name),
    ]..sort(_byName);
    state = state.copyWith(
      right: state.right.where((i) => i.path != item.path).toList(growable: false),
      left: left,
    );
  }

  /// Moves one candidate: its folder into
  /// `<storage root>/<safeFolderName(game.title)>/`, then scrapes [game] into
  /// the library with the moved path as [Game.installPath] and the local
  /// version parsed from the candidate's folder name.
  ///
  /// Refuses (without touching either side) when the target folder already
  /// exists, so a move can never merge into — or delete — an existing install.
  Future<void> import(String path, Game game) async {
    _cancelled[path] = false;
    _setItem(path, (item) => item.copyWith(
          phase: ImportItemPhase.moving,
          progress: 0,
          error: null,
          game: game,
        ));

    final root = ref.read(libraryRootProvider);
    if (root == null || root.trim().isEmpty) {
      _setItem(
        path,
        (item) => item.copyWith(
          phase: ImportItemPhase.failed,
          error: 'No storage directory configured',
        ),
      );
      return;
    }

    final dst = p.join(root.trim(), safeFolderName(game.title));
    try {
      await moveDirectory(
        path,
        dst,
        onProgress: (copied, total) => _setItem(
          path,
          (item) => item.copyWith(
            progress: total == 0 ? 1 : copied / total,
          ),
        ),
        isCancelled: () => _cancelled[path] ?? false,
      );
    } on CopyCancelledException {
      _setItem(path, (item) => item.copyWith(phase: ImportItemPhase.cancelled));
      return;
    } catch (e) {
      _setItem(
        path,
        (item) => item.copyWith(phase: ImportItemPhase.failed, error: e),
      );
      return;
    }

    _setItem(path, (item) => item.copyWith(phase: ImportItemPhase.scraping));
    try {
      final imported = await ref.read(libraryProvider.notifier).scrapeAndStore(
            game,
            installPath: dst,
            version: parseVersionFromName(path),
          );
      _setItem(
        path,
        (item) => item.copyWith(
          phase: ImportItemPhase.done,
          progress: 1,
          game: imported,
        ),
      );
    } catch (e) {
      _setItem(
        path,
        (item) => item.copyWith(phase: ImportItemPhase.failed, error: e),
      );
    }
  }

  /// Imports every right-pane item that has a match, in list order.
  ///
  /// Each item moves + scrapes + persists through [import], so per-item
  /// progress and cancellation still apply. A successfully imported item is
  /// removed from the right pane as soon as it finishes, so the list shrinks
  /// progressively and ends empty; failed and cancelled items stay, with their
  /// error, for a retry.
  Future<void> importRight() async {
    for (final item in state.right.toList(growable: false)) {
      if (item.phase == ImportItemPhase.done) continue;
      final game = item.matchedGame;
      if (game == null) continue;
      await import(item.path, game);
      if (!ref.mounted) return;
      final imported = state.right
          .where((right) => right.path == item.path)
          .firstOrNull;
      if (imported?.phase != ImportItemPhase.done) continue;
      state = state.copyWith(
        right: state.right
            .where((right) => right.path != item.path)
            .toList(growable: false),
      );
    }
  }

  /// Requests cancellation of the in-flight move for [path].
  void cancel(String path) => _cancelled[path] = true;

  /// Replaces the match for the right-pane [item] with a manually picked game.
  void setMatchedGame(String path, Game game) {
    _setItem(path, (item) => item.copyWith(matchedGame: game));
  }

  void _setItem(String path, ImportItem Function(ImportItem) update) {
    List<ImportItem> map(List<ImportItem> items) => items
        .map((item) => item.path == path ? update(item) : item)
        .toList(growable: false);
    state = state.copyWith(left: map(state.left), right: map(state.right));
  }
}

/// Stable case-insensitive ordering used when an item returns to the left pane.
int _byName(ImportItem a, ImportItem b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

final directoryImportProvider =
    NotifierProvider<DirectoryImportController, DirectoryImportState>(
  DirectoryImportController.new,
);
