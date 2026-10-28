import 'dart:io';

/// Opens [url] in the system's default browser.
///
/// Deliberately dependency-free: the project has no `url_launcher` plugin, and
/// a desktop build would need extra native registration for it. The widget
/// layer injects a fake in tests instead of calling this.
Future<void> openExternalUrl(String url) async {
  if (Platform.isWindows) {
    // `start` hands the URL to the shell's default handler; the empty argument
    // is the window title `start` otherwise mistakes the URL for.
    await Process.run('cmd', ['/c', 'start', '', url]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [url]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [url]);
  } else {
    throw UnsupportedError('openExternalUrl is unsupported on this platform');
  }
}
