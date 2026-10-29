import 'dart:convert';

import 'package:afghan_emi/src/core/security/device_key_signer.dart';
import 'package:afghan_emi/src/core/security/request_signature.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(mockSecureStorage);

  test('creates one key per installation and keeps it', () async {
    final store = SecureStore();
    final first = await DeviceKeySigner(store).binding();
    final again = await DeviceKeySigner(store).binding();

    expect(first.publicKey, hasLength(43));
    expect(first.installationId.length, greaterThanOrEqualTo(16));
    expect(again.toJson(), first.toJson());
    expect(await store.read(SecureKey.deviceKey), isNotNull);
  });

  test('the key survives sign-out but not a full wipe', () async {
    final store = SecureStore();
    final before = await DeviceKeySigner(store).binding();

    await store.clearSession();
    expect(
      (await DeviceKeySigner(store).binding()).publicKey,
      before.publicKey,
    );

    await store.clearAll();
    expect(
      (await DeviceKeySigner(store).binding()).publicKey,
      isNot(before.publicKey),
    );
  });

  test('an unreadable stored key is replaced with a new one', () async {
    mockSecureStorage(values: {SecureKey.deviceKey: 'not json'});
    final store = SecureStore();

    final binding = await DeviceKeySigner(store).binding();

    expect(binding.publicKey, hasLength(43));
    expect(jsonDecode((await store.read(SecureKey.deviceKey))!), isA<Map>());
  });

  test(
    'signatures verify with the bound public key and use fresh nonces',
    () async {
      final signer = DeviceKeySigner(SecureStore());
      final uri = Uri.parse('http://api.test/api/v1/cards?x=1');
      final body = utf8.encode('{"a":1}');

      final first = await signer.sign(method: 'POST', uri: uri, body: body);
      final second = await signer.sign(method: 'POST', uri: uri, body: body);
      expect(
        first[RequestSignature.nonceHeader],
        isNot(second[RequestSignature.nonceHeader]),
      );

      final message = RequestSignature.canonical(
        method: 'POST',
        path: '/api/v1/cards?x=1',
        timestamp: first[RequestSignature.timestampHeader]!,
        nonce: first[RequestSignature.nonceHeader]!,
        body: body,
      );
      final publicKey = SimplePublicKey(
        base64Url.decode(
          base64Url.normalize((await signer.binding()).publicKey),
        ),
        type: KeyPairType.ed25519,
      );
      Future<bool> verifies(List<int> signed) => Ed25519().verify(
        signed,
        signature: Signature(
          base64Url.decode(
            base64Url.normalize(first[RequestSignature.signatureHeader]!),
          ),
          publicKey: publicKey,
        ),
      );
      expect(await verifies(utf8.encode(message)), isTrue);
      expect(await verifies(utf8.encode('$message-tampered')), isFalse);
    },
  );
}
