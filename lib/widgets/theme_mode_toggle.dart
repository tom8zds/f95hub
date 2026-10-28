import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/config.dart';
import '../i18n/i18n.dart';
import '../state/config.dart';

/// A single light/dark icon button.
///
/// Presentational: [value] is the persisted preference, [onChanged] receives
/// the opposite of the currently effective brightness (never [AppThemeMode
/// .system]). A [value] of [AppThemeMode.system] is rendered as the platform
/// brightness, which is what `MaterialApp` resolves it to.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  bool _isDark(BuildContext context) => switch (value) {
        AppThemeMode.dark => true,
        AppThemeMode.light => false,
        AppThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  void _toggle(BuildContext context) {
    onChanged(_isDark(context) ? AppThemeMode.light : AppThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final action = dark
        ? context.t.theme.switchToLight
        : context.t.theme.switchToDark;
    return IconButton(
      key: const ValueKey('theme_mode_toggle'),
      icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
      tooltip: action,
      onPressed: () => _toggle(context),
    );
  }
}

/// Binds [ThemeModeToggle] to the persisted config: flips light ↔ dark and
/// writes [Config.themeMode] through [ConfigController], whose state rebuilds
/// `MaterialApp` immediately.
class ThemeModeSwitcher extends ConsumerWidget {
  const ThemeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(configProvider).config?.themeMode ?? AppThemeMode.system;
    return ThemeModeToggle(
      value: mode,
      onChanged: (next) {
        final config = ref.read(configProvider).config;
        if (config == null) return;
        ref
            .read(configProvider.notifier)
            .save(config.copyWith(themeMode: next));
      },
    );
  }
}
