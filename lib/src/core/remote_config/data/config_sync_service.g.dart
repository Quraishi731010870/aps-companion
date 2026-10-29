// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live socket to the backend's `/realtime` namespace. It only announces that
/// the admin portal published a change; `mobileConfigProvider` listens to
/// [changes] and reloads itself. (Invalidating that provider from here would
/// be a circular dependency, because it watches this one.)

@ProviderFor(configSyncService)
final configSyncServiceProvider = ConfigSyncServiceProvider._();

/// Live socket to the backend's `/realtime` namespace. It only announces that
/// the admin portal published a change; `mobileConfigProvider` listens to
/// [changes] and reloads itself. (Invalidating that provider from here would
/// be a circular dependency, because it watches this one.)

final class ConfigSyncServiceProvider
    extends
        $FunctionalProvider<
          ConfigSyncService,
          ConfigSyncService,
          ConfigSyncService
        >
    with $Provider<ConfigSyncService> {
  /// Live socket to the backend's `/realtime` namespace. It only announces that
  /// the admin portal published a change; `mobileConfigProvider` listens to
  /// [changes] and reloads itself. (Invalidating that provider from here would
  /// be a circular dependency, because it watches this one.)
  ConfigSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configSyncServiceHash();

  @$internal
  @override
  $ProviderElement<ConfigSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConfigSyncService create(Ref ref) {
    return configSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigSyncService>(value),
    );
  }
}

String _$configSyncServiceHash() => r'f20dc6ba510e8ca0d2d075d41ad1fbc95c3712f6';
