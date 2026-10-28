import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../domain/card_details.dart';
import '../domain/card_vault.dart';

/// The backend's RSA public key, as served by `GET /api/v1/cards/encryption-key`.
class CardEncryptionKey {
  const CardEncryptionKey({
    required this.kid,
    required this.n,
    required this.e,
  });

  /// Parses the JWK and checks that its `kid` really is its own thumbprint.
  factory CardEncryptionKey.fromJwk(Map<String, dynamic> jwk) {
    final (kty, n, e, kid) = (jwk['kty'], jwk['n'], jwk['e'], jwk['kid']);
    if (kty != 'RSA' || n is! String || e is! String || kid is! String) {
      throw const FormatException('Card encryption key is malformed.');
    }
    if (thumbprint(n: n, e: e) != kid) {
      throw const FormatException('Card encryption key id does not match.');
    }
    return CardEncryptionKey(kid: kid, n: n, e: e);
  }

  /// RFC 7638 thumbprint; identical to the backend's `jwkThumbprint`.
  static String thumbprint({required String n, required String e}) {
    final canonical = utf8.encode('{"e":"$e","kty":"RSA","n":"$n"}');
    return _b64(SHA256Digest().process(Uint8List.fromList(canonical)));
  }

  final String kid;
  final String n;
  final String e;

  RSAPublicKey get _rsa => RSAPublicKey(_bigInt(n), _bigInt(e));
}

/// Produces [CardEnvelope]s: AES-256-GCM over the card JSON with a fresh key
/// and nonce per call, the key wrapped with RSA-OAEP (SHA-256). Mirrors
/// `backend/src/cards/card-envelope.ts`.
class CardEncryptor {
  CardEncryptor({Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _clock = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _clock;

  CardEnvelope seal(CardDetails card, CardEncryptionKey key) {
    final contentKey = _bytes(32);
    final iv = _bytes(12);
    final plaintext = utf8.encode(jsonEncode(card.toPayload(_clock())));
    try {
      final gcm = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(KeyParameter(contentKey), 128, iv, aad(key.kid)),
        );
      final sealed = gcm.process(Uint8List.fromList(plaintext));
      final rsa = OAEPEncoding.withSHA256(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(key._rsa));
      return CardEnvelope(
        kid: key.kid,
        ek: _b64(rsa.process(contentKey)),
        iv: _b64(iv),
        ct: _b64(sealed),
      );
    } finally {
      // Best effort: Dart strings cannot be wiped, but byte buffers can.
      contentKey.fillRange(0, contentKey.length, 0);
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  /// Binds ciphertext to its purpose and key; must match `envelopeAad`.
  static Uint8List aad(String kid) =>
      Uint8List.fromList(utf8.encode('afghanpay-card-v1|$kid'));

  Uint8List _bytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

BigInt _bigInt(String base64url) {
  final bytes = base64Url.decode(base64Url.normalize(base64url));
  return bytes.fold(
    BigInt.zero,
    (value, byte) => (value << 8) | BigInt.from(byte),
  );
}
