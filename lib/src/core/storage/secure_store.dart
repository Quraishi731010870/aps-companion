import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'secure_store.g.dart';

/// Every value the app keeps in secure storage. Key names live only here.
enum SecureKey {
  accessToken('afghanpay_access_token'),
  refreshToken('afghanpay_refresh_token'),
  userProfile('afghanpay_user_profile'),

  /// Vault token and masked number of the linked card. Never a full PAN.
  linkedCard('afghanpay_linked_card'),

  /// Installation id and Ed25519 seed of this device's signing key. Kept on
  /// sign-out so the backend keeps recognising the device.
  deviceKey('afghanpay_device_key', sessionScoped: false);

  const SecureKey(this.storageKey, {this.sessionScoped = true});
  final String storageKey;

  /// Removed when a session ends.
  final bool sessionScoped;
}

/// Encrypted on-device storage for tokens and the signed-in user.
///
/// - Android: AES-256-GCM data encryption, key wrapped by the hardware-backed
///   Android Keystore (RSA-OAEP). Unreadable data is erased rather than
///   crashing (`resetOnError`). App backups are disabled in the manifest so
///   ciphertext is never restored without its Keystore key.
/// - iOS: Keychain items readable only while the device is unlocked, never
///   synced to iCloud and never migrated to another device.
/// - Keychain items survive an iOS uninstall, so the first launch after an
///   install wipes anything left behind.
class SecureStore {
  SecureStore({
    FlutterSecureStorage? storage,
    Future<SharedPreferences> Function()? preferences,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: androidOptions,
             iOptions: iosOptions,
           ),
       _preferences = preferences ?? SharedPreferences.getInstance;

  static const androidOptions = AndroidOptions(
    resetOnError: true,
    migrateOnAlgorithmChange: true,
  );

  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  );

  /// Non-secret marker in SharedPreferences, which (unlike the Keychain) is
  /// removed on uninstall.
  static const installMarker = 'afghanpay_secure_store_installed';

  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _preferences;
  Future<void>? _ready;

  Future<String?> read(SecureKey key) async {
    await _ensureReady();
    return _storage.read(key: key.storageKey);
  }

  Future<void> write(SecureKey key, String value) async {
    await _ensureReady();
    await _storage.write(key: key.storageKey, value: value);
  }

  Future<void> delete(SecureKey key) async {
    await _ensureReady();
    await _storage.delete(key: key.storageKey);
  }

  /// Removes everything tied to the signed-in user; the device key stays.
  Future<void> clearSession() async {
    await _ensureReady();
    await Future.wait([
      for (final key in SecureKey.values)
        if (key.sessionScoped) _storage.delete(key: key.storageKey),
    ]);
  }

  /// Removes every value this app stores, including the device key.
  Future<void> clearAll() async {
    await _ensureReady();
    await Future.wait([
      for (final key in SecureKey.values) _storage.delete(key: key.storageKey),
    ]);
  }

  Future<void> _ensureReady() => _ready ??= _clearIfFreshInstall().catchError((
    Object error,
    StackTrace stackTrace,
  ) {
    _ready = null; // try again on the next call instead of failing forever
    Error.throwWithStackTrace(error, stackTrace);
  });

  Future<void> _clearIfFreshInstall() async {
    final preferences = await _preferences();
    if (preferences.getBool(installMarker) ?? false) return;
    await _storage.deleteAll();
    await preferences.setBool(installMarker, true);
  }
}

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => SecureStore();
