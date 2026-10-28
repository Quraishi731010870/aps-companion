// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live socket that reloads [mobileConfigProvider] when the admin portal
/// publishes a change. The socket is closed when the provider is disposed.

@ProviderFor(configSyncService)
final configSyncServiceProvider = ConfigSyncServiceProvider._();

/// Live socket that reloads [mobileConfigProvider] when the admin portal
/// publishes a change. The socket is closed when the provider is disposed.

final class ConfigSyncServiceProvider
    extends
        $FunctionalProvider<
          ConfigSyncService,
          ConfigSyncService,
          ConfigSyncService
        >
    with $Provider<ConfigSyncService> {
  /// Live socket that reloads [mobileConfigProvider] when the admin portal
  /// publishes a change. The socket is closed when the provider is disposed.
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

String _$configSyncServiceHash() => r'b175fd0248b6d2906f0c98696d4a60bbabbfdd58';
