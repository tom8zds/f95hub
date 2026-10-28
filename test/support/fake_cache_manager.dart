import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// An offline [BaseCacheManager] for widget tests.
///
/// Records every requested key. URLs present in [files] are served from temp
/// files (so widgets can read real bytes back); everything else fails with
/// [error], which drives `CachedNetworkImage` to its error widget. No network
/// access happens, so tests stay deterministic. The temp files are small and
/// land in the OS temp dir; nothing cleans them up.
class FakeCacheManager extends BaseCacheManager {
  FakeCacheManager({
    this.error = const SocketExceptionStub(),
    Map<String, List<int>>? files,
  }) : files = files ?? const {};

  final Object error;

  /// Bytes served by URL (empty → every request fails).
  final Map<String, List<int>> files;

  /// Cache keys/urls requested, in order.
  final List<String> requests = [];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    requests.add(key ?? url);
    final bytes = files[key ?? url] ?? files[url];
    if (bytes == null) {
      throw error;
    }
    yield _fileInfoFor(url, bytes);
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    final info = await getFileStream(url, key: key, headers: headers).first;
    return (info as FileInfo).file;
  }

  FileInfo _fileInfoFor(String url, List<int> bytes) {
    final path =
        '${io.Directory.systemTemp.path}/f95hub-fake-'
        '${DateTime.now().microsecondsSinceEpoch}-${requests.length}.img';
    io.File(path).writeAsBytesSync(bytes, flush: true);
    return FileInfo(
      LocalFileSystem().file(path),
      FileSource.Cache,
      DateTime.now(),
      url,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stand-in for a network failure that does not need `dart:io`.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();

  @override
  String toString() => 'offline (test)';
}
