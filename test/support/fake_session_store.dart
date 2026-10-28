import 'package:f95hub/adapters/session_store.dart';

/// In-memory [SessionStore] for state/widget tests (no real file I/O).
class FakeSessionStore extends SessionStore {
  FakeSessionStore({this.cookie});

  /// The persisted cookie (null = logged out).
  String? cookie;

  /// Number of times [clear] ran.
  int clearCalls = 0;

  @override
  Future<String?> read() async => cookie;

  @override
  Future<void> write(String cookie) async {
    this.cookie = cookie;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    cookie = null;
  }
}
