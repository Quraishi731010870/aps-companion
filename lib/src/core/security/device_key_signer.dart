import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/secure_store.dart';
import 'request_signature.dart';
import 'request_signer.dart';

part 'device_key_signer.g.dart';

/// Signs requests with an Ed25519 key created once per installation.
///
/// The 32-byte seed lives only in [SecureStore] (Android Keystore-wrapped
/// AES-GCM; iOS Keychain, this device only). Neither the Secure Enclave nor
/// most Android Keystores support Ed25519, so the key is generated in
/// software rather than inside the secure hardware.
///
/// The key survives sign-out so the device stays recognised; a reinstall wipes
/// it and the next login binds a new device.
class DeviceKeySigner implements RequestSigner {
  DeviceKeySigner(
    this._store, {
    DateTime Function()? clock,
    this._nonce,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final SecureStore _store;
  final DateTime Function() _clock;
  final Random _random;
  final String Function()? _nonce;
  final _algorithm = Ed25519();
  Future<_DeviceKey>? _key;

  @override
  Future<DeviceBinding> binding() async {
    final key = await _loadKey();
    return DeviceBinding(
      installationId: key.installationId,
      platform: _platform,
      publicKey: key.publicKey,
    );
  }

  @override
  Future<Map<String, String>> sign({
    required String method,
    required Uri uri,
    required List<int> body,
  }) async {
    final key = await _loadKey();
    final timestamp = _clock().millisecondsSinceEpoch.toString();
    final nonce = _nonce?.call() ?? base64UrlNoPad(_bytes(16));
    final message = RequestSignature.canonical(
      method: method,
      path: RequestSignature.pathOf(uri),
      timestamp: timestamp,
      nonce: nonce,
      body: body,
    );
    final signature = await _algorithm.sign(
      utf8.encode(message),
      keyPair: key.keyPair,
    );
    return {
      RequestSignature.timestampHeader: timestamp,
      RequestSignature.nonceHeader: nonce,
      RequestSignature.signatureHeader: base64UrlNoPad(signature.bytes),
    };
  }

  Future<_DeviceKey> _loadKey() => _key ??= _readOrCreate().catchError((
    Object error,
    StackTrace stackTrace,
  ) {
    _key = null; // try again on the next request instead of failing forever
    Error.throwWithStackTrace(error, stackTrace);
  });

  Future<_DeviceKey> _readOrCreate() async {
    final stored = _StoredKey.parse(await _store.read(SecureKey.deviceKey));
    final value =
        stored ??
        _StoredKey(
          installationId: base64UrlNoPad(_bytes(16)),
          seed: _bytes(32),
        );
    if (stored == null) {
      await _store.write(SecureKey.deviceKey, jsonEncode(value.toJson()));
    }
    final keyPair = await _algorithm.newKeyPairFromSeed(value.seed);
    final publicKey = await keyPair.extractPublicKey();
    return _DeviceKey(
      installationId: value.installationId,
      keyPair: keyPair,
      publicKey: base64UrlNoPad(publicKey.bytes),
    );
  }

  List<int> _bytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  static String get _platform {
    if (kIsWeb) return 'WEB';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      // Desktop builds are development-only and have no own platform value.
      _ => 'WEB',
    };
  }
}

class _DeviceKey {
  const _DeviceKey({
    required this.installationId,
    required this.keyPair,
    required this.publicKey,
  });
  final String installationId;
  final SimpleKeyPair keyPair;
  final String publicKey;
}

/// The persisted form: installation id and the 32-byte Ed25519 seed.
class _StoredKey {
  const _StoredKey({required this.installationId, required this.seed});
  final String installationId;
  final List<int> seed;

  Map<String, String> toJson() => {
    'installationId': installationId,
    'seed': base64UrlNoPad(seed),
  };

  /// Null when missing or unreadable, so a fresh key is created.
  static _StoredKey? parse(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json case {
        'installationId': final String id,
        'seed': final String seed,
      }) {
        final bytes = base64Url.decode(base64Url.normalize(seed));
        if (bytes.length == 32 && id.length >= 16) {
          return _StoredKey(installationId: id, seed: bytes);
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
RequestSigner requestSigner(Ref ref) =>
    DeviceKeySigner(ref.watch(secureStoreProvider));
