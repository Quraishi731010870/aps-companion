import 'package:afghan_emi/src/data/biometric_authenticator.dart';
import 'package:afghan_emi/src/screens/profile_screen.dart';
import 'package:afghan_emi/src/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

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
}
