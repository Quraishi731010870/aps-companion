import 'package:afghan_emi/src/core/remote_config/data/config_repository.dart';
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
}
