import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_environment.dart';
import '../domain/payment_transaction.dart';
import '../network/config_sync_service.dart';
import '../repositories/config_repository.dart';

part 'mobile_config.g.dart';

/// Remote mobile configuration (feature flags, maintenance mode, content).
/// Falls back to the cached copy offline, and to [MobileConfiguration.empty]
/// when no backend is configured.
@Riverpod(keepAlive: true)
class MobileConfig extends _$MobileConfig {
  @override
  Future<MobileConfiguration> build() {
    if (!ref.watch(appEnvironmentProvider).hasBackend) {
      return Future.value(MobileConfiguration.empty);
    }
    // Starts the live socket that invalidates this provider on changes.
    ref.watch(configSyncServiceProvider);
    return ref.watch(configRepositoryProvider).load();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Latest configuration, keeping the previous value while reloading.
@riverpod
MobileConfiguration currentConfig(Ref ref) =>
    ref.watch(mobileConfigProvider).value ?? MobileConfiguration.empty;

/// Operations the remote feature flags allow, in display order.
@riverpod
List<PaymentOperation> enabledOperations(Ref ref) {
  final config = ref.watch(currentConfigProvider);
  return [
    for (final operation in PaymentOperation.values)
      if (config.featureEnabled(operation.configurationKey, safeDefault: true))
        operation,
  ];
}
