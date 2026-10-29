// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Signed in when tokens are stored (or offline on the mock gateway);
/// otherwise the sign-in screen is shown. Returns to signed out when the
/// server rejects the refresh token.
///
/// Sign-in is never retried automatically: repeated failures would lock the
/// account (5 attempts on the backend).

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Signed in when tokens are stored (or offline on the mock gateway);
/// otherwise the sign-in screen is shown. Returns to signed out when the
/// server rejects the refresh token.
///
/// Sign-in is never retried automatically: repeated failures would lock the
/// account (5 attempts on the backend).
final class SessionProvider
    extends $AsyncNotifierProvider<Session, SessionStatus> {
  /// ViewModel deciding whether the app can reach authenticated endpoints.
  ///
  /// Signed in when tokens are stored (or offline on the mock gateway);
  /// otherwise the sign-in screen is shown. Returns to signed out when the
  /// server rejects the refresh token.
  ///
  /// Sign-in is never retried automatically: repeated failures would lock the
  /// account (5 attempts on the backend).
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

String _$sessionHash() => r'c1e53be7666188eff14dff88b44e596d307c3b67';

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Signed in when tokens are stored (or offline on the mock gateway);
/// otherwise the sign-in screen is shown. Returns to signed out when the
/// server rejects the refresh token.
///
/// Sign-in is never retried automatically: repeated failures would lock the
/// account (5 attempts on the backend).

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
