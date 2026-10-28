import 'package:flutter/foundation.dart';

import 'card_details.dart';
import 'saved_card.dart';

/// Hybrid-encrypted card data (RSA-OAEP-256 wrapped AES-256-GCM), the only
/// form in which a card number leaves the device. Fields are base64url.
/// Format shared with `backend/src/cards/card-envelope.ts`.
@immutable
class CardEnvelope {
  const CardEnvelope({
    required this.kid,
    required this.ek,
    required this.iv,
    required this.ct,
  });

  static const version = 1;

  /// Id (RFC 7638 thumbprint) of the backend key used.
  final String kid;

  /// AES-256 content key, encrypted with the backend's RSA public key.
  final String ek;

  /// 96-bit AES-GCM nonce.
  final String iv;

  /// Card JSON encrypted with AES-256-GCM, followed by the 128-bit tag.
  final String ct;

  Map<String, Object> toJson() => {
    'v': version,
    'kid': kid,
    'ek': ek,
    'iv': iv,
    'ct': ct,
  };
}

/// Where cards go: vaulting a card to save it, and encrypting a one-off card
/// for a payment. Implementations never persist a full card number.
abstract interface class CardVault {
  /// The card linked on this device, if any (token and masked number only).
  Future<SavedCard?> linkedCard();

  /// Encrypts [card], stores it in the backend vault and links the returned
  /// token on this device.
  Future<SavedCard> saveCard(CardDetails card);

  /// Encrypts [card] for a single payment request.
  Future<CardEnvelope> encryptForPayment(CardDetails card);
}
