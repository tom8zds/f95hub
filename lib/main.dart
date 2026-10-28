import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/config.dart';
import 'i18n/i18n.dart';
import 'pages/config_wizard_page.dart';
import 'pages/home_shell.dart';
import 'state/config.dart';
import 'state/game_index.dart';
import 'state/image_cache.dart';
import 'state/session.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme.dart';

void main() {
  ensurePluralResolvers();
  // Image hosts sit behind the same Cloudflare gate as the metadata API;
  // route all default image caching through the authed manager.
  installAuthedImageCache();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ensurePluralResolvers();
    // Reactive: the theme and language follow the persisted config, so a
    // selection in the settings page rebuilds the MaterialApp and applies
    // immediately.
    final config = ref.watch(configProvider).config;
    final preset = config?.theme ?? ThemePreset.material;
    final mode = config?.themeMode ?? AppThemeMode.system;
    final locale = appLocaleOf(config?.language ?? AppLanguage.system);
    // Keep slang's global locale in sync with the persisted preference. The
    // TranslationProvider below rebuilds its subtree once the swap completes.
    if (LocaleSettings.currentLocale != locale) {
      LocaleSettings.setLocaleSync(locale);
    }
    final themes = buildThemes(preset);
    return TranslationProvider(
      child: MaterialApp(
        title: 'f95hub',
        locale: Locale(locale.languageCode, locale.countryCode),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        scrollBehavior: const AppScrollBehavior(),
        theme: themes.light,
        darkTheme: themes.dark,
        themeMode: materialThemeModeOf(mode),
        home: const _Root(),
      ),
    );
  }
}

/// Chooses between the first-launch wizard, a loading/error state, and the
/// main shell based on whether a config has been loaded.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(configProvider.notifier).load());
    // Seed an empty game index from the bundled catalogue snapshot at
    // startup, so library update detection and offline search work before
    // the user ever opens the cache settings.
    Future.microtask(
      () => ref.read(gameIndexProvider.notifier).loadStats(),
    );
    // Trigger the session controller: it restores the persisted cookie and
    // applies it to the metadata source.
    ref.read(sessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configProvider);

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t.app.loadConfigFailed),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.read(configProvider.notifier).load(),
                child: Text(context.t.common.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (!state.configured) {
      return const ConfigWizardPage();
    }
    return const HomeShell();
  }
}
