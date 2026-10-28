import 'package:flutter/material.dart';

import '../domain/config.dart';
import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

/// A single rounded-square theme swatch.
///
/// The square is split into four quadrants showing [preset]'s primary,
/// secondary, tertiary and error colors (top-left, top-right, bottom-left,
/// bottom-right). The active preset gets a thicker primary-colored border and
/// a check badge. Tapping the swatch selects the preset.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  /// Edge length of the rounded square, including its border.
  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final scheme = colorSchemeOf(preset, brightness: theme.brightness);
    final label = themeLabelOf(preset, context.t);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: ValueKey('theme_swatch_${preset.name}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: selected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SwatchQuadrants(scheme: scheme),
                  if (selected)
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 2×2 color grid inside a [ThemeSwatch].
class _SwatchQuadrants extends StatelessWidget {
  const _SwatchQuadrants({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget cell(Color color) => Expanded(child: ColoredBox(color: color));
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cell(scheme.primary), cell(scheme.secondary)],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cell(scheme.tertiary), cell(scheme.error)],
          ),
        ),
      ],
    );
  }
}

/// Horizontal row of [ThemeSwatch]es, one per [ThemePreset].
class ThemeSwatchPicker extends StatelessWidget {
  const ThemeSwatchPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemePreset value;
  final ValueChanged<ThemePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final preset in ThemePreset.values)
          ThemeSwatch(
            preset: preset,
            selected: preset == value,
            onTap: () => onChanged(preset),
          ),
      ],
    );
  }
}
