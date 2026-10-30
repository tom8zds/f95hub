import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/config.dart';
import 'package:f95hub/i18n/i18n.dart';
import 'package:f95hub/theme/app_theme.dart';

void main() {
  test('presets map to distinct schemes', () {
    final schemes = ThemePreset.values.map(flexSchemeOf).toSet();
    expect(ThemePreset.values.length, 3);
    expect(schemes.length, 3);
    // The default preset is the f95zone red (black/red dark, white/red light).
    expect(flexSchemeOf(ThemePreset.material), FlexScheme.redM3);
  });

  test('every preset has a distinct, non-empty label', () {
    final t = AppLocale.en.buildSync();
    final labels =
        ThemePreset.values.map((preset) => themeLabelOf(preset, t)).toSet();
    expect(labels.length, 3);
    expect(labels.every((l) => l.isNotEmpty), isTrue);
  });

  // Theme construction resolves Google Fonts descriptors, which schedule
  // best-effort font loads on the test binding; `testWidgets` owns that async
  // work so the failures implied by offline tests do not leak between cases.
  testWidgets('buildThemes produces distinct light and dark color schemes',
      (tester) async {
    for (final preset in ThemePreset.values) {
      final themes = buildThemes(preset);
      expect(themes.light.brightness, Brightness.light);
      expect(themes.dark.brightness, Brightness.dark);
      expect(themes.light.colorScheme.brightness, Brightness.light);
      expect(themes.dark.colorScheme.brightness, Brightness.dark);
      // Light and dark variants differ.
      expect(
        themes.light.colorScheme.primary,
        isNot(themes.dark.colorScheme.primary),
      );
    }
  });

  testWidgets('buildThemes applies the CJK font family to both text themes',
      (tester) async {
    for (final preset in ThemePreset.values) {
      final themes = buildThemes(preset);
      for (final theme in [themes.light, themes.dark]) {
        final styles = <String, TextStyle?>{
          'displayLarge': theme.textTheme.displayLarge,
          'headlineMedium': theme.textTheme.headlineMedium,
          'titleLarge': theme.textTheme.titleLarge,
          'bodyLarge': theme.textTheme.bodyLarge,
          'bodyMedium': theme.textTheme.bodyMedium,
          'labelSmall': theme.textTheme.labelSmall,
        };
        styles.forEach((name, style) {
          expect(
            style?.fontFamily,
            startsWith(cjkFontFamily),
            reason: '${theme.brightness.name} $name should use the CJK family',
          );
          // The unqualified family is the fallback for glyphs missing from the
          // weight-specific family, so both scripts resolve to Noto Sans SC.
          expect(style?.fontFamilyFallback, contains(cjkFontFamily));
        });
      }
    }
  });

  testWidgets('colorSchemeOf matches the colors of the built themes',
      (tester) async {
    for (final preset in ThemePreset.values) {
      final themes = buildThemes(preset);
      expect(colorSchemeOf(preset), themes.light.colorScheme);
      expect(
        colorSchemeOf(preset, brightness: Brightness.dark),
        themes.dark.colorScheme,
      );
    }
  });

  testWidgets('swatch quadrants use the four scheme accent colors',
      (tester) async {
    final scheme = colorSchemeOf(ThemePreset.material);
    // All four quadrants are visually distinct accents.
    expect(
      {
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        scheme.error,
      }.length,
      4,
    );
  });

  test('materialThemeModeOf maps every persisted mode', () {
    expect(materialThemeModeOf(AppThemeMode.system), ThemeMode.system);
    expect(materialThemeModeOf(AppThemeMode.light), ThemeMode.light);
    expect(materialThemeModeOf(AppThemeMode.dark), ThemeMode.dark);
  });

  testWidgets('distinct presets yield distinct light primary colors',
      (tester) async {
    final primaries =
        ThemePreset.values.map((p) => buildThemes(p).light.colorScheme.primary).toSet();
    expect(primaries.length, 3);
  });
}
