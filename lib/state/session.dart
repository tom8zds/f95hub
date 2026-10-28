import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/session_store.dart';
import '../domain/ports.dart';
import 'game_list.dart';
import 'image_cache.dart';

/// The [SessionStore] used by the app (file-backed in the support directory).
/// Tests override this with an in-memory store or a temp-directory one.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(),
);

/// The in-memory f95zone session cookie (e.g. `xf_user=...; cf_clearance=...`).
///
/// Restored from `session.json` on startup and persisted on login; `null`
/// means "not logged in".
final sessionProvider =
    NotifierProvider<SessionController, String?>(SessionController.new);

/// Performs login via the metadata source and stores the session cookie in
/// [sessionProvider], persisting it so the next launch stays logged in.
class SessionController extends Notifier<String?> {
  Future<void>? _restoring;

  @override
  String? build() {
    // Restore asynchronously: `build` must stay synchronous, and the app must
    // keep rendering while the file is read.
    _restoring = _restore();
    // The source is re-created when the request interval changes; re-apply the
    // cookie so a config edit does not silently log the app out.
    ref.listen<MetadataSource>(metadataSourceProvider, (previous, next) {
      final cookie = state;
      if (cookie != null && cookie.isNotEmpty) {
        unawaited(next.login(LoginCredentials(cookie: cookie)));
      }
    });
    return null;
  }

  /// Completes once the persisted session has been restored (startup/tests).
  Future<void> get restored => _restoring ?? Future<void>.value();

  Future<void> _restore() async {
    final String? cookie;
    try {
      cookie = await ref.read(sessionStoreProvider).read();
    } catch (_) {
      // No usable storage (e.g. unsupported platform): stay logged out.
      return;
    }
    if (cookie == null || cookie.isEmpty) {
      return;
    }
    try {
      final source = ref.read(metadataSourceProvider);
      final session = await source.login(LoginCredentials(cookie: cookie));
      if (ref.mounted) {
        _setSession(session);
      }
    } catch (_) {
      // The persisted cookie could not be applied; leave the user logged out.
    }
  }

  /// Logs in with a pasted session [cookie], stores it in memory and on disk.
  Future<String> login(String cookie) async {
    final source = ref.read(metadataSourceProvider);
    final session = await source.login(LoginCredentials(cookie: cookie));
    _setSession(session);
    // Best effort: a failed write must not break the session that works for
    // this run.
    try {
      await ref.read(sessionStoreProvider).write(session);
    } catch (_) {}
    return session;
  }

  /// Sets the session state and mirrors it into the image cache, so cover
  /// and screenshot downloads send the current credentials on the next
  /// request.
  void _setSession(String? value) {
    state = value;
    imageCacheCookie = value;
  }

  /// Clears the session (logs out) in memory and on disk.
  Future<void> logout() async {
    _setSession(null);
    try {
      await ref.read(sessionStoreProvider).clear();
    } catch (_) {}
  }
}
