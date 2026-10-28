// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user from secure storage; reloads after each sign-in.
/// Null in offline mock mode or when signed out.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// The signed-in user from secure storage; reloads after each sign-in.
/// Null in offline mock mode or when signed out.

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          FutureOr<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $FutureProvider<UserProfile?> {
  /// The signed-in user from secure storage; reloads after each sign-in.
  /// Null in offline mock mode or when signed out.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'058b6ed624c96430738fb993294aed127833640a';

/// The user to show in the UI: the signed-in user, otherwise the demo user.

@ProviderFor(displayedUser)
final displayedUserProvider = DisplayedUserProvider._();

/// The user to show in the UI: the signed-in user, otherwise the demo user.

final class DisplayedUserProvider
    extends $FunctionalProvider<UserProfile, UserProfile, UserProfile>
    with $Provider<UserProfile> {
  /// The user to show in the UI: the signed-in user, otherwise the demo user.
  DisplayedUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displayedUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displayedUserHash();

  @$internal
  @override
  $ProviderElement<UserProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserProfile create(Ref ref) {
    return displayedUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfile>(value),
    );
  }
}

String _$displayedUserHash() => r'089f805c2bd6bc5292473952a137131c169c9c6f';
