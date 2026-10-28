import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Future<void> _runBalanceInquiry(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('Balance Inquiry'));
  await tester.enterText(find.byType(TextFormField).first, 'WALLET-7814');
  await tester.tap(find.text('Run inquiry'));
  await tester.pumpAndSettle();
}

/// Opens Cash in and fills the manual card, agent and amount fields.
Future<void> _fillCashIn(WidgetTester tester, {required String amount}) async {
  await tester.tap(find.text('Cash in'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Card number'),
    '6037991234561234',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Agent ID'),
    'AGENT-1',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), amount);
  await tester.tap(find.text('Review and submit'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a failed payment shows an error and stops loading', (
    tester,
  ) async {
    final gateway = FakePaymentGateway()
      ..error = const ApiException(401, 'Unauthorized');
    await pumpApp(tester, gateway: gateway);

    await _runBalanceInquiry(tester);

    expect(
      find.text('The payment could not be completed. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Run inquiry'), findsOneWidget);
  });

  testWidgets('the result dialog reflects a pending state', (tester) async {
    final gateway = FakePaymentGateway(state: TransactionState.processing);
    await pumpApp(tester, gateway: gateway);

    await _runBalanceInquiry(tester);

    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('a successful payment can open its receipt', (tester) async {
    useTallScreen(tester);
    final gateway = FakePaymentGateway();
    await pumpApp(tester, gateway: gateway);

    await _fillCashIn(tester, amount: '500');

    expect(gateway.requests.single.amount, 500);
    expect(gateway.requests.single.operation, PaymentOperation.cashIn);
    expect(find.text('Successful'), findsOneWidget);

    await tester.tap(find.text('View receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction receipt'), findsOneWidget);
  });

  testWidgets('Done closes the payment and returns home', (tester) async {
    useTallScreen(tester);
    await pumpApp(tester);

    await _fillCashIn(tester, amount: '500');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('Review and submit'), findsNothing);
  });

  testWidgets('amounts above the active limit are blocked before sending', (
    tester,
  ) async {
    useTallScreen(tester);
    final gateway = FakePaymentGateway();
    await pumpApp(tester, gateway: gateway);

    await _fillCashIn(tester, amount: '999999');

    expect(
      find.text('Amount exceeds your active transaction limit'),
      findsOneWidget,
    );
    expect(gateway.requests, isEmpty);
  });

  testWidgets('required fields are validated before sending', (tester) async {
    final gateway = FakePaymentGateway();
    await pumpApp(tester, gateway: gateway);

    await scrollToAndTap(tester, find.text('Balance Inquiry'));
    await tester.tap(find.text('Run inquiry'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(gateway.requests, isEmpty);
  });
}
