/// Pure configuration model for f95hub: no I/O, no Flutter dependencies.
///
/// This is the *persistable* shape written to the on-disk `config.json`.
/// It deliberately holds **no secrets**: the aria2 RPC secret and the f95zone
/// session cookie stay in memory only and are never serialized here.
library;

/// The five built-in color themes the app offers. Serialized by [name], so
/// values are stable across releases (never reorder or rename an entry).
enum ThemePreset {
  material,
  materialYou,
  blue,
  green,
  red;

  /// Parses a persisted [name], falling back to [material] for unknown or
  /// legacy values so older config files keep loading.
  static ThemePreset fromName(String? name) {
    for (final preset in values) {
      if (preset.name == name) {
        return preset;
      }
    }
    return ThemePreset.material;
  }
}

/// Light/dark preference of the app shell. Serialized by [name], so values
/// are stable across releases. [system] follows the platform brightness.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Parses a persisted [name], falling back to [system] for unknown or
  /// missing values so older config files keep loading.
  static AppThemeMode fromName(String? name) {
    for (final mode in values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return AppThemeMode.system;
  }
}

/// The app's UI language. [system] follows the platform locale (falling back
/// to English); the explicit values pin the app to that language.
/// Serialized by [name], so values are stable across releases.
enum AppLanguage {
  system,
  en,
  zh;

  /// Parses a persisted [name], falling back to [system] for unknown or
  /// missing values so older config files keep loading.
  static AppLanguage fromName(String? name) {
    for (final language in values) {
      if (language.name == name) {
        return language;
      }
    }
    return AppLanguage.system;
  }
}

/// The app's persistent, non-secret settings.
class Config {
  const Config({
    this.downloadDir,
    this.storageDir,
    this.theme = ThemePreset.material,
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
    this.requestIntervalMs = defaultRequestIntervalMs,
  });

  /// Default minimum gap between two f95zone requests (2 s): the site answers
  /// 429 after roughly a dozen back-to-back requests (research 01 §5.2).
  static const int defaultRequestIntervalMs = 2000;

  /// Download/install directory (`--dir` for aria2).
  final String? downloadDir;

  /// Storage root: the directory under which the library lives (game installs
  /// are copied here on import). When unset, the library root falls back to
  /// [downloadDir]. Non-secret; persisted.
  final String? storageDir;

  /// The selected color theme (one of [ThemePreset]). Non-secret; persisted.
  final ThemePreset theme;

  /// Light/dark preference ([AppThemeMode]). Non-secret; persisted.
  final AppThemeMode themeMode;

  /// UI language ([AppLanguage]). Non-secret; persisted.
  final AppLanguage language;

  /// Minimum gap between two f95zone requests, in milliseconds. Non-secret;
  /// persisted.
  final int requestIntervalMs;

  /// Serializes to JSON. Only non-secret fields are ever written.
  Map<String, dynamic> toJson() => {
        if (downloadDir != null) 'downloadDir': downloadDir,
        if (storageDir != null) 'storageDir': storageDir,
        'theme': theme.name,
        'themeMode': themeMode.name,
        'language': language.name,
        'requestIntervalMs': requestIntervalMs,
      };

  /// Parses a previously-saved [Config]. Missing/unknown keys fall back to
  /// defaults so older config files keep loading.
  factory Config.fromJson(Map<String, dynamic> json) => Config(
        downloadDir: json['downloadDir'] as String?,
        storageDir: json['storageDir'] as String?,
        theme: ThemePreset.fromName(json['theme'] as String?),
        themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
        language: AppLanguage.fromName(json['language'] as String?),
        requestIntervalMs: (json['requestIntervalMs'] as num?)?.toInt() ??
            defaultRequestIntervalMs,
      );

  /// Sentinel letting nullable fields be *cleared* to null in [copyWith].
  static const Object _unset = Object();

  Config copyWith({
    Object? downloadDir = _unset,
    Object? storageDir = _unset,
    ThemePreset? theme,
    AppThemeMode? themeMode,
    AppLanguage? language,
    int? requestIntervalMs,
  }) {
    return Config(
      downloadDir:
          identical(downloadDir, _unset) ? this.downloadDir : downloadDir as String?,
      storageDir:
          identical(storageDir, _unset) ? this.storageDir : storageDir as String?,
      theme: theme ?? this.theme,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      requestIntervalMs: requestIntervalMs ?? this.requestIntervalMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Config &&
      other.downloadDir == downloadDir &&
      other.storageDir == storageDir &&
      other.theme == theme &&
      other.themeMode == themeMode &&
      other.language == language &&
      other.requestIntervalMs == requestIntervalMs;

  @override
  int get hashCode => Object.hash(
        downloadDir,
        storageDir,
        theme,
        themeMode,
        language,
        requestIntervalMs,
      );
}
