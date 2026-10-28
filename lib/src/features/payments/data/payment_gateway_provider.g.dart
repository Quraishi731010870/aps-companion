// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_gateway_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single place that chooses the gateway: backend if `API_BASE_URL` is set,
/// otherwise Google Sheets, otherwise the offline mock.

@ProviderFor(paymentGateway)
final paymentGatewayProvider = PaymentGatewayProvider._();

/// Single place that chooses the gateway: backend if `API_BASE_URL` is set,
/// otherwise Google Sheets, otherwise the offline mock.

final class PaymentGatewayProvider
    extends $FunctionalProvider<PaymentGateway, PaymentGateway, PaymentGateway>
    with $Provider<PaymentGateway> {
  /// Single place that chooses the gateway: backend if `API_BASE_URL` is set,
  /// otherwise Google Sheets, otherwise the offline mock.
  PaymentGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentGatewayHash();

  @$internal
  @override
  $ProviderElement<PaymentGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaymentGateway create(Ref ref) {
    return paymentGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentGateway>(value),
    );
  }
}

String _$paymentGatewayHash() => r'fa2ce845fd8541d3089e0a8d5e54de8e018fcb33';
