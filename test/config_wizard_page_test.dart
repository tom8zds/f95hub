import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/config_store.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/main.dart';
import 'package:f95hub/pages/config_wizard_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';
import 'package:f95hub/state/session.dart';

import 'support/fake_metadata_source.dart';
import 'support/fake_session_store.dart';

/// A ConfigStore fake for widget tests (no real file I/O under FakeAsync).
class _InMemoryConfigStore extends ConfigStore {
  Config? toLoad;
  Config? saved;

  @override
  Future<Config?> load() async => toLoad;

  @override
  Future<void> save(Config config) async {
    saved = config;
  }
}

Future<void> _golden(WidgetTester tester, Widget widget, String name) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: widget)),
    ),
  );
  await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  testWidgets('DownloadDirSection golden', (tester) async {
    await _golden(
      tester,
      DownloadDirSection(value: null, onBrowse: () {}),
      'config_download_dir_section',
    );
  });

  testWidgets('LoginSection golden', (tester) async {
    await _golden(
      tester,
      LoginSection(cookie: '', onCookieChanged: (_) {}),
      'config_login_section',
    );
  });

  testWidgets('LoginSection offers only a cookie input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginSection(cookie: '', onCookieChanged: (_) {}),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Session cookie'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('ConfigWizardPage golden', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ConfigWizardPage())),
    );
    await expectLater(
      find.byType(ConfigWizardPage),
      matchesGoldenFile('goldens/config_wizard_page.png'),
    );
  });

  testWidgets('finish writes config, sets secret and session in memory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = _InMemoryConfigStore();
    final sessionStore = FakeSessionStore();
    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        sessionStoreProvider.overrideWithValue(sessionStore),
        metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
        directoryPickerProvider.overrideWith((ref) => () async => r'C:\games'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConfigWizardPage()),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pump();
    await tester.pump();

    // The cookie is the wizard's only text field.
    await tester.enterText(find.byType(TextFormField).at(0), 'xf_user=abc');

    await tester.tap(find.text('Finish'));
    await tester.pump();
    await tester.pump();

    expect(store.saved, isNotNull);
    expect(store.saved!.downloadDir, r'C:\games');
    expect(container.read(sessionProvider), 'xf_user=abc');
    // The session cookie is persisted outside the config file.
    expect(sessionStore.cookie, 'xf_user=abc');

    // The persisted config never carries the secret or the cookie.
    final json = store.saved!.toJson();
    expect(json.keys, isNot(contains('secret')));
    expect(json.values.join(), isNot(contains('mysecret')));
    expect(json.values.join(), isNot(contains('xf_user')));
  });

  testWidgets('config-load failure shows a clear error with Retry', (
    tester,
  ) async {
    final store = _InMemoryConfigStore();
    var failNextLoad = true;

    final container = ProviderContainer(
      overrides: [
        configStoreProvider.overrideWithValue(
          _ThrowingConfigStore(() {
            if (failNextLoad) {
              failNextLoad = false;
              throw Exception('disk error');
            }
            return store.load();
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pump();

    expect(find.text('Failed to load configuration'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Retry succeeds (no config yet → wizard shows).
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ConfigWizardPage), findsOneWidget);
  });
}

/// A store that delegates `load()` to [loader], letting a test inject a failure.
class _ThrowingConfigStore extends ConfigStore {
  _ThrowingConfigStore(this.loader);

  final Future<Config?> Function() loader;

  @override
  Future<Config?> load() => loader();

  @override
  Future<void> save(Config config) async {}
}
