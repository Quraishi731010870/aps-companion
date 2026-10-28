import '../domain/card_details.dart';
import '../domain/card_vault.dart';
import '../domain/saved_card.dart';

/// Offline vault for mock mode: nothing leaves the device, nothing is
/// persisted, and only the masked number is kept in memory.
class MockCardVault implements CardVault {
  SavedCard? _linked;

  @override
  Future<SavedCard?> linkedCard() async => _linked;

  @override
  Future<SavedCard> saveCard(CardDetails card) async => _linked = SavedCard(
    token: 'mock_${card.maskedPan.substring(card.maskedPan.length - 4)}',
    maskedPan: card.maskedPan,
    expiryMonth: card.expiryMonth,
    expiryYear: card.expiryYear,
    holderName: card.holderName,
  );

  /// The mock gateway never reads card data, so no real encryption is needed.
  @override
  Future<CardEnvelope> encryptForPayment(CardDetails card) async =>
      const CardEnvelope(kid: 'mock', ek: 'mock', iv: 'mock', ct: 'mock');
}
