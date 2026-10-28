import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config/app_environment.dart';
import '../data/config_repository.dart';
import '../data/config_sync_service.dart';

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
