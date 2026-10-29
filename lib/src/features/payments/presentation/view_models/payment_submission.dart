import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../activity/presentation/view_models/activities.dart';
import '../../data/card_vault_provider.dart';
import '../../data/payment_gateway_provider.dart';
import '../../domain/card_details.dart';
import '../../domain/idempotency_key.dart';
import '../../domain/payment_transaction.dart';
import 'wallet.dart';

part 'payment_submission.g.dart';

/// Everything that makes two submissions "the same payment".
typedef _Attempt = (
  PaymentOperation operation,
  String source,
  String destination,
  double amount,
  String reference,
  String? cardToken,
  CardDetails? card,
);

/// ViewModel for submitting one payment. `null` data means nothing submitted
/// yet; errors surface as [AsyncError] for the view to report.
@riverpod
class PaymentSubmission extends _$PaymentSubmission {
  ({_Attempt attempt, String key})? _lastFailed;

  @override
  FutureOr<PaymentResult?> build() => null;

  /// Pays from [source] (wallet), the linked card ([cardToken]) or a card
  /// typed in for this payment ([card], encrypted before it is sent).
  Future<void> submit({
    required PaymentOperation operation,
    required String source,
    required String destination,
    required double amount,
    required String reference,
    String? cardToken,
    CardDetails? card,
  }) async {
    if (state.isLoading) return; // double-tap guard
    final _Attempt attempt = (
      operation,
      source,
      destination,
      amount,
      reference,
      cardToken,
      card,
    );
    final key = _keyFor(attempt);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final encryptedCard = card == null
          ? null
          : await ref.read(cardVaultProvider).encryptForPayment(card);
      return ref
          .read(paymentGatewayProvider)
          .execute(
            PaymentRequest(
              operation: operation,
              source: card?.maskedPan ?? source,
              destination: destination,
              amount: amount,
              reference: reference,
              idempotencyKey: key,
              cardToken: cardToken,
              encryptedCard: encryptedCard,
            ),
          );
    });
    if (!ref.mounted) return;
    _lastFailed = result.hasError ? (attempt: attempt, key: key) : null;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(activitiesProvider)
        ..invalidate(walletProvider);
    }
  }

  /// Retrying the same payment reuses its key so the backend can return the
  /// original result instead of debiting twice (APS p.24). Any edit is a new
  /// payment and gets a new key.
  String _keyFor(_Attempt attempt) {
    final previous = _lastFailed;
    return previous != null && previous.attempt == attempt
        ? previous.key
        : IdempotencyKey.generate();
  }
}
