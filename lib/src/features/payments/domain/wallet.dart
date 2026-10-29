import 'package:flutter/foundation.dart';

/// The signed-in customer's wallet as returned by `GET /api/v1/wallet`.
@immutable
class Wallet {
  const Wallet({
    required this.id,
    required this.currency,
    required this.availableBalance,
  });

  /// Wallet identifier, e.g. `WALLET-AF000001`.
  final String id;
  final String currency;
  final double availableBalance;

  /// Last four characters only, e.g. `•••• 0001`.
  String get masked =>
      '•••• ${id.length > 4 ? id.substring(id.length - 4) : id}';

  /// Null unless [json] has a wallet id, currency and numeric balance.
  static Wallet? fromJson(Object? json) => switch (json) {
    {
      'walletId': final String id,
      'currency': final String currency,
      'availableBalance': final num balance,
    }
        when id.isNotEmpty =>
      Wallet(id: id, currency: currency, availableBalance: balance.toDouble()),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is Wallet &&
      other.id == id &&
      other.currency == currency &&
      other.availableBalance == availableBalance;

  @override
  int get hashCode => Object.hash(id, currency, availableBalance);
}
