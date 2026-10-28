// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linked_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prototype linked card shared by Home and the payment flow. Holds only the
/// masked label; production must replace this with a vault token (APS p.31).

@ProviderFor(LinkedCard)
final linkedCardProvider = LinkedCardProvider._();

/// Prototype linked card shared by Home and the payment flow. Holds only the
/// masked label; production must replace this with a vault token (APS p.31).
final class LinkedCardProvider extends $NotifierProvider<LinkedCard, String?> {
  /// Prototype linked card shared by Home and the payment flow. Holds only the
  /// masked label; production must replace this with a vault token (APS p.31).
  LinkedCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkedCardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkedCardHash();

  @$internal
  @override
  LinkedCard create() => LinkedCard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$linkedCardHash() => r'4f424eea49d718aca77b15f45df2f278abede421';

/// Prototype linked card shared by Home and the payment flow. Holds only the
/// masked label; production must replace this with a vault token (APS p.31).

abstract class _$LinkedCard extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
