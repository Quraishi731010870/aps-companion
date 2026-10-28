import 'package:afghan_emi/src/data/payment_gateway_provider.dart';
import 'package:afghan_emi/src/domain/payment_transaction.dart';
import 'package:afghan_emi/src/network/api_client.dart';
import 'package:afghan_emi/src/state/activities.dart';
import 'package:afghan_emi/src/state/payment_submission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late FakePaymentGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakePaymentGateway();
    container = ProviderContainer.test(
      overrides: [paymentGatewayProvider.overrideWithValue(gateway)],
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
}
