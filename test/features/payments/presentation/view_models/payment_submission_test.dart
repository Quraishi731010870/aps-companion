import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/activity/presentation/view_models/activities.dart';
import 'package:afghan_emi/src/features/payments/data/card_vault_provider.dart';
import 'package:afghan_emi/src/features/payments/data/payment_gateway_provider.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/payment_submission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  late FakePaymentGateway gateway;
  late FakeCardVault vault;
  late ProviderContainer container;

  setUp(() {
    gateway = FakePaymentGateway();
    vault = FakeCardVault();
    container = ProviderContainer.test(
      overrides: [
        paymentGatewayProvider.overrideWithValue(gateway),
        cardVaultProvider.overrideWithValue(vault),
      ],
    );
    // Keep the autoDispose view model alive for the whole test.
    container.listen(paymentSubmissionProvider, (_, _) {});
  });

  Future<void> submit({double amount = 100}) => container
      .read(paymentSubmissionProvider.notifier)
      .submit(
        operation: PaymentOperation.cardToCard,
        source: 'WALLET-7814',
        destination: '6037990000001234',
        amount: amount,
        reference: 'rent',
      );

  test('starts with nothing submitted', () {
    final submission = container.read(paymentSubmissionProvider);
    expect(submission.hasValue, isTrue);
    expect(submission.value, isNull);
  });

  test('success exposes the gateway result', () async {
    gateway.state = TransactionState.processing;
    await submit();

    final result = container.read(paymentSubmissionProvider).value;
    expect(result?.state, TransactionState.processing);
    expect(result?.request.amount, 100);
  });

  test('failure becomes AsyncError instead of throwing', () async {
    gateway.error = const ApiException(401, 'Unauthorized');
    await submit();

    expect(container.read(paymentSubmissionProvider).hasError, isTrue);
    expect(container.read(paymentSubmissionProvider).isLoading, isFalse);
  });

  test('retrying the same failed payment reuses its idempotency key', () async {
    gateway.error = const ApiException(504, 'Timeout');
    await submit();
    gateway.error = null;
    await submit();

    expect(gateway.requests, hasLength(2));
    expect(
      gateway.requests[1].idempotencyKey,
      gateway.requests[0].idempotencyKey,
    );
  });

  test('an edited payment gets a new idempotency key', () async {
    gateway.error = const ApiException(504, 'Timeout');
    await submit(amount: 100);
    await submit(amount: 200);

    expect(
      gateway.requests[1].idempotencyKey,
      isNot(gateway.requests[0].idempotencyKey),
    );
  });

  test('a second tap while submitting is ignored', () async {
    final first = submit();
    final second = submit();
    await Future.wait([first, second]);

    expect(gateway.requests, hasLength(1));
  });

  test('a successful payment reloads the activity history', () async {
    container.listen(activitiesProvider, (_, _) {});
    await container.read(activitiesProvider.future);
    expect(gateway.activityFetches, 1);

    await submit();
    await container.read(activitiesProvider.future);

    expect(gateway.activityFetches, 2);
  });

  test('a failed payment leaves the history untouched', () async {
    container.listen(activitiesProvider, (_, _) {});
    await container.read(activitiesProvider.future);
    gateway.error = const ApiException(500, 'Server error');

    await submit();
    await container.read(activitiesProvider.future);

    expect(gateway.activityFetches, 1);
  });

  group('card payments', () {
    Future<void> payWithCard(String pan) => container
        .read(paymentSubmissionProvider.notifier)
        .submit(
          operation: PaymentOperation.purchase,
          source: pan,
          destination: 'MERCHANT-1',
          amount: 250,
          reference: '',
          card: CardDetails(pan: pan),
        );

    test(
      'a typed-in card is sent masked and encrypted, never in clear',
      () async {
        await payWithCard('6037991234561234');

        final request = gateway.requests.single;
        expect(request.source, '603799******1234');
        expect(request.encryptedCard, FakeCardVault.envelope);
        expect(
          jsonEncode(request.toJson()),
          isNot(contains('6037991234561234')),
        );
        expect(vault.encrypted.single.pan, '6037991234561234');
      },
    );

    test('the linked card is sent as its vault token', () async {
      await container
          .read(paymentSubmissionProvider.notifier)
          .submit(
            operation: PaymentOperation.purchase,
            source: '603799******1234',
            destination: 'MERCHANT-1',
            amount: 250,
            reference: '',
            cardToken: 'ctok_test',
          );

      expect(gateway.requests.single.cardToken, 'ctok_test');
      expect(gateway.requests.single.encryptedCard, isNull);
    });

    test('retrying the same card reuses the idempotency key', () async {
      gateway.error = const ApiException(504, 'Timeout');
      await payWithCard('6037991234561234');
      gateway.error = null;
      await payWithCard('6037991234561234');

      expect(
        gateway.requests[1].idempotencyKey,
        gateway.requests[0].idempotencyKey,
      );
    });

    test('a different card is a new payment with a new key', () async {
      gateway.error = const ApiException(504, 'Timeout');
      await payWithCard('6037991234561234');
      await payWithCard('6037999999995678');

      expect(
        gateway.requests[1].idempotencyKey,
        isNot(gateway.requests[0].idempotencyKey),
      );
    });

    test(
      'an encryption failure is a payment error and nothing is sent',
      () async {
        vault.error = Exception('key unavailable');
        await payWithCard('6037991234561234');

        expect(container.read(paymentSubmissionProvider).hasError, isTrue);
        expect(gateway.requests, isEmpty);
      },
    );
  });
}
