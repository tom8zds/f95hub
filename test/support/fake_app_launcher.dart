import 'package:f95hub/adapters/app_launcher.dart';

/// In-memory [AppLauncher] for tests: records every call so tests can assert
/// that open-folder/launch routed through the seam (and never hit `Process`).
class FakeAppLauncher implements AppLauncher {
  final List<String> openedFolders = [];

  @override
  Future<void> openFolder(String path) async {
    openedFolders.add(path);
  }
}
