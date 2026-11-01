import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_environment.dart';
import '../../data/device_integrity_checker.dart';
import '../../domain/device_integrity_report.dart';
import '../../domain/integrity_signal.dart';

part 'device_integrity.g.dart';

/// Latest device check. Runs at launch and again before every payment.
@Riverpod(keepAlive: true)
class DeviceIntegrity extends _$DeviceIntegrity {
  @override
  Future<DeviceIntegrityReport> build() =>
      ref.watch(deviceIntegrityCheckerProvider).check();

  /// Runs the checks again, keeping the previous report visible meanwhile.
  Future<DeviceIntegrityReport> recheck() {
    ref.invalidateSelf();
    return future;
  }
}

/// Developer-mode switches: enforce the policy in a debug build and simulate
/// detections. Release builds ignore them (see [integrityStatus]).
@Riverpod(keepAlive: true)
class IntegrityOverridesController extends _$IntegrityOverridesController {
  @override
  IntegrityOverrides build() => const IntegrityOverrides();

  void setEnforced(bool enforce) => state = state.copyWith(enforce: enforce);

  void setSimulated(IntegritySignal signal, bool simulated) =>
      state = state.copyWith(
        simulated: {
          for (final existing in state.simulated)
            if (existing != signal) existing,
          if (simulated) signal,
        },
      );

  void reset() => state = const IntegrityOverrides();
}

/// What the app enforces right now. Release builds always enforce and never
/// honour developer overrides.
@Riverpod(keepAlive: true)
IntegrityStatus integrityStatus(Ref ref) {
  final isRelease = ref.watch(appEnvironmentProvider).isRelease;
  final report = ref.watch(deviceIntegrityProvider).value;
  final overrides = isRelease
      ? const IntegrityOverrides()
      : ref.watch(integrityOverridesControllerProvider);
  return IntegrityStatus(
    detected: report?.signals ?? const {},
    simulated: overrides.simulated,
    enforced: isRelease || overrides.enforce,
    checked: report != null,
  );
}
