/// Identifier shown by the current local/demo wallet UI.
/// A production wallet ID must come from the authenticated wallet backend.
abstract final class WalletIdentity {
  static const number = 'WALLET-7814';

  static String get masked => '•••• ${number.substring(number.length - 4)}';
}

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
