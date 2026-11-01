// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_integrity_checker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceIntegrityChecker)
final deviceIntegrityCheckerProvider = DeviceIntegrityCheckerProvider._();

final class DeviceIntegrityCheckerProvider
    extends
        $FunctionalProvider<
          DeviceIntegrityChecker,
          DeviceIntegrityChecker,
          DeviceIntegrityChecker
        >
    with $Provider<DeviceIntegrityChecker> {
  DeviceIntegrityCheckerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIntegrityCheckerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIntegrityCheckerHash();

  @$internal
  @override
  $ProviderElement<DeviceIntegrityChecker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceIntegrityChecker create(Ref ref) {
    return deviceIntegrityChecker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceIntegrityChecker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceIntegrityChecker>(value),
    );
  }
}

String _$deviceIntegrityCheckerHash() =>
    r'94e85e6cd0bc934d8aea18ff6e9424912538311e';
