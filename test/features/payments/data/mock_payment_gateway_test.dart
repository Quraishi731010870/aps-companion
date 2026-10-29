import 'package:afghan_emi/src/features/payments/data/mock_payment_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline mode starts with no history and an empty wallet', () async {
    final gateway = MockPaymentGateway();

    expect(await gateway.fetchActivities(), isEmpty);
    final wallet = await gateway.fetchWallet();
    expect(wallet.availableBalance, 0);
    expect(wallet.currency, 'AFN');
  });
}
