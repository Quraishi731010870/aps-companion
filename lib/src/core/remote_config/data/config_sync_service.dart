import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/app_environment.dart';

part 'config_sync_service.g.dart';

/// Live socket to the backend's `/realtime` namespace. It only announces that
/// the admin portal published a change; `mobileConfigProvider` listens to
/// [changes] and reloads itself. (Invalidating that provider from here would
/// be a circular dependency, because it watches this one.)
@Riverpod(keepAlive: true)
ConfigSyncService configSyncService(Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final service = ConfigSyncService(
    baseUrl: environment.hasBackend ? environment.apiBaseUrl : '',
  );
  ref.onDispose(service.dispose);
  service.connect();
  return service;
}

class ConfigSyncService {
  ConfigSyncService({required this.baseUrl});
  final String baseUrl;
  final _changes = StreamController<void>.broadcast();
  io.Socket? _socket;

  /// Fires when configuration, feature flags or dynamic content change.
  Stream<void> get changes => _changes.stream;

  /// The backend emits each change under two event names; both land here.
  static const _events = [
    'ConfigurationUpdated',
    'CONFIGURATION_UPDATED',
    'FeatureFlagChanged',
    'FEATURE_FLAG_UPDATED',
    'DynamicContentUpdated',
    'DYNAMIC_CONTENT_UPDATED',
  ];

  void connect() {
    if (baseUrl.isEmpty) return;
    final socket = io.io(
      '$baseUrl/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    for (final event in _events) {
      socket.on(event, (_) => notifyChanged());
    }
    _socket = socket..connect();
  }

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _changes.close();
  }
}
