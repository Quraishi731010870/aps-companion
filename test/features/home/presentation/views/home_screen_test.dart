import 'package:afghan_emi/src/core/remote_config/state/mobile_config.dart';
import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/current_user.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/wallet.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/linked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void _useScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Rect _tile(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
);

void main() {
  testWidgets('the balance can be hidden and shown again', (tester) async {
    await pumpApp(tester);
    expect(find.text('24,560 AFN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.text('•••••• AFN'), findsOneWidget);
    expect(find.text('24,560 AFN'), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.text('24,560 AFN'), findsOneWidget);
  });

  testWidgets('shows the wallet id from the backend, not a fixed value', (
    tester,
  ) async {
    await pumpApp(
      tester,
      gateway: FakePaymentGateway(
        wallet: const Wallet(
          id: 'WALLET-AF000042',
          currency: 'AFN',
          availableBalance: 0,
        ),
      ),
    );

    expect(find.text('0 AFN'), findsOneWidget);
    expect(find.text('Wallet ID  •••• 0042'), findsOneWidget);
  });

  testWidgets('a wallet error offers a retry instead of a balance', (
    tester,
  ) async {
    final gateway = FakePaymentGateway()..walletError = Exception('down');
    await pumpApp(tester, gateway: gateway);

    expect(find.text('Balance unavailable'), findsOneWidget);

    gateway.walletError = null;
    await tester.tap(find.byTooltip('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('24,560 AFN'), findsOneWidget);
  });

  testWidgets('phones show four service tiles per row', (tester) async {
    _useScreen(tester, const Size(390, 2400));
    await pumpApp(tester);

    final first = _tile(tester, 'Balance Inquiry');
    expect(_tile(tester, 'C2W').top, first.top);
    expect(_tile(tester, 'P2P').top, greaterThan(first.top));
  });

  testWidgets('tablets fit more tiles per row without stretching them', (
    tester,
  ) async {
    _useScreen(tester, const Size(820, 2400));
    await pumpApp(tester);

    final first = _tile(tester, 'Balance Inquiry');
    expect(_tile(tester, 'P2P').top, first.top);
    expect(first.height, lessThan(130));
    expect(first.width, lessThanOrEqualTo(104));
  });

  testWidgets('service tiles do not overflow at 1.3x text', (tester) async {
    _useScreen(tester, const Size(360, 2400));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Bill Payment'), findsOneWidget);
  });

  testWidgets('disabled feature flags remove services from the grid', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(
      tester,
      overrides: [
        currentConfigProvider.overrideWithValue(
          testConfig(features: {'balance_inquiry': false}),
        ),
      ],
    );

    expect(find.text('Balance Inquiry'), findsNothing);
    expect(find.text('Name Inquiry'), findsOneWidget);
  });

  testWidgets('shows the most recent four activities from the gateway', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester);

    expect(find.text('Salary payment'), findsOneWidget);
    expect(find.text('Electricity bill'), findsOneWidget);
    // The fifth mock activity is only on the Activity tab.
    expect(find.text('Cash deposit'), findsNothing);
  });

  testWidgets('no transactions shows an empty state on Home', (tester) async {
    useTallScreen(tester);
    await pumpApp(tester, gateway: FakePaymentGateway(activities: const []));

    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('recent activity errors offer a retry', (tester) async {
    useTallScreen(tester);
    final gateway = FakePaymentGateway()..activitiesError = Exception('down');
    await pumpApp(tester, gateway: gateway);

    expect(find.text('Recent activity could not be loaded.'), findsOneWidget);

    gateway.activitiesError = null;
    await tester.tap(find.text('Try again').first);
    await tester.pumpAndSettle();

    expect(find.text('Salary payment'), findsWidgets);
  });

  testWidgets('a linked card from the provider is shown on Home', (
    tester,
  ) async {
    await pumpApp(tester);

    await containerOf(tester)
        .read(linkedCardProvider.notifier)
        .link(const CardDetails(pan: '6037991234561234'));
    await tester.pump();

    expect(find.text('APS card 6037 99** **** 1234'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('No card linked'), findsNothing);
  });

  testWidgets('greets the signed-in user by name', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        currentUserProvider.overrideWith(
          (ref) async => FakeAuthRepository.testUser,
        ),
      ],
    );

    expect(find.text('Demo Customer 001'), findsOneWidget);
    expect(find.text('Asif Quraishi'), findsNothing);
  });

  testWidgets('offline mock mode greets the demo user', (tester) async {
    await pumpApp(tester);

    expect(find.text(UserProfile.demo.displayName), findsOneWidget);
  });
}
