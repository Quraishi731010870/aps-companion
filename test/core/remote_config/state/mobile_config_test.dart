import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/remote_config/data/config_repository.dart';
import 'package:afghan_emi/src/core/remote_config/data/config_sync_service.dart';
import 'package:afghan_emi/src/core/remote_config/state/mobile_config.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/enabled_operations.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MobileConfiguration _config(Map<String, bool> features) => MobileConfiguration(
  version: 1,
  updatedAt: null,
  values: const {},
  features: features,
  content: const [],
  fromCache: false,
);

class _CountingRepository implements ConfigRepository {
  int loads = 0;

  @override
  Future<MobileConfiguration> load() async {
    loads++;
    return _config({'cash_out': loads.isOdd});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('operations are hidden only when their flag is off', () {
    final container = ProviderContainer.test(
      overrides: [
        currentConfigProvider.overrideWithValue(
          _config({'cash_out': false, 'purchase': true}),
        ),
      ],
    );

    final operations = container.read(enabledOperationsProvider);

    expect(operations, isNot(contains(PaymentOperation.cashOut)));
    expect(operations, contains(PaymentOperation.purchase));
    // No flag means the safe default: shown.
    expect(operations, contains(PaymentOperation.cashIn));
  });

  test('without a backend the empty configuration is used', () async {
    final container = ProviderContainer.test();

    final config = await container.read(mobileConfigProvider.future);

    expect(config, same(MobileConfiguration.empty));
    expect(config.maintenanceMode, isFalse);
  });

  test(
    'a live change from the admin portal reloads the configuration',
    () async {
      final repository = _CountingRepository();
      final sync = ConfigSyncService(baseUrl: '');
      addTearDown(sync.dispose);
      final container = ProviderContainer.test(
        overrides: [
          appEnvironmentProvider.overrideWithValue(
            const AppEnvironment(apiBaseUrl: 'http://localhost:8081'),
          ),
          configRepositoryProvider.overrideWithValue(repository),
          configSyncServiceProvider.overrideWithValue(sync),
        ],
      );
      container.listen(currentConfigProvider, (_, _) {});
      await container.read(mobileConfigProvider.future);
      expect(
        container.read(currentConfigProvider).featureEnabled('cash_out'),
        isTrue,
      );

      // The backend sends each change twice; it must not throw and loads once.
      sync
        ..notifyChanged()
        ..notifyChanged();
      await pumpEventQueue();
      await container.read(mobileConfigProvider.future);

      expect(repository.loads, 2);
      expect(
        container.read(currentConfigProvider).featureEnabled('cash_out'),
        isFalse,
      );
    },
  );
}
