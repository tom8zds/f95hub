import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Shared setup for every test file in `test/`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tests have no network access; resolve Google Fonts to its bundled/asset
  // fallback so theme construction never waits on a download.
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
