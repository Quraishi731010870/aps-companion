import 'package:afghan_emi/src/features/device_integrity/domain/device_integrity_report.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('risk maps to the APS response policy', () {
    expect(IntegrityRisk.none.verdict, IntegrityVerdict.allow);
    expect(IntegrityRisk.low.verdict, IntegrityVerdict.warn);
    expect(IntegrityRisk.medium.verdict, IntegrityVerdict.blockPayments);
    expect(IntegrityRisk.high.verdict, IntegrityVerdict.blockApp);
  });

  test('only allow and warn let payments through', () {
    expect(
      [for (final v in IntegrityVerdict.values) v.paymentsAllowed],
      [true, true, false, false],
    );
  });

  test('root, hooking and tampering are high risk', () {
    expect(IntegritySignal.rooted.risk, IntegrityRisk.high);
    expect(IntegritySignal.hookingFramework.risk, IntegrityRisk.high);
    expect(IntegritySignal.tampered.risk, IntegrityRisk.high);
    expect(IntegritySignal.emulator.risk, IntegrityRisk.medium);
    expect(IntegritySignal.developerOptions.risk, IntegrityRisk.low);
  });

  test('the worst signal sets the risk', () {
    expect(IntegrityRisk.highestOf(const []), IntegrityRisk.none);
    expect(
      IntegrityRisk.highestOf(const [
        IntegritySignal.developerOptions,
        IntegritySignal.rooted,
        IntegritySignal.emulator,
      ]),
      IntegrityRisk.high,
    );
  });

  group('IntegrityStatus', () {
    test('reports but never blocks when not enforced', () {
      const status = IntegrityStatus(
        detected: {IntegritySignal.rooted},
        enforced: false,
      );
      expect(status.risk, IntegrityRisk.high);
      expect(status.verdict, IntegrityVerdict.allow);
    });

    test('blocks payments until the first check finishes', () {
      const status = IntegrityStatus(
        detected: {},
        enforced: true,
        checked: false,
      );
      expect(status.verdict, IntegrityVerdict.blockPayments);
    });

    test('simulated signals count like detected ones', () {
      const status = IntegrityStatus(
        detected: {IntegritySignal.developerOptions},
        simulated: {IntegritySignal.debugger},
        enforced: true,
      );
      expect(status.signals, {
        IntegritySignal.developerOptions,
        IntegritySignal.debugger,
      });
      expect(status.verdict, IntegrityVerdict.blockPayments);
    });
  });

  test('a report lists only the checks its platform runs', () {
    final ios = DeviceIntegrityReport(
      platform: TargetPlatform.iOS,
      signals: const {},
      checkedAt: DateTime(2026),
    );
    expect(ios.applicableChecks, contains(IntegritySignal.tampered));
    expect(
      ios.applicableChecks,
      isNot(contains(IntegritySignal.developerOptions)),
    );
    final web = DeviceIntegrityReport.unsupported(
      platform: TargetPlatform.linux,
      checkedAt: DateTime(2026),
    );
    expect(web.applicableChecks, isEmpty);
  });
}
