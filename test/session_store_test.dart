import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/adapters/session_store.dart';

void main() {
  late Directory dir;
  late SessionStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('f95hub_session_');
    store = SessionStore(dirProvider: () async => dir);
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('read returns null when no session file exists', () async {
    expect(await store.read(), isNull);
  });

  test('write/read round-trips the cookie through session.json', () async {
    const cookie = 'xf_user=abc; cf_clearance=xyz';

    await store.write(cookie);

    expect(File('${dir.path}/session.json').existsSync(), isTrue);
    expect(await store.read(), cookie);

    final decoded = jsonDecode(
      await File('${dir.path}/session.json').readAsString(),
    );
    expect(decoded, {'cookie': cookie});
  });

  test('write overwrites a previous cookie', () async {
    await store.write('xf_user=old');
    await store.write('xf_user=new');

    expect(await store.read(), 'xf_user=new');
  });

  test('clear removes the persisted cookie and is idempotent', () async {
    await store.write('xf_user=abc');

    await store.clear();
    expect(await store.read(), isNull);
    expect(File('${dir.path}/session.json').existsSync(), isFalse);

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('creates the directory on write', () async {
    final nested = Directory('${dir.path}/nested')..createSync();
    final nestedStore = SessionStore(dirProvider: () async => nested);

    await nestedStore.write('xf_user=abc');

    expect(await nestedStore.read(), 'xf_user=abc');
  });
}
