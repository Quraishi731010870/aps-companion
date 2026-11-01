// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_integrity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Latest device check. Runs at launch and again before every payment.

@ProviderFor(DeviceIntegrity)
final deviceIntegrityProvider = DeviceIntegrityProvider._();

/// Latest device check. Runs at launch and again before every payment.
final class DeviceIntegrityProvider
    extends $AsyncNotifierProvider<DeviceIntegrity, DeviceIntegrityReport> {
  /// Latest device check. Runs at launch and again before every payment.
  DeviceIntegrityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIntegrityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIntegrityHash();

  @$internal
  @override
  DeviceIntegrity create() => DeviceIntegrity();
}

String _$deviceIntegrityHash() => r'51a8f519679b269ac2b51175ca3c27ff841f095d';

/// Latest device check. Runs at launch and again before every payment.

abstract class _$DeviceIntegrity extends $AsyncNotifier<DeviceIntegrityReport> {
  FutureOr<DeviceIntegrityReport> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<DeviceIntegrityReport>, DeviceIntegrityReport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DeviceIntegrityReport>,
                DeviceIntegrityReport
              >,
              AsyncValue<DeviceIntegrityReport>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Developer-mode switches: enforce the policy in a debug build and simulate
/// detections. Release builds ignore them (see [integrityStatus]).

@ProviderFor(IntegrityOverridesController)
final integrityOverridesControllerProvider =
    IntegrityOverridesControllerProvider._();

/// Developer-mode switches: enforce the policy in a debug build and simulate
/// detections. Release builds ignore them (see [integrityStatus]).
final class IntegrityOverridesControllerProvider
    extends
        $NotifierProvider<IntegrityOverridesController, IntegrityOverrides> {
  /// Developer-mode switches: enforce the policy in a debug build and simulate
  /// detections. Release builds ignore them (see [integrityStatus]).
  IntegrityOverridesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'integrityOverridesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$integrityOverridesControllerHash();

  @$internal
  @override
  IntegrityOverridesController create() => IntegrityOverridesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntegrityOverrides value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntegrityOverrides>(value),
    );
  }
}

String _$integrityOverridesControllerHash() =>
    r'b837291f8232fbbfd3527842c5b03b775aab9eb6';

/// Developer-mode switches: enforce the policy in a debug build and simulate
/// detections. Release builds ignore them (see [integrityStatus]).

abstract class _$IntegrityOverridesController
    extends $Notifier<IntegrityOverrides> {
  IntegrityOverrides build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IntegrityOverrides, IntegrityOverrides>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IntegrityOverrides, IntegrityOverrides>,
              IntegrityOverrides,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// What the app enforces right now. Release builds always enforce and never
/// honour developer overrides.

@ProviderFor(integrityStatus)
final integrityStatusProvider = IntegrityStatusProvider._();

/// What the app enforces right now. Release builds always enforce and never
/// honour developer overrides.

final class IntegrityStatusProvider
    extends
        $FunctionalProvider<IntegrityStatus, IntegrityStatus, IntegrityStatus>
    with $Provider<IntegrityStatus> {
  /// What the app enforces right now. Release builds always enforce and never
  /// honour developer overrides.
  IntegrityStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'integrityStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$integrityStatusHash();

  @$internal
  @override
  $ProviderElement<IntegrityStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IntegrityStatus create(Ref ref) {
    return integrityStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntegrityStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntegrityStatus>(value),
    );
  }
}

String _$integrityStatusHash() => r'07d221bbea6f44806d758d7791383788f2cbb660';
