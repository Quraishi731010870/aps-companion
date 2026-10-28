import 'payment_transaction.dart';

/// Abstraction every payment backend implements, so view models never depend
/// on a concrete gateway.
abstract interface class PaymentGateway {
  Future<PaymentResult> execute(PaymentRequest request);
  Future<List<WalletActivity>> fetchActivities();
}
