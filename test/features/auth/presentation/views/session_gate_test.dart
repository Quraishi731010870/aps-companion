import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/presentation/views/session_gate.dart';
import 'package:afghan_emi/src/features/auth/presentation/views/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

const _app = Text('APP CONTENT');

Future<void> _pumpGate(
  WidgetTester tester,
  FakeAuthRepository auth, {
  AppEnvironment environment = backendWithTestUser,
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

  testWidgets('stored tokens open the app', (tester) async {
    await _pumpGate(tester, FakeAuthRepository(hasTokens: true));

    expect(find.text('APP CONTENT'), findsOneWidget);
  });

  testWidgets('signed out shows the sign-in screen', (tester) async {
    await _pumpGate(tester, FakeAuthRepository());

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('APP CONTENT'), findsNothing);
  });

  testWidgets('offline mock mode opens the app without signing in', (
    tester,
  ) async {
    await _pumpGate(
      tester,
      FakeAuthRepository(),
      environment: const AppEnvironment(),
    );

    expect(find.text('APP CONTENT'), findsOneWidget);
  });
}
