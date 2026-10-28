import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/state/game_list.dart';
import 'package:f95hub/state/session.dart';

import 'support/fake_metadata_source.dart';
import 'support/fake_session_store.dart';

void main() {
  late FakeSessionStore store;

  setUp(() {
    store = FakeSessionStore();
  });

  ProviderContainer containerFor(FakeMetadataSource source) {
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        metadataSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('login stores the session cookie in sessionProvider', () async {
    final source = FakeMetadataSource(const []);
    final container = containerFor(source);

    await container.read(sessionProvider.notifier).restored;
    expect(container.read(sessionProvider), isNull);

    final cookie =
        await container.read(sessionProvider.notifier).login('xf_user=abc');

    expect(cookie, 'xf_user=abc');
    expect(container.read(sessionProvider), 'xf_user=abc');
    expect(source.loginCookies, ['xf_user=abc']);
  });

  test('login persists the cookie for the next launch', () async {
    final container = containerFor(FakeMetadataSource(const []));

    await container.read(sessionProvider.notifier).login('xf_user=abc');

    expect(store.cookie, 'xf_user=abc');
  });

  test('a fresh container restores the persisted cookie into the source',
      () async {
    // First launch: log in.
    final firstSource = FakeMetadataSource(const []);
    final first = containerFor(firstSource);
    await first.read(sessionProvider.notifier).login('xf_user=abc');
    first.dispose();

    // Restart: a brand-new container with the same persisted store.
    final secondSource = FakeMetadataSource(const []);
    final second = containerFor(secondSource);

    await second.read(sessionProvider.notifier).restored;

    expect(second.read(sessionProvider), 'xf_user=abc');
    expect(secondSource.loginCookies, ['xf_user=abc']);
  });

  test('restore stays logged out when nothing is persisted', () async {
    final source = FakeMetadataSource(const []);
    final container = containerFor(source);

    await container.read(sessionProvider.notifier).restored;

    expect(container.read(sessionProvider), isNull);
    expect(source.loginCookies, isEmpty);
  });

  test('re-applies the cookie when the metadata source is re-created',
      () async {
    final sources = <FakeMetadataSource>[];
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        metadataSourceProvider.overrideWith((ref) {
          final source = FakeMetadataSource(const []);
          sources.add(source);
          return source;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).login('xf_user=abc');
    expect(sources, hasLength(1));

    // Simulates a config change (request interval) rebuilding the source.
    container.invalidate(metadataSourceProvider);
    container.read(metadataSourceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(sources, hasLength(2));
    expect(sources.last.loginCookies, ['xf_user=abc']);
    expect(container.read(sessionProvider), 'xf_user=abc');
  });

  test('logout clears the session in memory and on disk', () async {
    final container = containerFor(FakeMetadataSource(const []));

    await container.read(sessionProvider.notifier).login('xf_user=abc');
    expect(container.read(sessionProvider), 'xf_user=abc');

    await container.read(sessionProvider.notifier).logout();

    expect(container.read(sessionProvider), isNull);
    expect(store.cookie, isNull);
    expect(store.clearCalls, 1);
  });

  test('a startup cookie is not lost when the source is replaced', () async {
    store.cookie = 'xf_user=persisted';
    final sources = <FakeMetadataSource>[];
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        metadataSourceProvider.overrideWith((ref) {
          final source = FakeMetadataSource(const []);
          sources.add(source);
          return source;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).restored;
    expect(container.read(sessionProvider), 'xf_user=persisted');

    container.invalidate(metadataSourceProvider);
    container.read(metadataSourceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(sources.last.loginCookies, ['xf_user=persisted']);
  });
}
