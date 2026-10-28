import 'package:flutter/material.dart';

/// Design tokens shared across the app's widgets.
///
/// Widgets take spacing, corner radii, animation durations, and image-overlay
/// colors from here (or from the active [ThemeData]) instead of hand-picked
/// literals, so the visual rhythm stays consistent and re-tunable from one
/// place.

/// Spacing scale on a 4pt grid — the only paddings/gaps widgets should use.
abstract final class AppSpacing {
  /// 4 — icon gaps, chip innards.
  static const double xs = 4;

  /// 8 — tight element gaps, chip padding.
  static const double sm = 8;

  /// 12 — grid gutters, list paddings.
  static const double md = 12;

  /// 16 — page padding, section separation.
  static const double lg = 16;

  /// 24 — roomy sections, dialog padding.
  static const double xl = 24;

  /// 32 — major separations.
  static const double xxl = 32;
}

/// Corner radii. Cards and cover images share [card]; small overlays placed on
/// art (chips, badges) use [chip].
abstract final class AppRadius {
  /// 8 — chips, badges, small overlays.
  static const double chip = 8;

  /// 12 — cards, cover images, tiles.
  static const double card = 12;

  /// 28 — the dashboard's big expressive cards.
  static const double cardXL = 28;
}

/// Durations for micro-animations (hover, press, fade-in).
abstract final class AppDurations {
  /// Hover/highlight transitions: fast enough to feel attached to the cursor.
  static const Duration fast = Duration(milliseconds: 120);

  /// Content transitions (fade-in, skeleton shimmer sweeps).
  static const Duration medium = Duration(milliseconds: 200);
}

/// Colors for content laid over cover art (title scrims, chips, badges).
///
/// These stay near-black in every theme: they sit on photographs, where theme
/// surface colors would hurt legibility.
abstract final class AppOverlay {
  /// Bottom→center scrim behind a card title (see [GameCard]).
  static const List<Color> coverGradient = [
    Color(0xDD000000), // 87% black
    Color(0x8A000000), // 54% black
    Colors.transparent,
  ];

  /// Fill for chips and badges placed on cover art.
  static const Color onCover = Color(0x73000000); // 45% black
}
