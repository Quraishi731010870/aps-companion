import 'package:afghan_emi/src/core/remote_config/state/mobile_config.dart';
import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/current_user.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/linked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

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
