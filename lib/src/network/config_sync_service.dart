import 'package:socket_io_client/socket_io_client.dart' as io;

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
