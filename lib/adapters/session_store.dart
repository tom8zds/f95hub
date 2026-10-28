import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the directory holding `session.json` (injectable for tests).
typedef SessionDirProvider = Future<Directory> Function();

/// Persists the f95zone session cookie as `session.json` in the platform's
/// application-support directory, so a login survives a restart.
///
/// The file lives outside the repository (app-data dir); it is created with
/// owner-only permissions where the platform supports them. Only the cookie
/// is stored — no other credentials.
class SessionStore {
  SessionStore({SessionDirProvider? dirProvider})
      : _dirProvider = dirProvider ?? _defaultDir;

  final SessionDirProvider _dirProvider;

  static const String fileName = 'session.json';

  static Future<Directory> _defaultDir() => getApplicationSupportDirectory();

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, fileName));
  }

  /// Returns the persisted cookie, or null when nobody is logged in.
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final cookie = decoded['cookie'];
    if (cookie is! String || cookie.isEmpty) {
      return null;
    }
    return cookie;
  }

  /// Persists [cookie], creating the directory if needed.
  Future<void> write(String cookie) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'cookie': cookie}));
  }

  /// Forgets the persisted cookie (logout). No-op when none exists.
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
