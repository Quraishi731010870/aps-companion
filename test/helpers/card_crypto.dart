import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:afghan_emi/src/features/payments/data/card_encryptor.dart';
import 'package:afghan_emi/src/features/payments/domain/card_vault.dart';
import 'package:pointycastle/export.dart';

/// One RSA key pair per test run (key generation is slow in pure Dart).
final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> testRsaKeyPair = () {
  final seed = Random.secure();
  final generator = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        FortunaRandom()..seed(
          KeyParameter(
            Uint8List.fromList(List.generate(32, (_) => seed.nextInt(256))),
          ),
        ),
      ),
    );
  return generator.generateKeyPair();
}();

String _b64(BigInt value) {
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final bytes = [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// The test public key as the backend serves it (JWK with RFC 7638 kid).
Map<String, dynamic> testJwk() {
  final key = testRsaKeyPair.publicKey;
  final n = _b64(key.modulus!);
  final e = _b64(key.exponent!);
  return {
    'kty': 'RSA',
    'n': n,
    'e': e,
    'kid': CardEncryptionKey.thumbprint(n: n, e: e),
    'alg': 'RSA-OAEP-256',
    'use': 'enc',
  };
}

CardEncryptionKey testEncryptionKey() => CardEncryptionKey.fromJwk(testJwk());

/// Decrypts [envelope] the way the backend does: RSA-OAEP-256 unwraps the
/// AES-256 key, AES-GCM (with the kid-bound AAD) opens the card JSON.
Map<String, dynamic> openTestEnvelope(CardEnvelope envelope, {String? aadKid}) {
  Uint8List bytes(String value) => base64Url.decode(base64Url.normalize(value));
  final rsa = OAEPEncoding.withSHA256(
    RSAEngine(),
  )..init(false, PrivateKeyParameter<RSAPrivateKey>(testRsaKeyPair.privateKey));
  final contentKey = rsa.process(bytes(envelope.ek));
  final gcm = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(
        KeyParameter(contentKey),
        128,
        bytes(envelope.iv),
        CardEncryptor.aad(aadKid ?? envelope.kid),
      ),
    );
  return jsonDecode(utf8.decode(gcm.process(bytes(envelope.ct))))
      as Map<String, dynamic>;
}
