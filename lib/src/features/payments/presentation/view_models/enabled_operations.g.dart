// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enabled_operations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Operations the remote feature flags allow, in display order.

@ProviderFor(enabledOperations)
final enabledOperationsProvider = EnabledOperationsProvider._();

/// Operations the remote feature flags allow, in display order.

final class EnabledOperationsProvider
    extends
        $FunctionalProvider<
          List<PaymentOperation>,
          List<PaymentOperation>,
          List<PaymentOperation>
        >
    with $Provider<List<PaymentOperation>> {
  /// Operations the remote feature flags allow, in display order.
  EnabledOperationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledOperationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledOperationsHash();

  @$internal
  @override
  $ProviderElement<List<PaymentOperation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PaymentOperation> create(Ref ref) {
    return enabledOperations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PaymentOperation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PaymentOperation>>(value),
    );
  }
}

String _$enabledOperationsHash() => r'63795906d30a420650109f5eed0ca7150e4e4e49';
