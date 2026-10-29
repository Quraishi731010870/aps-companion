import 'dart:async';

import '../domain/payment_gateway.dart';
import '../domain/payment_transaction.dart';
import '../domain/wallet.dart';

/// Offline development gateway: no sample data, an empty wallet, and
/// payments that succeed without moving money or calling the network.
class MockPaymentGateway implements PaymentGateway {
  static const offlineWallet = Wallet(
    id: 'WALLET-OFFLINE',
    currency: 'AFN',
    availableBalance: 0,
  );

  @override
  Future<List<WalletActivity>> fetchActivities() async => const [];

  @override
  Future<Wallet> fetchWallet() async => offlineWallet;

  @override
  Future<PaymentResult> execute(PaymentRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    return PaymentResult(
      request: request,
      transactionId: 'EMI-${now.microsecondsSinceEpoch}',
      state: TransactionState.successful,
      message: _message(request.operation),
      createdAt: now,
    );
  }

  String _message(PaymentOperation operation) => switch (operation) {
    PaymentOperation.balanceInquiry => 'Balance retrieved successfully',
    PaymentOperation.nameInquiry => 'Account holder verified',
    PaymentOperation.billInfo => 'Bill information retrieved',
    PaymentOperation.billPayment => 'Bill paid successfully',
    PaymentOperation.savePayment => 'Payment beneficiary saved',
    _ => '${operation.label} completed successfully',
  };
}
