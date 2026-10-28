import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/card_vault.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:afghan_emi/src/features/payments/domain/saved_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = CardDetails(pan: '6037991234561234', holderName: '  Asif  ');

  group('CardDetails', () {
    test('never prints the full number', () {
      expect('$card', 'CardDetails(603799******1234)');
      expect('$card', isNot(contains('6037991234561234')));
    });

    test('parses MM/YY expiry', () {
      expect(CardDetails.parseExpiry('12/29'), (12, 2029));
      expect(CardDetails.parseExpiry('13/29'), isNull);
      expect(CardDetails.parseExpiry('1/29'), isNull);
    });

    test('payload includes only the fields that are set, plus a timestamp', () {
      final sentAt = DateTime.utc(2026, 10, 28);
      expect(card.toPayload(sentAt), {
        'pan': '6037991234561234',
        'holder': 'Asif',
        'ts': sentAt.millisecondsSinceEpoch,
      });
    });
  });

  group('SavedCard', () {
    test('round-trips JSON and labels the masked number', () {
      const saved = SavedCard(token: 'ctok_1', maskedPan: '603799******1234');
      expect(SavedCard.fromJson(saved.toJson()), saved);
      expect(saved.label, 'APS card 6037 99** **** 1234');
    });

    test('refuses anything that is not a masked number', () {
      expect(
        SavedCard.fromJson({'token': 't', 'maskedPan': '6037991234561234'}),
        isNull,
      );
      expect(SavedCard.fromJson({'maskedPan': '603799******1234'}), isNull);
    });
  });

  group('PaymentRequest', () {
    const base = PaymentRequest(
      operation: PaymentOperation.purchase,
      source: '603799******1234',
      destination: 'MERCHANT-1',
      amount: 250,
      reference: '',
      idempotencyKey: 'key',
    );

    test('sends card fields only when they are set', () {
      expect(base.toJson().keys, isNot(contains('cardToken')));
      expect(base.toJson().keys, isNot(contains('encryptedCard')));
    });

    test('carries a vault token or an encrypted card', () {
      const withToken = PaymentRequest(
        operation: PaymentOperation.purchase,
        source: '603799******1234',
        destination: 'MERCHANT-1',
        amount: 250,
        reference: '',
        idempotencyKey: 'key',
        cardToken: 'ctok_1',
      );
      expect(withToken.toJson()['cardToken'], 'ctok_1');

      const envelope = CardEnvelope(kid: 'k', ek: 'e', iv: 'i', ct: 'c');
      const withCard = PaymentRequest(
        operation: PaymentOperation.purchase,
        source: '603799******1234',
        destination: 'MERCHANT-1',
        amount: 250,
        reference: '',
        idempotencyKey: 'key',
        encryptedCard: envelope,
      );
      expect(withCard.toJson()['encryptedCard'], envelope.toJson());
    });
  });
}
