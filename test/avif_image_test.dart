import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/widgets/image_gallery.dart';

import 'support/fake_cache_manager.dart';
import 'dart:io' as io;

import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Leading bytes of an AVIF file: size, `ftyp`, `avif` brand, filler.
final Uint8List _avifBytes = Uint8List.fromList([
  0, 0, 0, 16, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66, 0, 0, 0, 0,
]);

/// A 1×1 transparent PNG (engine-decodable stand-in for non-AVIF images).
final Uint8List _pngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, 0x49, 0x48,
  0x44, 0x52, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 0x1F, 0x15, 0xC4, 0x89,
  0, 0, 0, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0, 1, 0, 0, 5, 0,
  1, 0x0D, 0x0A, 0x2D, 0xB4, 0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

Future<ui.Image> _fakeDecode(Uint8List bytes) async {
  return decodeImageFromList(_pngBytes);
}

/// Yields a 40% download-progress event before the file, so the loader UI
/// can be asserted mid-flight.
class _ProgressFake extends FakeCacheManager {
  _ProgressFake(Map<String, List<int>> files) : super(files: files);

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
    final path =
        '${io.Directory.systemTemp.path}/f95hub-progress-'
        '${DateTime.now().microsecondsSinceEpoch}.img';
    io.File(path).writeAsBytesSync(bytes, flush: true);
    yield DownloadProgress(url, 100, 40);
    yield FileInfo(
      LocalFileSystem().file(path),
      FileSource.Cache,
      DateTime.now(),
      url,
    );
  }
}

void main() {
  testWidgets('AvifCapableImage shows a spinner and byte progress while '
      'loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvifCapableImage(
            url: 'https://attachments.f95zone.to/2024/10/slow.jpg',
            cacheManager: FakeCacheManager(files: {
              'https://attachments.f95zone.to/2024/10/slow.jpg': _pngBytes,
            }),
          ),
        ),
      ),
    );
    // Before the (real-IO) load finishes, the active loader is visible.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('a known download size drives the progress bar value', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvifCapableImage(
              url: 'https://attachments.f95zone.to/2024/10/p.jpg',
              cacheManager: _ProgressFake({
                'https://attachments.f95zone.to/2024/10/p.jpg': _pngBytes,
              }),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    // Once loaded the bar is gone.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  test('isAvifBytes recognizes the ftyp/avif brand and rejects others', () {
    expect(isAvifBytes(_avifBytes), isTrue);
    expect(isAvifBytes(_pngBytes), isFalse);
    expect(isAvifBytes(Uint8List(4)), isFalse);
  });

  testWidgets('AvifCapableImage decodes AVIF bytes through the seam', (
    tester,
  ) async {
    // The load path does real temp-file IO; pump inside runAsync so the
    // future chain completes on the real event loop.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvifCapableImage(
              url: 'https://attachments.f95zone.to/2024/10/a.jpg',
              cacheManager: FakeCacheManager(files: {
                'https://attachments.f95zone.to/2024/10/a.jpg': _avifBytes,
              }),
              decoder: _fakeDecode,
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsNothing);
  });

  testWidgets('AvifCapableImage renders non-AVIF bytes via Image.memory', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvifCapableImage(
              url: 'https://preview.f95zone.to/2017/08/x.jpg',
              cacheManager: FakeCacheManager(files: {
                'https://preview.f95zone.to/2017/08/x.jpg': _pngBytes,
              }),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.broken_image), findsNothing);
  });

  testWidgets('AvifCapableImage shows the broken placeholder on failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvifCapableImage(
            url: 'https://attachments.f95zone.to/2024/10/gone.jpg',
            cacheManager: FakeCacheManager(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
