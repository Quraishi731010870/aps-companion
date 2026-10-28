import 'dart:convert';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/card_details.dart';
import '../domain/card_vault.dart';
import '../domain/saved_card.dart';
import 'card_encryptor.dart';

/// Thrown when the backend's card key is not the pinned one.
class CardKeyMismatch implements Exception {
  const CardKeyMismatch();
  @override
  String toString() => 'The card encryption key could not be verified.';
}

/// Card vault backed by `/api/v1/cards`. Card numbers leave the device only
/// inside a [CardEnvelope]; the device keeps only the token and masked number.
class BackendCardVault implements CardVault {
  BackendCardVault(
    this._api,
    this._store,
    this._environment, {
    CardEncryptor? encryptor,
  }) : _encryptor = encryptor ?? CardEncryptor();

  final ApiClient _api;
  final SecureStore _store;
  final AppEnvironment _environment;
  final CardEncryptor _encryptor;
  Future<CardEncryptionKey>? _key;

  @override
  Future<SavedCard?> linkedCard() async {
    final raw = await _store.read(SecureKey.linkedCard);
    if (raw == null) return null;
    try {
      return SavedCard.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<SavedCard> saveCard(CardDetails card) async {
    final envelope = await encryptForPayment(card);
    final json = await _api.postJson('/api/v1/cards', {
      'encryptedCard': envelope.toJson(),
    });
    final saved = SavedCard.fromJson(json);
    if (saved == null) {
      throw const FormatException('Vault response is invalid.');
    }
    await _store.write(SecureKey.linkedCard, jsonEncode(saved.toJson()));
    return saved;
  }

  @override
  Future<CardEnvelope> encryptForPayment(CardDetails card) async =>
      _encryptor.seal(card, await _verifiedKey());

  /// Fetched once per app run and checked against the pinned thumbprint.
  /// A failed fetch is not cached, so the next attempt tries again.
  Future<CardEncryptionKey> _verifiedKey() =>
      _key ??= _fetchKey().catchError((Object error, StackTrace stackTrace) {
        _key = null;
        Error.throwWithStackTrace(error, stackTrace);
      });

  Future<CardEncryptionKey> _fetchKey() async {
    final key = CardEncryptionKey.fromJwk(
      await _api.getJson('/api/v1/cards/encryption-key'),
    );
    final pinned = _environment.cardKeySha256;
    if (pinned.isEmpty ? _environment.isRelease : key.kid != pinned) {
      throw const CardKeyMismatch();
    }
    return key;
  }
}
