import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/auth_failure.dart';
import 'package:afghan_emi/src/features/auth/presentation/views/session_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

const _app = Text('APP CONTENT');

Finder _field(String label) => find.widgetWithText(TextFormField, label);
Finder get _signIn => find.widgetWithText(FilledButton, 'Sign in');

Future<void> _pump(
  WidgetTester tester,
  FakeAuthRepository auth, {
  AppEnvironment environment = const AppEnvironment(
    apiBaseUrl: 'http://localhost:8081',
    isRelease: false,
  ),
}) => pumpScreen(
  tester,
  const SessionGate(child: _app),
  overrides: [
    appEnvironmentProvider.overrideWithValue(environment),
    authRepositoryProvider.overrideWithValue(auth),
  ],
);

void main() {
  setUp(mockSecureStorage);

  testWidgets('signs in with a normalized phone number and opens the app', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _pump(tester, auth);

    await tester.enterText(_field('Phone number'), '070 123 4567');
    await tester.enterText(_field('Password'), 'secret-pass');
    await tester.tap(_signIn);
    await tester.pumpAndSettle();

    expect(auth.signIns, [('+93701234567', 'secret-pass')]);
    expect(find.text('APP CONTENT'), findsOneWidget);
  });

  testWidgets('validates before calling the server', (tester) async {
    final auth = FakeAuthRepository();
    await _pump(tester, auth);

    await tester.enterText(_field('Phone number'), '12345');
    await tester.tap(_signIn);
    await tester.pumpAndSettle();

    expect(find.text('Enter an Afghan mobile number'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(auth.signIns, isEmpty);
  });

  testWidgets('wrong credentials show a message and clear the password', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..error = AuthFailure.invalidCredentials;
    await _pump(tester, auth);

    await tester.enterText(_field('Phone number'), '+93701234567');
    await tester.enterText(_field('Password'), 'wrong-password');
    await tester.tap(_signIn);
    await tester.pumpAndSettle();

    expect(
      find.text('The phone number or password is incorrect.'),
      findsOneWidget,
    );
    expect(find.text('wrong-password'), findsNothing);
    expect(find.text('APP CONTENT'), findsNothing);
  });

  testWidgets('debug builds pre-fill the test user but do not sign in', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _pump(tester, auth, environment: backendWithTestUser);

    expect(find.text('+93790000001'), findsOneWidget);
    expect(auth.signIns, isEmpty);
    expect(find.text('APP CONTENT'), findsNothing);
  });

  testWidgets('release builds offer no sign-up and no pre-filled user', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeAuthRepository(),
      environment: const AppEnvironment(
        apiBaseUrl: 'http://localhost:8081',
        testUserIdentifier: '+93790000001',
        testUserPassword: 'test-password',
        isRelease: true,
      ),
    );

    expect(find.text('New here? Create an account'), findsNothing);
    expect(find.text('+93790000001'), findsNothing);
  });
}
