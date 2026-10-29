import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:afghan_emi/src/features/payments/presentation/views/receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WalletActivity _activity({required TransactionState status, String rrn = ''}) =>
    WalletActivity(
      title: 'Purchase',
      subtitle: 'MERCHANT-1',
      amount: 250,
      incoming: false,
      operation: PaymentOperation.purchase,
      date: DateTime(2026, 10, 29, 12),
      source: 'WALLET-AF000001',
      destination: 'MERCHANT-1',
      rrn: rrn,
      status: status,
    );

Future<void> _pump(WidgetTester tester, WalletActivity activity) =>
    tester.pumpWidget(MaterialApp(home: ReceiptScreen(activity: activity)));

void main() {
  testWidgets('a pending transaction with no RRN shows as pending', (
    tester,
  ) async {
    await _pump(tester, _activity(status: TransactionState.processing));

    expect(tester.takeException(), isNull);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Successful'), findsNothing);
    expect(find.text('Not settled'), findsOneWidget);
    expect(find.text('Authorization code'), findsNothing);
    expect(find.text('RRN / UTR'), findsNothing);
  });

  testWidgets('a successful transaction shows its RRN and settlement', (
    tester,
  ) async {
    await _pump(
      tester,
      _activity(status: TransactionState.successful, rrn: '426981730112'),
    );

    expect(find.text('Successful'), findsWidgets);
    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('426981'), findsOneWidget);
  });
}
