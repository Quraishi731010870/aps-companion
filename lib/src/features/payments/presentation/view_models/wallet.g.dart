// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The customer's wallet (id and balance). Invalidated after each payment.

@ProviderFor(wallet)
final walletProvider = WalletProvider._();

/// The customer's wallet (id and balance). Invalidated after each payment.

final class WalletProvider
    extends $FunctionalProvider<AsyncValue<Wallet>, Wallet, FutureOr<Wallet>>
    with $FutureModifier<Wallet>, $FutureProvider<Wallet> {
  /// The customer's wallet (id and balance). Invalidated after each payment.
  WalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletHash();

  @$internal
  @override
  $FutureProviderElement<Wallet> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Wallet> create(Ref ref) {
    return wallet(ref);
  }
}

String _$walletHash() => r'37a26d0ad2eb03ce296719fb007a381b2a97ec6b';
