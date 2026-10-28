import 'dart:async';

import 'package:f95hub/adapters/app_launcher.dart';

/// In-memory [ProcessRunner] for tests: records launches and lets the test
/// decide when the "game process" exits by completing [exitCode].
class FakeProcessRunner implements ProcessRunner {
  final List<String> started = [];
  final List<Completer<int>> _exits = [];

  @override
  Future<RunningProcess> start(String executablePath) async {
    started.add(executablePath);
    final exit = Completer<int>();
    _exits.add(exit);
    return RunningProcess(exit.future);
  }

  /// Completes the most recently started process with [code].
  void complete([int code = 0]) {
    _exits.last.complete(code);
  }
}
