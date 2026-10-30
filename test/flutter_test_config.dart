import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shared setup for every test file in `test/`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tests have no network access; resolve Google Fonts to its bundled/asset
  // fallback so theme construction never waits on a download.
  GoogleFonts.config.allowRuntimeFetching = false;
  // The settings footer reads the build's version; pin it so goldens and text
  // assertions do not depend on the host executable.
  PackageInfo.setMockInitialValues(
    appName: 'f95hub',
    packageName: 'f95hub',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  await testMain();
}
