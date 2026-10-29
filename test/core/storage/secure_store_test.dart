import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

void main() {
  const raw = FlutterSecureStorage();

  test('writes, reads and deletes by key', () async {
    mockSecureStorage();
    final store = SecureStore();

    await store.write(SecureKey.accessToken, 'token');
    expect(await store.read(SecureKey.accessToken), 'token');

    await store.delete(SecureKey.accessToken);
    expect(await store.read(SecureKey.accessToken), isNull);
  });

  test('clearAll removes every app value', () async {
    mockSecureStorage(
      values: {
        SecureKey.accessToken: 'a',
        SecureKey.refreshToken: 'r',
        SecureKey.userProfile: '{}',
      },
    );
    final store = SecureStore();

    await store.clearAll();

    for (final key in SecureKey.values) {
      expect(await store.read(key), isNull, reason: key.name);
    }
  });

  test('clearSession keeps the device key', () async {
    mockSecureStorage(
      values: {
        SecureKey.accessToken: 'a',
        SecureKey.userProfile: '{}',
        SecureKey.linkedCard: '{}',
        SecureKey.deviceKey: 'device',
      },
    );
    final store = SecureStore();

    await store.clearSession();

    for (final key in SecureKey.values) {
      expect(
        await store.read(key),
        key.sessionScoped ? isNull : isNotNull,
        reason: key.name,
      );
    }
  });

  test(
    'a fresh install wipes Keychain values left by a previous install',
    () async {
      mockSecureStorage(
        values: {SecureKey.accessToken: 'stale-token'},
        freshInstall: true,
      );

      final value = await SecureStore().read(SecureKey.accessToken);

      expect(value, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(SecureStore.installMarker), isTrue);
    },
  );

  test('later launches keep stored values', () async {
    mockSecureStorage(values: {SecureKey.accessToken: 'live-token'});

    expect(await SecureStore().read(SecureKey.accessToken), 'live-token');
  });

  test('the fresh-install wipe runs once per store', () async {
    mockSecureStorage(freshInstall: true);
    final store = SecureStore();
    await store.read(SecureKey.accessToken);

    await store.write(SecureKey.accessToken, 'new');
    // A second wipe would erase the value just written.
    expect(await store.read(SecureKey.accessToken), 'new');
    expect(await raw.read(key: SecureKey.accessToken.storageKey), 'new');
  });

  test('key names are unique and app-prefixed', () {
    final names = {for (final key in SecureKey.values) key.storageKey};
    expect(names, hasLength(SecureKey.values.length));
    expect(names.every((name) => name.startsWith('afghanpay_')), isTrue);
  });

  group('platform protection', () {
    test('iOS: only while unlocked, this device only, no iCloud sync', () {
      final options = SecureStore.iosOptions.toMap();
      expect(
        options['accessibility'],
        KeychainAccessibility.unlocked_this_device.name,
      );
      expect(options['synchronizable'], 'false');
    });

    test('Android: Keystore-wrapped AES-GCM, erase on unreadable data', () {
      final options = SecureStore.androidOptions.toMap();
      expect(options['resetOnError'], 'true');
      expect(options['storageCipherAlgorithm'], 'AES_GCM_NoPadding');
      expect(
        options['keyCipherAlgorithm'],
        'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
      );
    });
  });
}
