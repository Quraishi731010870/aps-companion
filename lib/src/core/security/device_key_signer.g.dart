// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key_signer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(requestSigner)
final requestSignerProvider = RequestSignerProvider._();

final class RequestSignerProvider
    extends $FunctionalProvider<RequestSigner, RequestSigner, RequestSigner>
    with $Provider<RequestSigner> {
  RequestSignerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestSignerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestSignerHash();

  @$internal
  @override
  $ProviderElement<RequestSigner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestSigner create(Ref ref) {
    return requestSigner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestSigner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestSigner>(value),
    );
  }
}

String _$requestSignerHash() => r'6804274e19b4423e58bb586899b38ce3ee342749';
