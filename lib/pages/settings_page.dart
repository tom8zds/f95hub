import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/config.dart';
import '../i18n/i18n.dart';
import '../state/config.dart';
import '../state/game_index.dart';
import '../state/library.dart';
import '../state/session.dart';
import '../widgets/cache_section.dart';
import '../theme/tokens.dart';
import '../widgets/page_frame.dart';
import '../widgets/settings_section.dart';
import '../widgets/theme_swatch_picker.dart';

/// App settings: the storage directory and the f95zone session. Every change is
/// written through immediately ([ConfigStore] for the non-secret config,
/// memory-only for the session cookie) so downstream providers (the library
/// root) refresh live.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.leading});

  /// Optional leading widget for the page's title bar (a drawer hamburger in
  /// the shell's narrow layout).
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider).config;
    final session = ref.watch(sessionProvider);

    return PageFrame(
      leading: leading,
      title: context.t.settings.title,
      loading: ref.watch(gameIndexProvider).busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ThemeSection(
            value: config?.theme ?? ThemePreset.material,
            onChanged: (v) => _save(ref, (c) => c.copyWith(theme: v)),
          ),
          const SizedBox(height: 16),
          LanguageSection(
            value: config?.language ?? AppLanguage.system,
            onChanged: (v) => _save(ref, (c) => c.copyWith(language: v)),
          ),
          const SizedBox(height: 16),
          StorageDirSection(
            value: config?.storageDir,
            fallback: config?.downloadDir,
            onBrowse: () => _pickStorageDir(ref),
          ),
          const SizedBox(height: 16),
          const CacheSettingsSection(),
          const SizedBox(height: 16),
          FetchIntervalSection(
            intervalMs: config?.requestIntervalMs ??
                Config.defaultRequestIntervalMs,
            onChanged: (ms) => _save(
              ref,
              (c) => c.copyWith(requestIntervalMs: ms),
            ),
          ),
          const SizedBox(height: 16),
          LoginSection(
            session: session,
            onLogin: (cookie) =>
                ref.read(sessionProvider.notifier).login(cookie),
            onLogout: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStorageDir(WidgetRef ref) async {
    final dir = await ref.read(directoryPickerProvider)();
    if (dir != null) {
      _save(ref, (c) => c.copyWith(storageDir: dir));
    }
  }

  /// Applies [transform] to the current config and persists the result.
  void _save(WidgetRef ref, Config Function(Config) transform) {
    final current = ref.read(configProvider).config ?? const Config();
    ref.read(configProvider.notifier).save(transform(current));
  }
}

/// Color theme picker: one rounded four-color swatch per [ThemePreset].
/// Selecting a swatch persists it immediately, and the app's `MaterialApp`
/// rebuilds its [ThemeData] from the new preset live.
class ThemeSection extends StatelessWidget {
  const ThemeSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemePreset value;
  final ValueChanged<ThemePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: context.t.settings.theme,
      child: ThemeSwatchPicker(value: value, onChanged: onChanged),
    );
  }
}

/// UI-language picker: follows the system locale or pins the app to one of the
/// supported languages. Selecting an option persists it immediately, and the
/// root `MaterialApp` rebuilds with the new locale.
class LanguageSection extends StatelessWidget {
  const LanguageSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SettingsSection(
      title: t.settings.language,
      // Chips instead of a dropdown: three options stay visible at once.
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final option in AppLanguage.values)
            ChoiceChip(
              key: Key('language-chip-${option.name}'),
              label: Text(switch (option) {
                AppLanguage.system => t.languages.system,
                AppLanguage.en => t.languages.en,
                AppLanguage.zh => t.languages.zh,
              }),
              selected: option == value,
              onSelected: (_) => onChanged(option),
            ),
        ],
      ),
    );
  }
}

/// Storage-directory picker: the current path (or the download-directory
/// fallback when unset) plus a "Browse" button. Selecting a directory persists
/// immediately, repointing the library root.
class StorageDirSection extends StatelessWidget {
  const StorageDirSection({
    super.key,
    required this.value,
    required this.fallback,
    required this.onBrowse,
  });

  final String? value;
  final String? fallback;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final hasStorage = value != null && value!.isNotEmpty;
    final fallbackText =
        fallback == null || fallback!.isEmpty ? t.common.none : fallback!;

    return SettingsSection(
      title: t.settings.storage.title,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStorage ? value! : t.settings.storage.none,
                  overflow: TextOverflow.ellipsis,
                  style: hasStorage
                      ? null
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                ),
                if (!hasStorage)
                  Text(
                    t.settings.storage.fallback(path: fallbackText),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.folder_open),
            label: Text(t.common.browse),
          ),
        ],
      ),
    );
  }
}

/// f95zone request pacing: the minimum gap between two catalogue requests.
///
/// Persisted as milliseconds ([Config.requestIntervalMs]) but edited in
/// seconds; the metadata source is rebuilt with the new interval immediately.
class FetchIntervalSection extends StatelessWidget {
  const FetchIntervalSection({
    super.key,
    required this.intervalMs,
    required this.onChanged,
  });

  final int intervalMs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SettingsSection(
      title: t.settings.network.title,
      child: TextFormField(
        initialValue: _secondsLabel(intervalMs),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: t.settings.network.fetchInterval,
          helperText: t.settings.network.fetchIntervalHelp,
          isDense: true,
        ),
        onChanged: (value) {
          final seconds = double.tryParse(value.trim());
          if (seconds != null && seconds >= 0) {
            onChanged((seconds * 1000).round());
          }
        },
      ),
    );
  }

  /// `2000` → `2`, `1500` → `1.5`: no trailing `.0` for whole seconds.
  static String _secondsLabel(int ms) {
    final seconds = ms / 1000;
    return seconds == seconds.roundToDouble()
        ? seconds.round().toString()
        : seconds.toString();
  }
}

/// f95zone session: shows whether the app is logged in, and offers login
/// (pasted session cookie) and logout.
class LoginSection extends StatefulWidget {
  const LoginSection({
    super.key,
    required this.session,
    required this.onLogin,
    required this.onLogout,
  });

  /// The current in-memory session cookie, or null when logged out.
  final String? session;
  final Future<void> Function(String cookie) onLogin;
  final VoidCallback onLogout;

  @override
  State<LoginSection> createState() => _LoginSectionState();
}

class _LoginSectionState extends State<LoginSection> {
  String _cookie = '';
  bool _busy = false;

  Future<void> _login() async {
    final cookie = _cookie.trim();
    if (cookie.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onLogin(cookie);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final loggedIn = widget.session != null;

    return SettingsSection(
      title: t.settings.login.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                loggedIn ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: loggedIn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                loggedIn
                    ? t.settings.login.loggedIn
                    : t.settings.login.notLoggedIn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              if (loggedIn)
                OutlinedButton(
                  onPressed: widget.onLogout,
                  child: Text(t.buttons.logOut),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _cookie,
            decoration: InputDecoration(
              labelText: t.settings.login.sessionCookie,
              helperText: t.settings.login.sessionCookieHelp,
              isDense: true,
            ),
            onChanged: (v) => _cookie = v,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.buttons.logIn),
          ),
        ],
      ),
    );
  }
}
