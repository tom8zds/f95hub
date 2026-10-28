import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../domain/models.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import 'cover_image.dart';
import 'format.dart';

/// A single game tile in the f95zone style: a 16:9 edge-to-edge cover with a
/// bottom→middle dark gradient carrying the title (ellipsized) and a version
/// chip, plus up to two lines of tag chips below the image.
///
/// Hovering (or keyboard-focusing) the card highlights it: the resting
/// [ColorScheme.outlineVariant] border animates to [ColorScheme.primary] and a
/// soft shadow lifts the tile — the desktop affordance the flat f95zone-style
/// card otherwise lacks.
class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.game,
    this.onTap,
    this.hasUpdate = false,
    this.onSecondaryTapUp,
  });

  final Game game;
  final VoidCallback? onTap;

  /// When true, a small "有更新" badge sits over the top-left of the cover
  /// (the library computes it from the catalogue index; the games page leaves
  /// it off).
  final bool hasUpdate;

  /// Right-click (secondary tap) with the global pointer position; hosts use
  /// it to open a context menu for this game.
  final void Function(Offset position)? onSecondaryTapUp;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _highlighted => _hovered || _focused;

  /// Version to display: the f95zone latest when known, else the local one.
  String get _version => widget.game.displayVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: _highlighted ? Colors.black26 : Colors.transparent,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          onSecondaryTapUp: widget.onSecondaryTapUp == null
              ? null
              : (details) => widget.onSecondaryTapUp!(details.globalPosition),
          borderRadius: BorderRadius.circular(AppRadius.card),
          onFocusChange: (value) => setState(() => _focused = value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edge-to-edge 16:9 cover with the dark gradient and title overlay.
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(url: widget.game.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: AppOverlay.coverGradient,
                          ),
                        ),
                      ),
                      // Hover scrim: a dark veil with the game's tags that
                      // fades in so the card reads as interactive (and the
                      // tags stay readable over any cover).
                      AnimatedOpacity(
                        opacity: _highlighted ? 1 : 0,
                        duration: AppDurations.fast,
                        child: _HoverScrim(tags: widget.game.tags),
                      ),
                      if (widget.hasUpdate)
                        Positioned(
                          left: AppSpacing.sm,
                          top: AppSpacing.sm,
                          child: _UpdateBadge(threadId: widget.game.threadId),
                        ),
                      // Adaptive "how long ago" stamp (3 分钟前 / 2 天前 …).
                      Positioned(
                        right: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _UpdatedAgoChip(
                          updatedAt: widget.game.updatedAt,
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        right: AppSpacing.sm,
                        bottom: 6,
                        child: Row(
                          children: [
                            Expanded(
                              child: Tooltip(
                                // The card ellipsizes long titles; hovering
                                // reveals the full name.
                                message: widget.game.title,
                                child: Text(
                                  widget.game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (_version.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _VersionChip(label: _version),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small version chip overlaid on the cover gradient.
class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppOverlay.onCover,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// The small "更新于多久之前" chip on a cover's top-right.
class _UpdatedAgoChip extends StatelessWidget {
  const _UpdatedAgoChip({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppOverlay.onCover,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        formatRelativeTime(context.t, updatedAt),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// The "有更新" pill overlaid on the top-left of a library cover.
class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({required this.threadId});

  /// The thread the badge belongs to, so tests can target one card.
  final int threadId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: Key('game-update-badge-$threadId'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_circle_up, size: 12, color: scheme.onPrimary),
          const SizedBox(width: 3),
          Text(
            context.t.library.hasUpdate,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

/// The hover veil: a dark scrim carrying the game's tags (two clipped lines,
/// the same treatment the cards used to show permanently below the cover).
class _HoverScrim extends StatelessWidget {
  const _HoverScrim({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0x66000000)),
          if (tags.isNotEmpty)
            // Bottom-anchored tag block, kept clear of the card's overlays:
            // the viewport starts above the title/version row (and a little
            // extra breathing room) instead of covering it. The Wrap lays
            // out at the real width so chips wrap, and the fixed-height
            // bottom-anchored viewport keeps only the last
            // [_TagLine.maxLines] lines.
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: _TagLine.bottomInset,
              height: _TagLine.height * _TagLine.maxLines,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Never grow past the top badge row: the cover minus the
                    // badge strip (top) and the title row (bottom) is the
                    // tag block's ceiling.
                    final ceiling =
                        constraints.maxHeight -
                        _TagLine.topInset -
                        _TagLine.bottomInset;
                    final height = (_TagLine.height * _TagLine.maxLines).clamp(
                      0.0,
                      ceiling,
                    );
                    return SizedBox(
                      height: height,
                      width: constraints.maxWidth,
                      child: OverflowBox(
                        alignment: Alignment.bottomLeft,
                        maxHeight: double.infinity,
                        // Width comes from the cover minus padding; the Wrap
                        // wraps against it (unbounded would kill wrapping).
                        maxWidth: constraints.maxWidth,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final tag in tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.chip,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Geometry of the scrim's tag block: one compact line's height, the line
/// cap, and the bottom inset that keeps the block clear of the title/
/// version row (`bottom: 6` + its text height + breathing room).
class _TagLine {
  static const double height = 22;

  static const int maxLines = 3;

  /// Distance from the cover's bottom to the tag block's bottom edge.
  static const double bottomInset = 34;

  /// Strip reserved at the cover's top for the update badge / time stamp.
  static const double topInset = 30;
}

// ---------------------------------------------------------------------------
// Widget previews
// ---------------------------------------------------------------------------

Game _previewGame({
  String title = 'Kunoichi Sensei',
  String version = 'v0.9.5',
  List<String> tags = const ['rpg', '3dcg', '2dcg'],
  String? cover,
}) => Game(
  threadId: 319855,
  title: title,
  creator: 'NTRNoob',
  version: version,
  cover: cover,
  tags: tags,
  createdAt: DateTime(2026, 10, 24),
  updatedAt: DateTime(2026, 10, 24),
);

Widget _cardPreview(Game game, {bool hasUpdate = false}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: GameCard(game: game, hasUpdate: hasUpdate, onTap: () {}),
      ),
    ),
  ),
);

/// Default card: cover art, title + version chip, one line of tags.
///
/// The preview cover is a stable sample image so the overlay treatment can be
/// judged against real art; offline it falls back to the placeholder.
@Preview(name: 'Default', group: 'GameCard', size: Size(320, 300))
Widget gameCardPreview() => _cardPreview(
  _previewGame(cover: 'https://picsum.photos/seed/f95hub/640/360'),
);

/// Long title (ellipsized) and enough tags to wrap onto two clipped lines.
@Preview(
  name: 'Long title + many tags',
  group: 'GameCard',
  size: Size(320, 300),
)
Widget gameCardLongPreview() => _cardPreview(
  _previewGame(
    title: 'Amelia and the Erotic Tentacle Trap Dungeon — Extended Cut',
    tags: const [
      'rpg',
      '3dcg',
      '2dcg',
      'ai cg',
      'sandbox',
      'fantasy',
      'male protagonist',
    ],
  ),
);

/// Library variant: the "有更新" badge over the top-left of the cover.
@Preview(name: 'Update badge', group: 'GameCard', size: Size(320, 300))
Widget gameCardUpdatePreview() => _cardPreview(_previewGame(), hasUpdate: true);

/// No cover URL / failed load: the themed placeholder treatment.
@Preview(name: 'Cover placeholder', group: 'GameCard', size: Size(320, 300))
Widget gameCardPlaceholderPreview() => _cardPreview(_previewGame(cover: null));
