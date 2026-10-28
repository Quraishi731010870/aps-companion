import 'dart:convert';

import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:afghan_emi/src/features/payments/data/backend_card_vault.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/saved_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../helpers/card_crypto.dart';
import '../../../helpers/test_app.dart';

const _card = CardDetails(
  pan: '6037991234561234',
  expiryMonth: 12,
  expiryYear: 2029,
);

void main() {
  late SecureStore store;
  late List<http.Request> requests;

  setUp(() {
    mockSecureStorage();
    store = SecureStore();
    requests = [];
  });

  BackendCardVault vault({String? pin, bool isRelease = false}) =>
      BackendCardVault(
        ApiClient(
          baseUrl: 'http://api.test',
          store: store,
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/api/v1/cards/encryption-key') {
              return http.Response(jsonEncode(testJwk()), 200);
            }
            return http.Response(
              jsonEncode({
                'token': 'ctok_abc',
                'maskedPan': '603799******1234',
                'expiryMonth': 12,
                'expiryYear': 2029,
                'holderName': null,
              }),
              201,
            );
          }),
        ),
        store,
        AppEnvironment(
          apiBaseUrl: 'http://api.test',
          cardKeySha256: pin ?? testJwk()['kid'] as String,
          isRelease: isRelease,
        ),
      );

  test(
    'saving sends only an encrypted card and keeps only the token',
    () async {
      final saved = await vault().saveCard(_card);

      expect(saved.token, 'ctok_abc');
      expect(saved.maskedPan, '603799******1234');
      final post = requests.singleWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/v1/cards');
      expect(post.body, isNot(contains('6037991234561234')));
      final envelope = (jsonDecode(post.body) as Map)['encryptedCard'] as Map;
      expect(envelope.keys, containsAll(['v', 'kid', 'ek', 'iv', 'ct']));

      final stored = await store.read(SecureKey.linkedCard);
      expect(stored, isNot(contains('6037991234561234')));
      expect(SavedCard.fromJson(jsonDecode(stored!)), saved);
    },
  );

  test('the linked card survives a restart', () async {
    await vault().saveCard(_card);

    final restored = await vault().linkedCard();

    expect(restored?.token, 'ctok_abc');
  });

  test('a payment card is encrypted with the pinned key', () async {
    final envelope = await vault().encryptForPayment(_card);

    expect(envelope.kid, testJwk()['kid']);
    expect(openTestEnvelope(envelope)['pan'], '6037991234561234');
  });

  test('the key is fetched once and reused', () async {
    final cards = vault();
    await cards.encryptForPayment(_card);
    await cards.encryptForPayment(_card);

    expect(
      requests.where((r) => r.url.path.endsWith('/encryption-key')),
      hasLength(1),
    );
  });

  test('a key that is not the pinned one is refused', () async {
    await expectLater(
      vault(pin: 'some-other-key').encryptForPayment(_card),
      throwsA(isA<CardKeyMismatch>()),
    );
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  test('release builds refuse to send cards without a pinned key', () async {
    await expectLater(
      vault(pin: '', isRelease: true).saveCard(_card),
      throwsA(isA<CardKeyMismatch>()),
    );
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  test('no linked card when nothing is stored', () async {
    expect(await vault().linkedCard(), isNull);
  });
}
