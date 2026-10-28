import 'package:flutter/foundation.dart';

import 'card_number.dart';

/// A card the user typed in. Lives only in memory until it is encrypted for
/// the backend; it is never stored or logged in clear.
@immutable
class CardDetails {
  const CardDetails({
    required this.pan,
    this.expiryMonth,
    this.expiryYear,
    this.holderName,
  });

  final String pan;
  final int? expiryMonth;
  final int? expiryYear;
  final String? holderName;

  String get maskedPan => CardNumber.masked(pan);

  /// Parses `MM/YY` into month and four-digit year; null when malformed.
  static (int, int)? parseExpiry(String value) {
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    return (int.parse(match.group(1)!), 2000 + int.parse(match.group(2)!));
  }

  /// Plaintext that goes inside the encrypted envelope. [sentAt] lets the
  /// backend reject replays of a captured envelope.
  Map<String, Object> toPayload(DateTime sentAt) => {
    'pan': pan,
    'expMonth': ?expiryMonth,
    'expYear': ?expiryYear,
    if (holderName case final name? when name.trim().isNotEmpty)
      'holder': name.trim(),
    'ts': sentAt.millisecondsSinceEpoch,
  };

  /// Never prints the full number.
  @override
  String toString() => 'CardDetails($maskedPan)';

  @override
  bool operator ==(Object other) =>
      other is CardDetails &&
      other.pan == pan &&
      other.expiryMonth == expiryMonth &&
      other.expiryYear == expiryYear &&
      other.holderName == holderName;

  @override
  int get hashCode => Object.hash(pan, expiryMonth, expiryYear, holderName);
}
