import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/device_integrity/data/device_integrity_checker.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:afghan_emi/src/features/device_integrity/presentation/view_models/device_integrity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  late FakeDeviceIntegrityChecker checker;

  ProviderContainer containerFor({required bool isRelease}) {
    final container = ProviderContainer.test(
      overrides: [
        deviceIntegrityCheckerProvider.overrideWithValue(checker),
        appEnvironmentProvider.overrideWithValue(
          AppEnvironment(isRelease: isRelease),
        ),
      ],
    );
    container.listen(integrityStatusProvider, (_, _) {});
    return container;
  }

  setUp(() => checker = FakeDeviceIntegrityChecker());

  test('release builds enforce what the checks find', () async {
    checker.signals = {IntegritySignal.rooted};
    final container = containerFor(isRelease: true);
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.blockPayments,
      reason: 'fails closed before the first check finishes',
    );
    await container.read(deviceIntegrityProvider.future);
    final status = container.read(integrityStatusProvider);
    expect(status.enforced, isTrue);
    expect(status.verdict, IntegrityVerdict.blockApp);
  });

  test('release builds ignore developer overrides', () async {
    final container = containerFor(isRelease: true);
    await container.read(deviceIntegrityProvider.future);
    container.read(integrityOverridesControllerProvider.notifier)
      ..setEnforced(false)
      ..setSimulated(IntegritySignal.rooted, true);
    final status = container.read(integrityStatusProvider);
    expect(status.simulated, isEmpty);
    expect(status.verdict, IntegrityVerdict.allow);
  });

  test('debug builds report without enforcing by default', () async {
    checker.signals = {IntegritySignal.emulator, IntegritySignal.debugger};
    final container = containerFor(isRelease: false);
    await container.read(deviceIntegrityProvider.future);
    final status = container.read(integrityStatusProvider);
    expect(status.detected, checker.signals);
    expect(status.risk, IntegrityRisk.medium);
    expect(status.verdict, IntegrityVerdict.allow);
  });

  test('developer mode can enforce and simulate in debug builds', () async {
    final container = containerFor(isRelease: false);
    await container.read(deviceIntegrityProvider.future);
    final overrides = container.read(
      integrityOverridesControllerProvider.notifier,
    );

    overrides
      ..setEnforced(true)
      ..setSimulated(IntegritySignal.developerOptions, true);
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.warn,
    );

    overrides.setSimulated(IntegritySignal.hookingFramework, true);
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.blockApp,
    );

    overrides.setSimulated(IntegritySignal.hookingFramework, false);
    expect(container.read(integrityStatusProvider).simulated, {
      IntegritySignal.developerOptions,
    });

    overrides.reset();
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.allow,
    );
  });

  test('recheck runs the checks again and picks up new findings', () async {
    final container = containerFor(isRelease: true);
    await container.read(deviceIntegrityProvider.future);
    expect(checker.checks, 1);

    checker.signals = {IntegritySignal.hookingFramework};
    final report = await container
        .read(deviceIntegrityProvider.notifier)
        .recheck();

    expect(checker.checks, 2);
    expect(report.signals, {IntegritySignal.hookingFramework});
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.blockApp,
    );
  });
}
