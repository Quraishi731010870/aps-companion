import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/app_environment.dart';
import '../state/mobile_config.dart';

part 'config_sync_service.g.dart';

/// Live socket that reloads [mobileConfigProvider] when the admin portal
/// publishes a change. The socket is closed when the provider is disposed.
@Riverpod(keepAlive: true)
ConfigSyncService configSyncService(Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final service = ConfigSyncService(
    baseUrl: environment.hasBackend ? environment.apiBaseUrl : '',
    onConfigurationChanged: () async => ref.invalidate(mobileConfigProvider),
  );
  ref.onDispose(service.dispose);
  service.connect();
  return service;
}

class ConfigSyncService {
  ConfigSyncService({
    required this.baseUrl,
    required this.onConfigurationChanged,
  });
  final String baseUrl;
  final Future<void> Function() onConfigurationChanged;
  io.Socket? _socket;
  void connect() {
    if (baseUrl.isEmpty) return;
    _socket =
        io.io(
            '$baseUrl/realtime',
            io.OptionBuilder()
                .setTransports(['websocket'])
                .disableAutoConnect()
                .enableReconnection()
                .build(),
          )
          ..on('ConfigurationUpdated', (_) => onConfigurationChanged())
          ..on('FeatureFlagChanged', (_) => onConfigurationChanged())
          ..on('CONFIGURATION_UPDATED', (_) => onConfigurationChanged())
          ..on('FEATURE_FLAG_UPDATED', (_) => onConfigurationChanged())
          ..on('DYNAMIC_CONTENT_UPDATED', (_) => onConfigurationChanged())
          ..on('DynamicContentUpdated', (_) => onConfigurationChanged())
          ..connect();
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
