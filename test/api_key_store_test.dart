import 'package:claudy/core/config/api_key_store.dart';
import 'package:claudy/core/http/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(Map<String, String> initialValues) {
    FlutterSecureStorage.setMockInitialValues(initialValues);
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(Dio()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('read returns empty when nothing stored and no build-time key', () async {
    final store = containerWith({}).read(apiKeyStoreProvider);
    expect(await store.read(), isEmpty);
    expect(await store.hasUserKey(), isFalse);
  });

  test('save persists and read returns the user key', () async {
    final container = containerWith({});
    final store = container.read(apiKeyStoreProvider);

    await store.save('  abc123  ');
    expect(await store.read(), 'abc123');
    expect(await store.hasUserKey(), isTrue);
  });

  test('clear removes the user key', () async {
    final container = containerWith({'security.openweathermap.api_key': 'secret'});
    final store = container.read(apiKeyStoreProvider);

    expect(await store.hasUserKey(), isTrue);
    await store.clear();
    expect(await store.hasUserKey(), isFalse);
    expect(await store.read(), isEmpty);
  });

  test('provider exposes the stored key reactively', () async {
    final container = containerWith({'security.openweathermap.api_key': 'k1'});
    expect(await container.read(openWeatherApiKeyProvider.future), 'k1');
  });
}
