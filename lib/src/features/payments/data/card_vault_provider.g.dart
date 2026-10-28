// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_vault_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backend vault when `API_BASE_URL` is set, otherwise the offline mock.

@ProviderFor(cardVault)
final cardVaultProvider = CardVaultProvider._();

/// Backend vault when `API_BASE_URL` is set, otherwise the offline mock.

final class CardVaultProvider
    extends $FunctionalProvider<CardVault, CardVault, CardVault>
    with $Provider<CardVault> {
  /// Backend vault when `API_BASE_URL` is set, otherwise the offline mock.
  CardVaultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardVaultProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardVaultHash();

  @$internal
  @override
  $ProviderElement<CardVault> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CardVault create(Ref ref) {
    return cardVault(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardVault value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardVault>(value),
    );
  }
}

String _$cardVaultHash() => r'e1c23563d8ffbcd2538663be47e34ac8cf95e488';
