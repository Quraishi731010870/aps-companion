// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Until the sign-in screen exists, debug builds sign in as the seeded test
/// user from `TEST_USER_PHONE` / `TEST_USER_PASSWORD` on every launch, which
/// also replaces any expired tokens.
///
/// Never retried automatically: repeated failed sign-ins would lock the
/// account (5 attempts on the backend). Retry is the user's choice.

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Until the sign-in screen exists, debug builds sign in as the seeded test
/// user from `TEST_USER_PHONE` / `TEST_USER_PASSWORD` on every launch, which
/// also replaces any expired tokens.
///
/// Never retried automatically: repeated failed sign-ins would lock the
/// account (5 attempts on the backend). Retry is the user's choice.
final class SessionProvider
    extends $AsyncNotifierProvider<Session, SessionStatus> {
  /// ViewModel deciding whether the app can reach authenticated endpoints.
  ///
  /// Until the sign-in screen exists, debug builds sign in as the seeded test
  /// user from `TEST_USER_PHONE` / `TEST_USER_PASSWORD` on every launch, which
  /// also replaces any expired tokens.
  ///
  /// Never retried automatically: repeated failed sign-ins would lock the
  /// account (5 attempts on the backend). Retry is the user's choice.
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  Session create() => Session();
}

String _$sessionHash() => r'855b3073b5744a0dc6b075c726cf981775f7a178';

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Until the sign-in screen exists, debug builds sign in as the seeded test
/// user from `TEST_USER_PHONE` / `TEST_USER_PASSWORD` on every launch, which
/// also replaces any expired tokens.
///
/// Never retried automatically: repeated failed sign-ins would lock the
/// account (5 attempts on the backend). Retry is the user's choice.

abstract class _$Session extends $AsyncNotifier<SessionStatus> {
  FutureOr<SessionStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SessionStatus>, SessionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionStatus>, SessionStatus>,
              AsyncValue<SessionStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
