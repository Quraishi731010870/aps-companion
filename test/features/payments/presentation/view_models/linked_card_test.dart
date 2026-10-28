import 'package:afghan_emi/src/features/payments/data/card_vault_provider.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/saved_card.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/linked_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  late FakeCardVault vault;
  late ProviderContainer container;

  setUp(() {
    vault = FakeCardVault();
    container = ProviderContainer.test(
      overrides: [cardVaultProvider.overrideWithValue(vault)],
    );
  });

  test('starts with the card already linked on this device', () async {
    vault.linked = const SavedCard(token: 't', maskedPan: '603799******1234');

    expect((await container.read(linkedCardProvider.future))?.token, 't');
  });

  test(
    'linking vaults the card and keeps only token and masked number',
    () async {
      final saved = await container
          .read(linkedCardProvider.notifier)
          .link(const CardDetails(pan: '6037991234561234'));

      expect(saved.maskedPan, '603799******1234');
      expect(container.read(linkedCardProvider).value, saved);
    },
  );

  test('a vault failure is reported and nothing is linked', () async {
    vault.error = Exception('offline');
    await container.read(linkedCardProvider.future);

    await expectLater(
      container
          .read(linkedCardProvider.notifier)
          .link(const CardDetails(pan: '6037991234561234')),
      throwsException,
    );
    expect(container.read(linkedCardProvider).value, isNull);
  });
}
