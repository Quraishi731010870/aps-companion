import 'dart:async';

import '../domain/payment_transaction.dart';

abstract interface class PaymentGateway {
  Future<PaymentResult> execute(PaymentRequest request);
  Future<List<WalletActivity>> fetchActivities();
}

/// Development gateway only. Replace with a regulated, authenticated EMI API.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<List<WalletActivity>> fetchActivities() async => mockActivities;

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

final mockActivities = <WalletActivity>[
  WalletActivity(
    title: 'Salary payment',
    subtitle: 'Kabul Trading Co.',
    amount: 18500,
    incoming: true,
    operation: PaymentOperation.cardToWallet,
    date: DateTime.now().subtract(const Duration(hours: 2)),
    source: 'Kabul Trading Co. payroll',
    destination: 'WALLET-7814',
    rrn: '426981730112',
  ),
  WalletActivity(
    title: 'Mobile top-up',
    subtitle: 'Roshan • 079 123 4567',
    amount: 500,
    incoming: false,
    operation: PaymentOperation.purchase,
    date: DateTime.now().subtract(const Duration(days: 1)),
    source: 'APS card •••• 1087',
    destination: 'Roshan 0791234567',
    rrn: '426872119408',
    fee: 5,
  ),
  WalletActivity(
    title: 'Bank transfer',
    subtitle: 'Azizi Bank • •••• 1942',
    amount: 2200,
    incoming: false,
    operation: PaymentOperation.walletToCard,
    date: DateTime.now().subtract(const Duration(days: 2)),
    source: 'WALLET-7814',
    destination: 'Azizi Bank •••• 1942',
    rrn: 'UTR-AF-785-903184',
    fee: 10,
  ),
  WalletActivity(
    title: 'Electricity bill',
    subtitle: 'DABS • Kabul',
    amount: 1375,
    incoming: false,
    operation: PaymentOperation.purchase,
    date: DateTime.now().subtract(const Duration(days: 4)),
    source: 'APS card •••• 1087',
    destination: 'DABS Kabul 994712',
    rrn: '426553881209',
    fee: 15,
  ),
  WalletActivity(
    title: 'Cash deposit',
    subtitle: 'Shahr-e-Naw agent',
    amount: 5000,
    incoming: true,
    operation: PaymentOperation.cashIn,
    date: DateTime.now().subtract(const Duration(days: 7)),
    source: 'Shahr-e-Naw agent AGT-019',
    destination: 'WALLET-7814',
    rrn: '426093725841',
  ),
];
