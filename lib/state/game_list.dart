import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/f95zone_metadata_source.dart';
import '../domain/config.dart';
import '../domain/ports.dart';
import 'config.dart';

/// Overridable metadata source. Tests inject a [FakeMetadataSource] by
/// overriding this provider.
///
/// The request pacing comes from the saved config, so changing 抓取间隔 in the
/// settings re-creates the source with the new [Config.requestIntervalMs].
final metadataSourceProvider = Provider<MetadataSource>((ref) {
  // Select just the pacing field: watching the whole config would recreate the
  // source — and reset the listing — on unrelated changes such as the theme.
  final intervalMs = ref.watch(
    configProvider.select((s) => s.config?.requestIntervalMs),
  );
  return F95zoneMetadataSource(
    requestInterval: Duration(
      milliseconds: intervalMs ?? Config.defaultRequestIntervalMs,
    ),
  );
});

/// Client-side title filter predicate: case-insensitive substring match.
///
/// An empty/blank [query] matches everything (no filtering). Shared by the
/// games listing and the manual import dialog.
bool titleMatches(String title, String query) {
  final needle = query.trim().toLowerCase();
  return needle.isEmpty || title.toLowerCase().contains(needle);
}

/// Immutable listing state: accumulated pages, current sort, server-side
/// filters (tags/prefixes/date), the local title filter, and a 429 throttle
/// flag.
class GameListState {
  const GameListState({
    this.games = const [],
    this.sort = SortOrder.date,
    this.page = 0,
    this.totalPages = 0,
    this.hasMore = true,
    this.loading = false,
    this.error,
    this.query = '',
    this.selectedTags = const {},
    this.selectedPrefixes = const {},
    this.date,
    this.tagTable,
    this.throttled = false,
  });

  /// All games loaded so far (every page fetched so far, in order).
  final List<Game> games;

  final SortOrder sort;

  /// 1-based page number of the last loaded page (`0` before the first load).
  final int page;

  /// Total page count reported by the server (`0` until the first load).
  final int totalPages;

  /// Whether more pages remain on the server.
  final bool hasMore;

  /// True while the first page (or a sort-triggered reload) is in flight.
  final bool loading;

  final Object? error;

  /// Raw local title filter text (client-side, matches spec "按标题本地过滤").
  final String query;

  /// Numeric tag ids to filter on (server-side AND filter).
  final Set<int> selectedTags;

  /// Numeric prefix ids to filter on (server-side AND filter, multi-select).
  final Set<int> selectedPrefixes;

  /// "Last N days" window (server-side `date`), or null for anytime.
  final int? date;

  /// Static id→name table used to render filter options; null until loaded.
  final TagTable? tagTable;

  /// True while the metadata source is backing off from a 429 and retrying.
  final bool throttled;

  /// Games after the local title filter is applied.
  List<Game> get filteredGames =>
      games.where((g) => titleMatches(g.title, query)).toList(growable: false);

  GameListState copyWith({
    List<Game>? games,
    SortOrder? sort,
    int? page,
    int? totalPages,
    bool? hasMore,
    bool? loading,
    Object? error,
    String? query,
    Set<int>? selectedTags,
    Set<int>? selectedPrefixes,
    Object? date = _unset,
    TagTable? tagTable,
    bool? throttled,
  }) {
    return GameListState(
      games: games ?? this.games,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      query: query ?? this.query,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedPrefixes: selectedPrefixes ?? this.selectedPrefixes,
      date: identical(date, _unset) ? this.date : date as int?,
      tagTable: tagTable ?? this.tagTable,
      throttled: throttled ?? this.throttled,
    );
  }
}

/// Sentinel so `copyWith` can distinguish "clear to null" from "unset" for the
/// nullable [GameListState.date] field.
const Object _unset = Object();

/// Drives the games listing: first-page load, pagination, server-side sort and
/// filters, and the local title filter.
class GameListController extends Notifier<GameListState> {
  StreamSubscription<bool>? _throttleSub;

  @override
  GameListState build() {
    final source = ref.watch(metadataSourceProvider);
    _throttleSub = source.throttled.listen((value) {
      state = state.copyWith(throttled: value);
    });
    ref.onDispose(() => _throttleSub?.cancel());
    return const GameListState();
  }

  MetadataSource get _source => ref.read(metadataSourceProvider);

  /// Requests page [n] (1-based) using the current sort + server-side filters.
  Future<GameListPage> _fetchPage(int n) => _source.listGames(
        GameCategory.games,
        tags: state.selectedTags.isEmpty ? null : state.selectedTags.toList(),
        prefixes: state.selectedPrefixes.isEmpty
            ? null
            : state.selectedPrefixes.toList(),
        sort: state.sort,
        date: state.date,
        page: n,
      );

  /// Replaces the listing with [page], resolving tag ids through [table].
  void _applyPage(GameListPage page, TagTable table) {
    state = state.copyWith(
      games: [for (final g in page.items) g.withResolvedTags(table)],
      page: page.page,
      totalPages: page.totalPages,
      hasMore: page.page < page.totalPages,
      loading: false,
      tagTable: table,
    );
  }

  /// Loads (or reloads) the first page using the current sort + filters, and
  /// refreshes the static tag table for the filter options.
  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait<Object?>([
        _fetchPage(1),
        _source.getTagTable(),
      ]);
      _applyPage(results[0] as GameListPage, results[1] as TagTable);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Re-fetches the *current* page from the network, bypassing the source's
  /// in-memory cache, and refreshes the static tag table.
  ///
  /// Unlike [load] this keeps [GameListState.page] (unless nothing is loaded
  /// yet), along with the sort, tag/prefix filters, date window, and local
  /// title query. No-op while a load is already in flight.
  Future<void> refresh() async {
    if (state.loading) {
      return;
    }
    _source.clearCache();
    final target = state.page < 1 ? 1 : state.page;
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait<Object?>([
        _fetchPage(target),
        _source.getTagTable(),
      ]);
      _applyPage(results[0] as GameListPage, results[1] as TagTable);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Loads page [n] (1-based), *replacing* the current games list rather than
  /// appending. No-op if [n] is out of range or a load is already in flight.
  Future<void> goToPage(int n) async {
    if (n < 1 || n == state.page || state.loading) {
      return;
    }
    if (state.totalPages > 0 && n > state.totalPages) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      // Resolve tag ids against the cached table (fetching it on first use).
      final table = state.tagTable ?? await _source.getTagTable();
      _applyPage(await _fetchPage(n), table);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Advances to the next page (no-op at the last page).
  Future<void> nextPage() async {
    if (state.page < state.totalPages) {
      await goToPage(state.page + 1);
    }
  }

  /// Returns to the previous page (no-op at the first page).
  Future<void> prevPage() async {
    if (state.page > 1) {
      await goToPage(state.page - 1);
    }
  }

  /// Switches the server-side sort and reloads from the first page.
  Future<void> setSort(SortOrder sort) async {
    if (state.sort == sort) {
      return;
    }
    state = state.copyWith(
      sort: sort,
      games: const [],
      page: 0,
      hasMore: true,
    );
    await load();
  }

  /// Updates the local title filter.
  ///
  /// Filtering stays client-side, but the view is reset to page 1 so the
  /// filtered results start from the top (reloading page 1 when not already
  /// there). On page 1 the filter applies with no network round-trip.
  void setQuery(String query) {
    state = state.copyWith(query: query);
    if (state.page > 1) {
      goToPage(1);
    }
  }

  /// Sets the tag filter (server-side AND filter) and reloads.
  Future<void> setTags(Set<int> tags) async {
    state = state.copyWith(selectedTags: tags, games: const [], page: 0, hasMore: true);
    await load();
  }

  /// Sets the prefix filter (server-side AND filter, multi-select) and reloads.
  Future<void> setPrefixes(Set<int> prefixes) async {
    state = state.copyWith(
      selectedPrefixes: prefixes,
      games: const [],
      page: 0,
      hasMore: true,
    );
    await load();
  }

  /// Sets the "last N days" window and reloads (null = anytime).
  Future<void> setDate(int? date) async {
    state = state.copyWith(date: date, games: const [], page: 0, hasMore: true);
    await load();
  }
}

final gameListProvider = NotifierProvider<GameListController, GameListState>(
  GameListController.new,
);
