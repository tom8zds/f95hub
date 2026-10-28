import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Port-like seam for OS-level "open" actions (open a folder in the file
/// manager).
///
/// Kept deliberately tiny so the app can open folders without the UI talking
/// to `Process` directly. Tests inject a fake that records the calls; the real
/// implementation lives in [ProcessAppLauncher].
abstract class AppLauncher {
  /// Opens [path] (a directory) in the OS file manager.
  Future<void> openFolder(String path);
}

/// [AppLauncher] backed by the platform process launcher.
///
/// Windows: `explorer.exe` for folders. Linux: `xdg-open`.
class ProcessAppLauncher implements AppLauncher {
  const ProcessAppLauncher();

  @override
  Future<void> openFolder(String path) async {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [path]);
    } else {
      throw UnsupportedError('openFolder is unsupported on this platform');
    }
  }
}

/// A started game process: [exitCode] completes when the game quits.
///
/// Abstracted so playtime tracking never depends on `dart:io`'s concrete
/// [Process] in tests (a fake runner completes the future deterministically).
class RunningProcess {
  const RunningProcess(this.exitCode);

  final Future<int> exitCode;
}

/// Port: starts a local game executable and exposes its exit code.
///
/// The launch entry is an absolute `.exe`/`.bat` path; batch files are started
/// through `cmd /c` (with the working directory set to the game folder) so the
/// process we wait on is the actual game, not a detached shell.
abstract class ProcessRunner {
  Future<RunningProcess> start(String executablePath);
}

/// [ProcessRunner] backed by `dart:io` [Process].
class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<RunningProcess> start(String executablePath) async {
    final workingDirectory = p.dirname(executablePath);
    final lower = executablePath.toLowerCase();
    final isBatch = lower.endsWith('.bat') || lower.endsWith('.cmd');

    final Process process;
    if (isBatch && Platform.isWindows) {
      process = await Process.start(
        'cmd',
        ['/c', executablePath],
        workingDirectory: workingDirectory,
      );
    } else {
      process = await Process.start(
        executablePath,
        const [],
        workingDirectory: workingDirectory,
        runInShell: isBatch,
      );
    }
    // A game that chats on stdout would otherwise block once the OS pipe
    // buffer fills; drain both streams for the process's whole lifetime.
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    return RunningProcess(process.exitCode);
  }
}
