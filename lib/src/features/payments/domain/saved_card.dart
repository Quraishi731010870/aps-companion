import 'package:flutter/foundation.dart';

import 'card_number.dart';

/// A vaulted card as the app knows it: a backend token and the masked number.
/// The full number never comes back from the vault (APS p.31), and the expiry
/// and CVV are never kept.
@immutable
class SavedCard {
  const SavedCard({
    required this.token,
    required this.maskedPan,
    this.holderName,
  });

  final String token;
  final String maskedPan;
  final String? holderName;

  /// e.g. `APS card 6037 99** **** 1234`.
  String get label => 'APS card ${CardNumber.display(maskedPan)}';

  Map<String, Object?> toJson() => {
    'token': token,
    'maskedPan': maskedPan,
    'holderName': holderName,
  };

  /// Returns null unless [json] has a token and a properly masked number.
  static SavedCard? fromJson(Object? json) => switch (json) {
    {'token': final String token, 'maskedPan': final String masked}
        when token.isNotEmpty && masked.contains('*') =>
      SavedCard(
        token: token,
        maskedPan: masked,
        holderName: json['holderName'] as String?,
      ),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is SavedCard &&
      other.token == token &&
      other.maskedPan == maskedPan;

  @override
  int get hashCode => Object.hash(token, maskedPan);
}
