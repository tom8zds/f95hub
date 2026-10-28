import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/drift_library_store.dart';
import 'package:f95hub/adapters/library_database.dart';
import 'package:f95hub/domain/config.dart';
import 'package:f95hub/i18n/i18n.dart';
import 'package:f95hub/main.dart';
import 'package:f95hub/pages/settings_page.dart';
import 'package:f95hub/state/config.dart';
import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/library.dart';

import 'support/fake_config_store.dart';
import 'support/fake_metadata_source.dart';

/// Builds a full app scope with an in-memory database and a fake config store.
({Widget widget, ProviderContainer container, FakeConfigStore store}) _app({
  required Config config,
}) {
  final store = FakeConfigStore(toLoad: config);
  final db = LibraryDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      metadataSourceProvider.overrideWithValue(FakeMetadataSource(const [])),
      libraryStoreProvider.overrideWithValue(DriftLibraryStore(db)),
      libraryDatabaseProvider.overrideWithValue(db),
      configStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return (
    widget: UncontrolledProviderScope(container: container, child: const App()),
    container: container,
    store: store,
  );
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('generated translations compile and cover both locales', () {
    final en = AppLocale.en.buildSync();
    final zh = AppLocale.zh.buildSync();

    expect(en.nav.games, 'Games');
    expect(en.nav.library, 'Library');
    expect(en.nav.downloads, 'Downloads');
    expect(en.nav.settings, 'Settings');
    expect(zh.nav.games, '游戏');
    expect(zh.nav.library, '库');
    expect(zh.nav.downloads, '下载');
    expect(zh.nav.settings, '设置');

    expect(en.settings.title, 'Settings');
    expect(zh.settings.title, '设置');
    expect(zh.filters.category, '类别');
    expect(zh.filters.engine, '引擎');
    expect(zh.filters.status, '状态');
    expect(zh.sort.date, '日期');

    // Interpolation and pluralization stay type-safe.
    expect(en.cache.gamesCached(n: 3), '3 games cached');
    expect(zh.cache.gamesCached(n: 3), '已缓存 3 个游戏');
    expect(en.cache.reached(page: 2, total: 5), 'Reached 2 / 5 pages');
    expect(zh.cache.reached(page: 2, total: 5), '已到 2 / 5 页');
    expect(en.library.removeConfirm(title: 'X'), 'Remove "X" from your library?');
    expect(zh.library.removeConfirm(title: 'X'), '从库中移除「X」？');
  });

  testWidgets('switching the language in Settings relabels the UI live',
      (tester) async {
    final app = _app(
      config: const Config(downloadDir: r'C:\games', language: AppLanguage.en),
    );
    await tester.pumpWidget(app.widget);
    await tester.pump();

    Locale localeOf() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale!;
    expect(localeOf(), const Locale('en'));

    // English nav labels are visible in the narrow drawer.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Games'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Open Settings: English section title.
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    // Switch to Chinese through the persisted language picker.
    await tester.tap(find.byKey(const Key('language-chip-zh')));
    await tester.pumpAndSettle();

    expect(app.store.saved?.language, AppLanguage.zh);
    expect(localeOf(), const Locale('zh'));
    expect(find.text('设置'), findsWidgets);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('Theme'), findsNothing);

    // The nav labels switched too.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('游戏'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaterialApp locale follows the persisted config', (tester) async {
    final app = _app(
      config: const Config(downloadDir: r'C:\games', language: AppLanguage.zh),
    );
    await tester.pumpWidget(app.widget);
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('zh'),
    );

    await app.container.read(configProvider.notifier).save(
          const Config(downloadDir: r'C:\games', language: AppLanguage.en),
        );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
    expect(app.container.read(configProvider).config?.language, AppLanguage.en);
  });
}
