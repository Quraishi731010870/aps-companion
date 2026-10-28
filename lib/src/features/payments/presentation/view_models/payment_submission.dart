import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../activity/presentation/view_models/activities.dart';
import '../../data/payment_gateway_provider.dart';
import '../../domain/idempotency_key.dart';
import '../../domain/payment_transaction.dart';

part 'payment_submission.g.dart';

/// ViewModel for submitting one payment. `null` data means nothing submitted
/// yet; errors surface as [AsyncError] for the view to report.
@riverpod
class PaymentSubmission extends _$PaymentSubmission {
  PaymentRequest? _lastFailed;

  @override
  FutureOr<PaymentResult?> build() => null;

  Future<void> submit({
    required PaymentOperation operation,
    required String source,
    required String destination,
    required double amount,
    required String reference,
  }) async {
    if (state.isLoading) return; // double-tap guard
    final request = PaymentRequest(
      operation: operation,
      source: source,
      destination: destination,
      amount: amount,
      reference: reference,
      idempotencyKey: _keyFor(
        operation,
        source,
        destination,
        amount,
        reference,
      ),
    );
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(paymentGatewayProvider).execute(request),
    );
    if (!ref.mounted) return;
    _lastFailed = result.hasError ? request : null;
    state = result;
    if (result.hasValue) ref.invalidate(activitiesProvider);
  }

  /// Retrying the same payment reuses its key so the backend can return the
  /// original result instead of debiting twice (APS p.24). Any edit is a new
  /// payment and gets a new key.
  String _keyFor(
    PaymentOperation operation,
    String source,
    String destination,
    double amount,
    String reference,
  ) {
    final previous = _lastFailed;
    final isRetry =
        previous != null &&
        previous.operation == operation &&
        previous.source == source &&
        previous.destination == destination &&
        previous.amount == amount &&
        previous.reference == reference;
    return isRetry ? previous.idempotencyKey : IdempotencyKey.generate();
  }
}
