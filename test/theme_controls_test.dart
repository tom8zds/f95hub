import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/config.dart';
import 'package:f95hub/widgets/theme_mode_toggle.dart';
import 'package:f95hub/widgets/theme_swatch_picker.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

double _borderWidth(WidgetTester tester, ThemePreset preset) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(ValueKey('theme_swatch_${preset.name}')),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return ((container.decoration! as BoxDecoration).border! as Border)
      .top
      .width;
}

void main() {
  testWidgets('swatch picker reports the tapped preset and highlights it',
      (tester) async {
    ThemePreset? selected;
    await tester.pumpWidget(
      _host(
        ThemeSwatchPicker(
          value: ThemePreset.material,
          onChanged: (preset) => selected = preset,
        ),
      ),
    );

    expect(find.byType(ThemeSwatch), findsNWidgets(3));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(_borderWidth(tester, ThemePreset.material), 3);
    expect(_borderWidth(tester, ThemePreset.green), 1);

    await tester.tap(find.byKey(const ValueKey('theme_swatch_green')));
    await tester.pump();

    expect(selected, ThemePreset.green);

    // Re-render with the new selection: the highlight moves.
    await tester.pumpWidget(
      _host(
        ThemeSwatchPicker(
          value: ThemePreset.green,
          onChanged: (preset) => selected = preset,
        ),
      ),
    );
    await tester.pump();

    expect(_borderWidth(tester, ThemePreset.green), 3);
    expect(_borderWidth(tester, ThemePreset.material), 1);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme_swatch_green')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('swatch picker golden', (tester) async {
    await tester.pumpWidget(
      _host(
        ThemeSwatchPicker(value: ThemePreset.blue, onChanged: (_) {}),
      ),
    );
    await expectLater(
      find.byType(ThemeSwatchPicker),
      matchesGoldenFile('goldens/theme_controls_swatch_picker.png'),
    );
  });

  testWidgets('toggle writes the opposite of the effective brightness',
      (tester) async {
    AppThemeMode? next;
    await tester.pumpWidget(
      _host(
        ThemeModeToggle(
          value: AppThemeMode.light,
          onChanged: (mode) => next = mode,
        ),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme_mode_toggle')));
    expect(next, AppThemeMode.dark);

    next = null;
    await tester.pumpWidget(
      _host(
        ThemeModeToggle(
          value: AppThemeMode.dark,
          onChanged: (mode) => next = mode,
        ),
      ),
    );
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme_mode_toggle')));
    expect(next, AppThemeMode.light);
  });

  testWidgets('system mode follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    AppThemeMode? next;
    await tester.pumpWidget(
      _host(
        ThemeModeToggle(
          value: AppThemeMode.system,
          onChanged: (mode) => next = mode,
        ),
      ),
    );

    // Dark is effective, so the button offers light.
    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme_mode_toggle')));
    expect(next, AppThemeMode.light);
  });

  testWidgets('toggle is a single icon button with an action tooltip',
      (tester) async {
    AppThemeMode? next;
    await tester.pumpWidget(
      _host(
        ThemeModeToggle(
          value: AppThemeMode.light,
          onChanged: (mode) => next = mode,
        ),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme_mode_toggle')));
    expect(next, AppThemeMode.dark);
  });

  testWidgets('theme mode toggle golden', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          child: Material(
            child: ThemeModeToggle(
              value: AppThemeMode.light,
              onChanged: _ignore,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(ThemeModeToggle),
      matchesGoldenFile('goldens/theme_controls_toggle.png'),
    );
  });
}

void _ignore(AppThemeMode mode) {}
