import 'dart:convert';

import 'package:afghan_emi/src/features/payments/data/card_encryptor.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/card_crypto.dart';

void main() {
  const card = CardDetails(
    pan: '6037991234561234',
    expiryMonth: 12,
    expiryYear: 2029,
    holderName: 'Demo Customer',
  );
  final sentAt = DateTime.utc(2026, 10, 28, 14);
  final encryptor = CardEncryptor(clock: () => sentAt);

  test('the backend key can open what the app seals', () {
    final key = testEncryptionKey();
    final envelope = encryptor.seal(card, key);

    expect(openTestEnvelope(envelope), {
      'pan': '6037991234561234',
      'expMonth': 12,
      'expYear': 2029,
      'holder': 'Demo Customer',
      'ts': sentAt.millisecondsSinceEpoch,
    });
    expect(envelope.kid, key.kid);
  });

  test('the card number never appears in the envelope', () {
    final json = jsonEncode(encryptor.seal(card, testEncryptionKey()).toJson());
    expect(json, isNot(contains('6037991234561234')));
    expect(json, isNot(contains('Demo Customer')));
  });

  test('uses a fresh key and nonce for every envelope', () {
    final key = testEncryptionKey();
    final a = encryptor.seal(card, key);
    final b = encryptor.seal(card, key);

    expect(a.iv, isNot(b.iv));
    expect(a.ek, isNot(b.ek));
    expect(a.ct, isNot(b.ct));
  });

  test('ciphertext is bound to its key id', () {
    final envelope = encryptor.seal(card, testEncryptionKey());

    expect(
      () => openTestEnvelope(envelope, aadKid: 'another-key'),
      throwsA(anything),
    );
  });

  test('has the wire shape the backend validates', () {
    final json = encryptor.seal(card, testEncryptionKey()).toJson();
    final b64url = RegExp(r'^[A-Za-z0-9_-]+$');

    expect(json['v'], 1);
    for (final field in ['kid', 'ek', 'iv', 'ct']) {
      expect(json[field], matches(b64url), reason: field);
    }
    expect(
      base64Url.decode(base64Url.normalize(json['iv']! as String)),
      hasLength(12),
    );
  });

  group('CardEncryptionKey', () {
    test('computes the RFC 7638 thumbprint (same vector as the backend)', () {
      expect(
        CardEncryptionKey.thumbprint(
          e: 'AQAB',
          n: '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
        ),
        'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs',
      );
    });

    test('rejects a key whose kid is not its own thumbprint', () {
      final jwk = testJwk()..['kid'] = 'forged';
      expect(() => CardEncryptionKey.fromJwk(jwk), throwsFormatException);
    });

    test('rejects non-RSA or incomplete keys', () {
      expect(
        () => CardEncryptionKey.fromJwk({...testJwk(), 'kty': 'EC'}),
        throwsFormatException,
      );
      expect(
        () => CardEncryptionKey.fromJwk({...testJwk()}..remove('n')),
        throwsFormatException,
      );
    });
  });
}
