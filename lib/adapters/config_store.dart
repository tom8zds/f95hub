import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/config.dart';

/// Resolves the directory holding `config.json` (injectable for tests).
typedef ConfigDirProvider = Future<Directory> Function();

/// Loads and saves the app's [Config] as `config.json` in the platform's
/// application-support directory.
///
/// Only non-secret fields are persisted (see [Config]); the aria2 RPC secret
/// and the f95zone session cookie never reach this file.
class ConfigStore {
  ConfigStore({ConfigDirProvider? dirProvider})
      : _dirProvider = dirProvider ?? _defaultDir;

  final ConfigDirProvider _dirProvider;

  static const String fileName = 'config.json';

  static Future<Directory> _defaultDir() => getApplicationSupportDirectory();

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, fileName));
  }

  /// Returns the saved config, or null when none exists yet (first launch).
  Future<Config?> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return Config.fromJson(decoded);
  }

  /// Persists [config], creating the directory if needed.
  Future<void> save(Config config) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(config.toJson()));
  }
}
