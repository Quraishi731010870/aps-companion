import 'package:afghan_emi/src/domain/payment_transaction.dart';
import 'package:afghan_emi/src/repositories/config_repository.dart';
import 'package:afghan_emi/src/state/linked_card.dart';
import 'package:afghan_emi/src/state/mobile_config.dart';
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

  test('linking a card stores only the masked label', () {
    final container = ProviderContainer.test();

    final label = container
        .read(linkedCardProvider.notifier)
        .link('6037991234561234');

    expect(label, 'APS card  •••• 1234');
    expect(container.read(linkedCardProvider), isNot(contains('603799')));
  });
}
