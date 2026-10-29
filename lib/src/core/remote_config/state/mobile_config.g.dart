// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Remote mobile configuration (feature flags, maintenance mode, content).
/// Falls back to the cached copy offline, and to [MobileConfiguration.empty]
/// when no backend is configured.

@ProviderFor(MobileConfig)
final mobileConfigProvider = MobileConfigProvider._();

/// Remote mobile configuration (feature flags, maintenance mode, content).
/// Falls back to the cached copy offline, and to [MobileConfiguration.empty]
/// when no backend is configured.
final class MobileConfigProvider
    extends $AsyncNotifierProvider<MobileConfig, MobileConfiguration> {
  /// Remote mobile configuration (feature flags, maintenance mode, content).
  /// Falls back to the cached copy offline, and to [MobileConfiguration.empty]
  /// when no backend is configured.
  MobileConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mobileConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mobileConfigHash();

  @$internal
  @override
  MobileConfig create() => MobileConfig();
}

String _$mobileConfigHash() => r'72343525502cd5e4bb1f5ca2519f3dcd1f5fea99';

/// Remote mobile configuration (feature flags, maintenance mode, content).
/// Falls back to the cached copy offline, and to [MobileConfiguration.empty]
/// when no backend is configured.

abstract class _$MobileConfig extends $AsyncNotifier<MobileConfiguration> {
  FutureOr<MobileConfiguration> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MobileConfiguration>, MobileConfiguration>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MobileConfiguration>, MobileConfiguration>,
              AsyncValue<MobileConfiguration>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Latest configuration, keeping the previous value while reloading.

@ProviderFor(currentConfig)
final currentConfigProvider = CurrentConfigProvider._();

/// Latest configuration, keeping the previous value while reloading.

final class CurrentConfigProvider
    extends
        $FunctionalProvider<
          MobileConfiguration,
          MobileConfiguration,
          MobileConfiguration
        >
    with $Provider<MobileConfiguration> {
  /// Latest configuration, keeping the previous value while reloading.
  CurrentConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentConfigHash();

  @$internal
  @override
  $ProviderElement<MobileConfiguration> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MobileConfiguration create(Ref ref) {
    return currentConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MobileConfiguration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MobileConfiguration>(value),
    );
  }
}

String _$currentConfigHash() => r'cb963fb4801a625767014ec1abc16e37185dde0d';
