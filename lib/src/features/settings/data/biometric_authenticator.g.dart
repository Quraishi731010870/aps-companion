// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_authenticator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biometricAuthenticator)
final biometricAuthenticatorProvider = BiometricAuthenticatorProvider._();

final class BiometricAuthenticatorProvider
    extends
        $FunctionalProvider<
          BiometricAuthenticator,
          BiometricAuthenticator,
          BiometricAuthenticator
        >
    with $Provider<BiometricAuthenticator> {
  BiometricAuthenticatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAuthenticatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAuthenticatorHash();

  @$internal
  @override
  $ProviderElement<BiometricAuthenticator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BiometricAuthenticator create(Ref ref) {
    return biometricAuthenticator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricAuthenticator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricAuthenticator>(value),
    );
  }
}

String _$biometricAuthenticatorHash() =>
    r'4e8172d89a0c0b7c66558b0ed6dccfe59b808e09';
