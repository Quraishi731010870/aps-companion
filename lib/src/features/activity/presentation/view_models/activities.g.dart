// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activities.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wallet history from the active gateway. Invalidated after each payment.

@ProviderFor(activities)
final activitiesProvider = ActivitiesProvider._();

/// Wallet history from the active gateway. Invalidated after each payment.

final class ActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WalletActivity>>,
          List<WalletActivity>,
          FutureOr<List<WalletActivity>>
        >
    with
        $FutureModifier<List<WalletActivity>>,
        $FutureProvider<List<WalletActivity>> {
  /// Wallet history from the active gateway. Invalidated after each payment.
  ActivitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<WalletActivity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WalletActivity>> create(Ref ref) {
    return activities(ref);
  }
}

String _$activitiesHash() => r'aec3b6144cd9f021b4c78a9f41f19ae3d0c0000c';
