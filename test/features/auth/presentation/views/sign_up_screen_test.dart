import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/auth_failure.dart';
import 'package:afghan_emi/src/features/auth/presentation/views/session_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);
Finder get _create => find.widgetWithText(FilledButton, 'Create account');

Future<void> _openSignUp(WidgetTester tester, FakeAuthRepository auth) async {
  useTallScreen(tester);
  await pumpScreen(
    tester,
    const SessionGate(child: Text('APP CONTENT')),
    overrides: [
      appEnvironmentProvider.overrideWithValue(
        const AppEnvironment(
          apiBaseUrl: 'http://localhost:8081',
          isRelease: false,
        ),
      ),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  await tester.tap(find.text('New here? Create an account'));
  await tester.pumpAndSettle();
  expect(find.text('Create your account'), findsOneWidget);
}

Future<void> _fill(
  WidgetTester tester, {
  String confirm = 'long-password',
}) async {
  await tester.enterText(_field('Full name'), '  New Customer ');
  await tester.enterText(_field('Phone number'), '0701234567');
  await tester.enterText(_field('Password'), 'long-password');
  await tester.enterText(_field('Confirm password'), confirm);
}

void main() {
  setUp(mockSecureStorage);

  testWidgets('creates the customer, signs in and opens the app', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _openSignUp(tester, auth);

    await _fill(tester);
    await tester.tap(_create);
    await tester.pumpAndSettle();

    expect(auth.registrations, [
      ('New Customer', '+93701234567', 'long-password'),
    ]);
    expect(find.text('APP CONTENT'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
  });

  testWidgets('checks the password rules and confirmation first', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _openSignUp(tester, auth);

    await tester.enterText(_field('Password'), 'short');
    await tester.enterText(_field('Confirm password'), 'different');
    await tester.tap(_create);
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Use at least 10 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(auth.registrations, isEmpty);
  });

  testWidgets('a registered phone number is explained', (tester) async {
    final auth = FakeAuthRepository()..error = AuthFailure.phoneInUse;
    await _openSignUp(tester, auth);

    await _fill(tester);
    await tester.tap(_create);
    await tester.pumpAndSettle();

    expect(
      find.text('This phone number is already registered. Sign in instead.'),
      findsOneWidget,
    );
    expect(find.text('APP CONTENT'), findsNothing);
  });
}
