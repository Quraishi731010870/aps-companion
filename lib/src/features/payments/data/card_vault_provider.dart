import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/card_vault.dart';
import 'backend_card_vault.dart';
import 'mock_card_vault.dart';

part 'card_vault_provider.g.dart';

/// Backend vault when `API_BASE_URL` is set, otherwise the offline mock.
@Riverpod(keepAlive: true)
CardVault cardVault(Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.hasBackend) return MockCardVault();
  return BackendCardVault(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
    environment,
  );
}
