import 'package:afghan_emi/src/domain/wallet_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet receive QR round-trips only the wallet identifier', () {
    final payload = WalletQrPayload.forWallet(WalletIdentity.number).toString();

    expect(WalletQrPayload.walletFrom(payload), WalletIdentity.number);
    expect(payload, isNot(contains('Asif')));
    expect(payload, isNot(contains('+93')));
  });

  test('rejects malformed PayAfghan wallet QR payloads', () {
    expect(
      WalletQrPayload.walletFrom('payafghan://pay?wallet=not-a-wallet'),
      isNull,
    );
    expect(WalletQrPayload.walletFrom('https://example.invalid/pay'), isNull);
  });
}
