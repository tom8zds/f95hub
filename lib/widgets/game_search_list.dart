import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/game_index_mapping.dart';
import '../adapters/game_index_store.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../state/game_index.dart';
import 'game_search_results.dart';

/// Search field + result list for picking a game from the local game index.
///
/// Shared by the manual-import dialog and the directory-import associate
/// dialog. f95zone has no server-side search (research 01 §2.5), so the
/// catalogue is searched in the local [GameIndexStore]: results are instant,
/// span the whole cached catalogue, and match on the normalized title (so
/// `secret care cafe` finds `Secret Care Cafe [v0.9.5] [Rare Alex]`).
///
/// An empty query lists the first [browseLimit] titles; typing runs the index
/// search after [searchDebounce]. An empty cache shows [GameIndexEmptyHint]
/// instead of a misleading "no matches".
class GameSearchList extends ConsumerStatefulWidget {
  const GameSearchList({
    super.key,
    required this.onSelect,
    this.busyThreadId,
    this.header,
    this.initialQuery,
  });

  /// Called with the tapped [Game].
  final ValueChanged<Game> onSelect;

  /// Thread currently being imported; tiles are disabled while non-null.
  final int? busyThreadId;

  /// Optional widget rendered between the search field and the results (the
  /// manual-import dialog uses this for its local-version field).
  final Widget? header;

  /// Pre-fills the search field with a guessed title (the directory-import
  /// associate flow guesses from the folder name); still editable so the
  /// manual-search escape hatch remains.
  final String? initialQuery;

  /// Delay between the last keystroke and the local index query.
  static const searchDebounce = Duration(milliseconds: 250);

  /// Rows listed for the empty-query state.
  static const browseLimit = 50;

  @override
  ConsumerState<GameSearchList> createState() => _GameSearchListState();
}

class _GameSearchListState extends ConsumerState<GameSearchList> {
  String _query = '';
  List<Game>? _games;
  bool _indexEmpty = false;
  int _lastBuiltPage = 0;
  int _totalPages = 0;
  Set<int> _exactThreadIds = const {};
  Object? _error;
  Timer? _debounce;
  late final TextEditingController _controller;

  /// Monotonic request id; stale index results (a slower earlier query) are
  /// discarded instead of flickering over a newer one.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Reads the cache size (to distinguish an empty index from no matches) and
  /// then runs the initial query.
  Future<void> _load() async {
    setState(() {
      _games = null;
      _error = null;
    });
    final request = ++_request;
    try {
      final store = ref.read(gameIndexStoreProvider);
      final count = await store.count();
      final lastBuiltPage = await store.lastBuiltPage();
      final totalPages = await store.totalPages();
      if (!mounted || request != _request) {
        return;
      }
      setState(() {
        _indexEmpty = count == 0;
        _lastBuiltPage = lastBuiltPage;
        _totalPages = totalPages;
      });
      await _search(_query, request: request);
    } catch (e) {
      if (!mounted || request != _request) {
        return;
      }
      setState(() => _error = e);
    }
  }

  Future<void> _search(String query, {int? request}) async {
    final id = request ?? ++_request;
    final store = ref.read(gameIndexStoreProvider);
    try {
      final rows = query.trim().isEmpty
          ? await store.browse(limit: GameSearchList.browseLimit)
          : await store.search(query);
      if (!mounted || id != _request) {
        return;
      }
      // An exact normalized title match is floated above the looser contains
      // hits and highlighted, so a guessed folder name lands on the right row
      // instead of somewhere in the middle of the list.
      final needle = GameIndexStore.normalizeTitle(query);
      final exact = <Game>[];
      final rest = <Game>[];
      final exactIds = <int>{};
      for (final row in rows) {
        final game = gameFromIndexRow(row);
        if (needle.isNotEmpty && row.normalizedTitle == needle) {
          exact.add(game);
          exactIds.add(row.threadId);
        } else {
          rest.add(game);
        }
      }
      setState(() {
        _games = [...exact, ...rest];
        _exactThreadIds = exactIds;
        _error = null;
      });
    } catch (e) {
      if (!mounted || id != _request) {
        return;
      }
      setState(() => _error = e);
    }
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(GameSearchList.searchDebounce, () => _search(_query));
  }

  void _submit(String value) {
    _debounce?.cancel();
    _search(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: context.t.games.searchByTitle,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (_totalPages > 0 && _lastBuiltPage < _totalPages) ...[
          const SizedBox(height: 8),
          GameIndexCompletenessHint(
            lastBuiltPage: _lastBuiltPage,
            totalPages: _totalPages,
          ),
        ],
        if (widget.header != null) ...[
          const SizedBox(height: 8),
          widget.header!,
        ],
        const SizedBox(height: 8),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _results() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.games.indexLoadFailed),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _load,
              child: Text(context.t.common.retry),
            ),
          ],
        ),
      );
    }
    final games = _games;
    if (games == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_indexEmpty) {
      return const GameIndexEmptyHint();
    }
    if (games.isEmpty) {
      return const GameSearchNoMatches();
    }
    return GameSearchResults(
      games: games,
      onSelect: widget.onSelect,
      busyThreadId: widget.busyThreadId,
      highlightedThreadIds: _exactThreadIds,
    );
  }
}
