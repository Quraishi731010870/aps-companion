// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linked_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The card linked on this device, shared by Home and the payment flow.
/// Holds only the vault token and masked number (APS p.31).

@ProviderFor(LinkedCard)
final linkedCardProvider = LinkedCardProvider._();

/// The card linked on this device, shared by Home and the payment flow.
/// Holds only the vault token and masked number (APS p.31).
final class LinkedCardProvider
    extends $AsyncNotifierProvider<LinkedCard, SavedCard?> {
  /// The card linked on this device, shared by Home and the payment flow.
  /// Holds only the vault token and masked number (APS p.31).
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
}

String _$linkedCardHash() => r'3bb2288e213872190db7ad47d987741999c2097f';

/// The card linked on this device, shared by Home and the payment flow.
/// Holds only the vault token and masked number (APS p.31).

abstract class _$LinkedCard extends $AsyncNotifier<SavedCard?> {
  FutureOr<SavedCard?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SavedCard?>, SavedCard?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SavedCard?>, SavedCard?>,
              AsyncValue<SavedCard?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
