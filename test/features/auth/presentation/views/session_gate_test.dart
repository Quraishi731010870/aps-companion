import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/presentation/views/session_gate.dart';
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
  testWidgets('shows the app once the test user is signed in', (tester) async {
    await _pumpGate(tester, FakeAuthRepository());

    expect(find.text('APP CONTENT'), findsOneWidget);
  });

  testWidgets('explains how to configure the test user when signed out', (
    tester,
  ) async {
    await _pumpGate(
      tester,
      FakeAuthRepository(),
      environment: const AppEnvironment(apiBaseUrl: 'http://localhost:8081'),
    );

    expect(find.text('APP CONTENT'), findsNothing);
    expect(find.textContaining('TEST_USER_PHONE'), findsOneWidget);
  });

  testWidgets('a sign-in failure offers retry, which opens the app', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..error = const ApiException(401, 'Invalid credentials');
    await _pumpGate(tester, auth);

    expect(
      find.text('Could not sign in to the PayAfghan server.'),
      findsOneWidget,
    );
    expect(find.text('APP CONTENT'), findsNothing);

    auth.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('APP CONTENT'), findsOneWidget);
  });
}
