import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:f95hub/i18n/i18n.dart';
import 'package:f95hub/widgets/about_footer.dart';

/// Captures the URL the footer's GitHub button hands to the platform.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? launched;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched = url;
    return true;
  }
}

void main() {
  testWidgets('shows the version and author and opens the repository',
      (tester) async {
    final launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = _FakeUrlLauncher());

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AboutFooter())),
    );
    await tester.pump();

    final t = AppLocale.en.buildSync();
    expect(find.text('f95hub'), findsOneWidget);
    expect(
      find.text(t.settings.about.version(version: '1.0.0+1')),
      findsOneWidget,
    );
    expect(
      find.text(t.settings.about.author(author: kAuthor)),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(t.settings.about.github));
    await tester.pump();

    expect(launcher.launched, kRepoUrl);
  });
}
