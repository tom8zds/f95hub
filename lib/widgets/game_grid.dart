import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import 'empty_state.dart';
import 'game_card.dart';

/// A responsive grid of [GameCard]s.
///
/// Uses [SliverGridDelegateWithMaxCrossAxisExtent] so the column count grows
/// and shrinks with the window width while each card stays at most ~300px
/// wide ([_maxCardWidth]).
class GameGrid extends StatelessWidget {
  const GameGrid({
    super.key,
    required this.games,
    this.onTap,
    this.hasUpdate,
    this.onSecondaryTapUp,
    this.controller,
  });

  /// Cards never exceed this cross-axis extent; the grid derives the column
  /// count from the available width.
  static const double _maxCardWidth = 300;

  final List<Game> games;

  /// Optional scroll controller so hosts can reset the offset (e.g. on page
  /// changes).
  final ScrollController? controller;

  /// Called with the tapped game, if provided.
  final ValueChanged<Game>? onTap;

  /// Optional per-game update flag, forwarded to [GameCard.hasUpdate].
  final bool Function(Game game)? hasUpdate;

  /// Right-click on a card, with the game and the global pointer position
  /// (hosts open a context menu).
  final void Function(Game game, Offset position)? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return EmptyState(
        icon: Icons.videogame_asset,
        title: context.t.games.empty,
      );
    }
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _maxCardWidth,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        // Card = the 16:9 cover plus a hair of border padding — there is no
        // tag strip below it anymore, so the tile hugs the cover.
        childAspectRatio: 16 / 9,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCard(
          game: game,
          hasUpdate: hasUpdate?.call(game) ?? false,
          onTap: onTap == null ? null : () => onTap!(game),
          onSecondaryTapUp: onSecondaryTapUp == null
              ? null
              : (position) => onSecondaryTapUp!(game, position),
        );
      },
    );
  }
}
