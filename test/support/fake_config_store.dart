import 'package:f95hub/adapters/config_store.dart';
import 'package:f95hub/domain/config.dart';

/// In-memory [ConfigStore] for widget/state tests (no real file I/O, which
/// would not complete under `testWidgets`'s FakeAsync zone).
class FakeConfigStore extends ConfigStore {
  FakeConfigStore({this.toLoad});

  /// The config returned by [load] (null = first launch).
  Config? toLoad;

  /// The last config passed to [save].
  Config? saved;

  @override
  Future<Config?> load() async => toLoad;

  @override
  Future<void> save(Config config) async {
    saved = config;
  }
}
