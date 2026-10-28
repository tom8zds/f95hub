import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/config_store.dart';
import 'package:f95hub/domain/config.dart';

void main() {
  late Directory dir;
  late ConfigStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('f95hub_config_test');
    store = ConfigStore(dirProvider: () async => dir);
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('load returns null when no config file exists (first launch)', () async {
    expect(await store.load(), isNull);
  });

  test('save/load round-trips every non-secret field', () async {
    const config = Config(
      downloadDir: r'C:\games',
      storageDir: r'D:\library',
      theme: ThemePreset.green,
      themeMode: AppThemeMode.dark,
      requestIntervalMs: 3500,
    );
    await store.save(config);

    final loaded = await store.load();
    expect(loaded, config);
    expect(loaded, isNotNull);
    expect(loaded?.storageDir, r'D:\library');
    expect(loaded?.theme, ThemePreset.green);
    expect(loaded?.themeMode, AppThemeMode.dark);
    expect(loaded?.requestIntervalMs, 3500);
  });

  test('theme round-trips for every preset', () async {
    for (final preset in ThemePreset.values) {
      await store.save(Config(downloadDir: '/x', theme: preset));
      expect((await store.load())?.theme, preset);
    }
  });

  test('themeMode round-trips for every mode', () async {
    for (final mode in AppThemeMode.values) {
      await store.save(Config(downloadDir: '/x', themeMode: mode));
      expect((await store.load())?.themeMode, mode);
    }
  });

  test('writes only non-secret fields to disk', () async {
    await store.save(
      const Config(
        downloadDir: r'C:\games',
        storageDir: r'D:\library',
        theme: ThemePreset.red,
      ),
    );

    final raw = await File(
      '${dir.path}/${ConfigStore.fileName}',
    ).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    expect(json.keys.toSet(), {
      'downloadDir',
      'storageDir',
      'theme',
      'themeMode',
      'language',
      'requestIntervalMs',
    });
    // No secret/cookie/session keys may ever reach the file.
    expect(json.keys, isNot(contains(anyOf('secret', 'rpcSecret', 'cookie'))));
  });

  test('fromJson falls back to null storageDir for legacy config files', () {
    // A pre-ticket-15 config.json has no `storageDir` key; it must load
    // gracefully with storageDir == null rather than throwing.
    final config = Config.fromJson(const {'downloadDir': '/x'});
    expect(config.storageDir, isNull);
  });

  test('fromJson falls back to the default theme for legacy config files', () {
    // A pre-ticket-23 config.json has no `theme` key; it must load gracefully
    // with the default (material) theme rather than throwing.
    final config = Config.fromJson(const {'downloadDir': '/x'});
    expect(config.theme, ThemePreset.material);
  });

  test('language defaults to system, round-trips, and falls back for legacy',
      () async {
    expect(const Config().language, AppLanguage.system);
    expect(AppLanguage.fromName('nonsense'), AppLanguage.system);
    expect(Config.fromJson(const {'downloadDir': '/x'}).language,
        AppLanguage.system);

    await store.save(const Config(downloadDir: '/x', language: AppLanguage.zh));
    final loaded = await store.load();
    expect(loaded?.language, AppLanguage.zh);

    final changed = const Config().copyWith(language: AppLanguage.en);
    expect(Config.fromJson(changed.toJson()).language, AppLanguage.en);
  });

  test('fromJson falls back to the system theme mode for legacy files', () {
    // A pre-ticket-39 config.json has no `themeMode` key.
    final config = Config.fromJson(const {'downloadDir': '/x'});
    expect(config.themeMode, AppThemeMode.system);
    expect(AppThemeMode.fromName('nonsense'), AppThemeMode.system);
  });

  test('fromJson falls back to the default interval for legacy config files',
      () {
    // A pre-ticket-34 config.json has no `requestIntervalMs` key.
    final config = Config.fromJson(const {'downloadDir': '/x'});
    expect(config.requestIntervalMs, Config.defaultRequestIntervalMs);
    expect(Config.defaultRequestIntervalMs, 2000);
  });

  test('requestIntervalMs defaults to 2 s and round-trips through copyWith',
      () {
    expect(const Config().requestIntervalMs, 2000);
    final changed = const Config().copyWith(requestIntervalMs: 750);
    expect(changed.requestIntervalMs, 750);
    expect(
      Config.fromJson(changed.toJson()).requestIntervalMs,
      750,
    );
  });

  test('fromJson falls back to defaults for missing keys', () {
    final config = Config.fromJson(const {'downloadDir': '/x'});
    expect(config.downloadDir, '/x');
  });

  test('Config json round-trips the download directory', () {
    final config = Config.fromJson(Config(downloadDir: '/y').toJson());
    expect(config.downloadDir, '/y');
  });
}
