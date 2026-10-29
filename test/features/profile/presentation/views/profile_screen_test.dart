import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/session_status.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/current_user.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/session.dart';
import 'package:afghan_emi/src/features/profile/presentation/views/profile_screen.dart';
import 'package:afghan_emi/src/features/settings/data/biometric_authenticator.dart';
import 'package:afghan_emi/src/features/settings/domain/biometric_outcome.dart';
import 'package:afghan_emi/src/features/settings/presentation/view_models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator(this.outcome);
  final BiometricOutcome outcome;

  @override
  Future<BiometricOutcome> verify(String localizedReason) async => outcome;
}

Future<void> _pumpProfile(WidgetTester tester, BiometricOutcome outcome) {
  useTallScreen(tester);
  return pumpScreen(
    tester,
    const ProfileScreen(),
    overrides: [
      biometricAuthenticatorProvider.overrideWithValue(
        _FakeAuthenticator(outcome),
      ),
    ],
  );
}

bool _switchValue(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

void main() {
  testWidgets('biometrics turn on after a successful check', (tester) async {
    await _pumpProfile(tester, BiometricOutcome.verified);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isTrue);
    expect(containerOf(tester).read(settingsProvider).biometricEnabled, isTrue);
  });

  testWidgets('an unavailable sensor explains why and stays off', (
    tester,
  ) async {
    await _pumpProfile(tester, BiometricOutcome.unavailable);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
    expect(
      find.text('Biometric authentication is not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('a cancelled prompt stays off silently', (tester) async {
    await _pumpProfile(tester, BiometricOutcome.cancelled);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('turning biometrics off needs no check', (tester) async {
    await _pumpProfile(tester, BiometricOutcome.verified);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
  });

  testWidgets('shows the signed-in user without the demo phone number', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpScreen(
      tester,
      const ProfileScreen(),
      overrides: [
        currentUserProvider.overrideWith(
          (ref) async => FakeAuthRepository.testUser,
        ),
      ],
    );

    expect(find.text('Demo Customer 001'), findsOneWidget);
    expect(find.text('DC'), findsOneWidget);
    expect(find.text('+93 731010870'), findsNothing);
  });

  testWidgets('offline mock mode has no sign-out', (tester) async {
    await _pumpProfile(tester, BiometricOutcome.verified);

    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('signing out ends the session', (tester) async {
    mockSecureStorage();
    useTallScreen(tester);
    final auth = FakeAuthRepository(hasTokens: true);
    await pumpScreen(
      tester,
      const ProfileScreen(),
      overrides: [
        appEnvironmentProvider.overrideWithValue(backendWithTestUser),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );

    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(
      containerOf(tester).read(sessionProvider).value,
      SessionStatus.signedOut,
    );
  });
}
