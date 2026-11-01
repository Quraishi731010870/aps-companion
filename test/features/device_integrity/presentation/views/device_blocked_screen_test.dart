import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  late FakeDeviceIntegrityChecker checker;

  setUp(() => checker = FakeDeviceIntegrityChecker());

  Future<void> pump(WidgetTester tester, {required bool isRelease}) => pumpApp(
    tester,
    integrity: checker,
    overrides: [
      appEnvironmentProvider.overrideWithValue(
        AppEnvironment(isRelease: isRelease),
      ),
    ],
  );

  testWidgets('a rooted device is locked out of a release build', (
    tester,
  ) async {
    checker.signals = {IntegritySignal.rooted};
    await pump(tester, isRelease: true);

    expect(find.text('This device cannot be used'), findsOneWidget);
    expect(find.text('• Root or jailbreak'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Developer mode'), findsNothing);
  });

  testWidgets('the app returns once a re-check comes back clean', (
    tester,
  ) async {
    checker.signals = {IntegritySignal.hookingFramework};
    await pump(tester, isRelease: true);
    expect(find.text('This device cannot be used'), findsOneWidget);

    checker.signals = {};
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text('This device cannot be used'), findsNothing);
    expect(find.text('Available balance'), findsOneWidget);
  });

  testWidgets('debug builds report root without locking the app', (
    tester,
  ) async {
    checker.signals = {IntegritySignal.rooted};
    await pump(tester, isRelease: false);

    expect(find.text('This device cannot be used'), findsNothing);
    expect(find.text('Available balance'), findsOneWidget);
  });

  testWidgets('a medium-risk device sees the payments-blocked banner', (
    tester,
  ) async {
    checker.signals = {IntegritySignal.emulator};
    await pump(tester, isRelease: true);

    expect(find.text('Payments are turned off on this device'), findsOneWidget);
    expect(find.text('Available balance'), findsOneWidget);
  });
}
