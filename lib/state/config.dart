import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/config_store.dart';
import '../domain/config.dart';

/// The [ConfigStore] used by the app (file-backed in the support directory).
/// Tests override this with a store pointed at a temp directory.
final configStoreProvider = Provider<ConfigStore>(
  (ref) => ConfigStore(),
);

/// Immutable config state: loading flag, the loaded [Config] (null before the
/// wizard completes), and a load/save [error].
class ConfigState {
  const ConfigState({this.config, this.loading = true, this.error});

  final Config? config;
  final bool loading;
  final Object? error;

  /// True once a config has been loaded or saved.
  bool get configured => config != null;

  ConfigState copyWith({Config? config, bool? loading, Object? error}) {
    return ConfigState(
      config: config ?? this.config,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

/// Loads and saves the app config. Drives the first-launch wizard: the root
/// widget shows the wizard while `configured` is false and no error occurred.
class ConfigController extends Notifier<ConfigState> {
  @override
  ConfigState build() => const ConfigState();

  /// Loads the saved config (called once at startup).
  Future<void> load() async {
    state = const ConfigState();
    try {
      final config = await ref.read(configStoreProvider).load();
      state = ConfigState(loading: false, config: config);
    } catch (e) {
      state = ConfigState(loading: false, error: e);
    }
  }

  /// Persists [config] and marks the app as configured.
  Future<void> save(Config config) async {
    await ref.read(configStoreProvider).save(config);
    state = ConfigState(loading: false, config: config);
  }
}

final configProvider = NotifierProvider<ConfigController, ConfigState>(
  ConfigController.new,
);
