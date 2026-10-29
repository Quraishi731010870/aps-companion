/// PayAfghan-specific receive QR payload. It carries only a wallet identifier,
/// never a name, phone number, amount, credential, or payment authorization.
abstract final class WalletQrPayload {
  static Uri forWallet(String walletNumber) => Uri(
    scheme: 'payafghan',
    host: 'pay',
    queryParameters: {'wallet': walletNumber},
  );

  static String? walletFrom(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'payafghan' || uri.host != 'pay') {
      return null;
    }
    final wallet = uri.queryParameters['wallet'];
    if (wallet == null ||
        !RegExp(r'^WALLET-[A-Z0-9]{4,20}$').hasMatch(wallet)) {
      return null;
    }
    return wallet;
  }
}
