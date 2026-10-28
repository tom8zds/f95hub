import 'package:flutter/widgets.dart';

import '../domain/config.dart';
import 'translations.g.dart';

export 'translations.g.dart'
    show
        AppLocale,
        AppLocaleUtils,
        InheritedLocaleData,
        LocaleSettings,
        TranslationProvider,
        Translations;

bool _pluralResolversConfigured = false;

/// Registers the CLDR plural resolver for Chinese, which slang does not ship
/// with. Chinese has a single plural category ("other"), so every count maps
/// to the `other` form.
void ensurePluralResolvers() {
  if (_pluralResolversConfigured) {
    return;
  }
  _pluralResolversConfigured = true;
  LocaleSettings.setPluralResolverSync(
    language: 'zh',
    cardinalResolver: (n, {zero, one, two, few, many, other}) => other ?? '$n',
  );
}

/// Resolves the persisted [AppLanguage] to a slang locale. [AppLanguage.system]
/// follows the platform locale, falling back to the base locale (English).
AppLocale appLocaleOf(AppLanguage language) => switch (language) {
      AppLanguage.en => AppLocale.en,
      AppLanguage.zh => AppLocale.zh,
      AppLanguage.system => AppLocaleUtils.findDeviceLocale(),
    };

/// Translations accessor for widget `build` methods.
///
/// Uses the [TranslationProvider] inherited widget, so the widget rebuilds when
/// the language changes at runtime. Falls back to the current global
/// translations when rendered without a provider (isolated component tests).
extension AppTranslations on BuildContext {
  Translations get t =>
      dependOnInheritedWidgetOfExactType<
              InheritedLocaleData<AppLocale, Translations>>()
          ?.translations ??
      LocaleSettings.instance.currentTranslations;
}
