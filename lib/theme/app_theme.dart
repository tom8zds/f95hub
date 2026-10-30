import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/config.dart';
import '../i18n/i18n.dart';

/// Family name of the CJK-friendly typeface (Noto Sans SC) applied to the
/// app's [TextTheme]s. The per-weight families Google Fonts resolves to all
/// start with this prefix, and "Noto Sans SC" is their glyph fallback.
const String cjkFontFamily = 'NotoSansSC';

/// Maps a [ThemePreset] to its [FlexScheme] color set (Material 3).
FlexScheme flexSchemeOf(ThemePreset preset) => switch (preset) {
      // The app's own black-and-red identity: the default preset is the
      // f95zone red, so a fresh install opens on the black/red (dark) and
      // white/red (light) pair rather than Material's purple baseline.
      ThemePreset.material => FlexScheme.redM3,
      ThemePreset.materialYou => FlexScheme.materialBaseline,
      ThemePreset.blue => FlexScheme.blueM3,
      ThemePreset.green => FlexScheme.greenM3,
      ThemePreset.red => FlexScheme.redM3,
    };

/// Localized label for each preset (shown in the settings selector).
String themeLabelOf(ThemePreset preset, Translations t) => switch (preset) {
      ThemePreset.material => t.theme.presets.material,
      ThemePreset.materialYou => t.theme.presets.materialYou,
      ThemePreset.blue => t.theme.presets.blue,
      ThemePreset.green => t.theme.presets.green,
      ThemePreset.red => t.theme.presets.red,
    };

/// Maps the persisted [AppThemeMode] to Flutter's [ThemeMode] for
/// `MaterialApp.themeMode`.
ThemeMode materialThemeModeOf(AppThemeMode mode) => switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

/// The [FlexColorScheme] source for [preset]; [buildThemes] and
/// [colorSchemeOf] share it so the swatches always show the colors the app
/// actually applies.
FlexColorScheme _flexSchemeOfPreset(
  ThemePreset preset,
  Brightness brightness,
) {
  final scheme = flexSchemeOf(preset);
  return brightness == Brightness.dark
      ? FlexColorScheme.dark(scheme: scheme, useMaterial3: true)
      : FlexColorScheme.light(scheme: scheme, useMaterial3: true);
}

final Map<(ThemePreset, Brightness), ColorScheme> _colorSchemeCache = {};

/// The [ColorScheme] for [preset] in [brightness], without building the full
/// [ThemeData] (and its font lookups). Cached: presets are a small fixed set.
///
/// Used by the theme swatches, which render each preset's primary / secondary
/// / tertiary / error colors.
ColorScheme colorSchemeOf(
  ThemePreset preset, {
  Brightness brightness = Brightness.light,
}) =>
    _colorSchemeCache.putIfAbsent(
      (preset, brightness),
      () => _flexSchemeOfPreset(preset, brightness).toTheme.colorScheme,
    );

/// Overrides every style in [base] with Noto Sans SC, a Google Font whose
/// Latin and Simplified Chinese glyphs share one design, so mixed UI strings
/// render consistently.
TextTheme cjkTextTheme(TextTheme base) =>
    GoogleFonts.notoSansScTextTheme(base);

/// Navigation-drawer theme: every property but the indicator width is the M3
/// default — 56 tile height, stadium shape, secondary-container fill, and the
/// default icon/label colors — so the destination's hover overlay and the
/// selected indicator share one shape and size.
///
/// The sidebar is 304 wide, narrower than Material's default 336 indicator, so
/// the only override is the width: infinity clamps the indicator to the tile
/// (the destination's Stack) instead of letting it overflow.
NavigationDrawerThemeData _drawerTheme() {
  return const NavigationDrawerThemeData(
    indicatorSize: Size(double.infinity, 56),
  );
}

/// Rounded, tonally filled inputs app-wide (M3 style): no harsh outlines,
/// a soft container fill and a primary ring on focus.
InputDecorationTheme _inputDecoration(ColorScheme scheme) {
  OutlineInputBorder border(Color? color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: width),
      );
  return InputDecorationTheme(
    filled: true,
    fillColor: scheme.surfaceContainerHigh,
    border: border(null),
    enabledBorder: border(null),
    focusedBorder: border(scheme.primary, 1.5),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.5),
  );
}

/// Builds the light + dark [ThemeData] pair for [preset] via [FlexColorScheme],
/// with the CJK typeface applied to both.
({ThemeData light, ThemeData dark}) buildThemes(ThemePreset preset) {
  final light = _flexSchemeOfPreset(preset, Brightness.light).toTheme;
  final dark = _flexSchemeOfPreset(preset, Brightness.dark).toTheme;
  return (
    light: light.copyWith(
      textTheme: cjkTextTheme(light.textTheme),
      inputDecorationTheme: _inputDecoration(light.colorScheme),
      drawerTheme: DrawerThemeData(
        backgroundColor: light.colorScheme.surfaceContainerLow,
      ),
      navigationDrawerTheme: _drawerTheme(),
    ),
    dark: dark.copyWith(
      textTheme: cjkTextTheme(dark.textTheme),
      inputDecorationTheme: _inputDecoration(dark.colorScheme),
      drawerTheme: DrawerThemeData(
        backgroundColor: dark.colorScheme.surfaceContainerLow,
      ),
      navigationDrawerTheme: _drawerTheme(),
    ),
  );
}
