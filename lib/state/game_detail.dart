import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import 'game_list.dart';

/// Immutable detail-page state: thread details + the tag table used to resolve
/// numeric ids to display names.
class GameDetailState {
  const GameDetailState({
    this.loading = false,
    this.error,
    this.thread,
    this.tagTable,
  });

  final bool loading;
  final Object? error;
  final ThreadDetail? thread;
  final TagTable? tagTable;

  GameDetailState copyWith({
    bool? loading,
    Object? error,
    ThreadDetail? thread,
    TagTable? tagTable,
  }) {
    return GameDetailState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      thread: thread ?? this.thread,
      tagTable: tagTable ?? this.tagTable,
    );
  }
}

/// Fetches a thread's description ([getThread]) and the static tag table
/// ([getTagTable]) for the detail page — one state per thread id, so several
/// detail tabs can coexist without stealing each other's data.
class GameDetailController extends Notifier<GameDetailState> {
  GameDetailController(this.threadId);

  /// The thread this per-tab instance loads.
  final int threadId;

  @override
  GameDetailState build() => const GameDetailState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    final source = ref.read(metadataSourceProvider);
    try {
      // Await both in parallel; Future.wait handles a failure of either.
      final results = await Future.wait<Object?>([
        source.getThread(threadId),
        source.getTagTable(),
      ]);
      state = state.copyWith(
        loading: false,
        thread: results[0] as ThreadDetail,
        tagTable: results[1] as TagTable,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}

final gameDetailProvider = NotifierProvider.family<
  GameDetailController,
  GameDetailState,
  int
>(GameDetailController.new);

/// Display names resolved from a game's numeric tag/prefix ids.
class ResolvedDetails {
  const ResolvedDetails({
    required this.tags,
    required this.categories,
    required this.engines,
  });

  final List<String> tags;

  /// Prefix names under the "Other" group (e.g. `VN`, `Collection`).
  final List<String> categories;

  /// Prefix names under the "Engine" group (e.g. `Unity`, `Ren'Py`).
  final List<String> engines;
}

/// Resolves [game]'s numeric tag/prefix ids to names via [table].
///
/// Prefixes are looked up per category ([GameCategory.games]); the "Other"
/// group maps to category and the "Engine" group maps to engine.
ResolvedDetails resolveGameDetails(Game game, TagTable table) {
  final prefixes = table.prefixesFor(GameCategory.games, game.prefixIds);

  return ResolvedDetails(
    tags: table.tagNamesFor(game.tagIds),
    categories: prefixes
        .where((p) => p.group == 'Other')
        .map((p) => p.name)
        .toList(growable: false),
    engines: prefixes
        .where((p) => p.group == 'Engine')
        .map((p) => p.name)
        .toList(growable: false),
  );
}
