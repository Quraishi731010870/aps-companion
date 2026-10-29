import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/auth_repository.dart';
import '../../domain/session_status.dart';

part 'session.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Signed in when tokens are stored (or offline on the mock gateway);
/// otherwise the sign-in screen is shown. Returns to signed out when the
/// server rejects the refresh token.
///
/// Sign-in is never retried automatically: repeated failures would lock the
/// account (5 attempts on the backend).
@Riverpod(keepAlive: true, retry: _noRetry)
class Session extends _$Session {
  @override
  Future<SessionStatus> build() async {
    if (!ref.watch(appEnvironmentProvider).hasBackend) {
      return SessionStatus.signedIn;
    }
    final ended = ref.watch(apiClientProvider).sessionEnded.listen((_) {
      state = const AsyncData(SessionStatus.signedOut);
    });
    ref.onDispose(ended.cancel);
    return await ref.watch(authRepositoryProvider).hasSession()
        ? SessionStatus.signedIn
        : SessionStatus.signedOut;
  }

  /// Throws `AuthFailure` on failure; the state is unchanged then.
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .signIn(identifier: identifier, password: password);
    if (!ref.mounted) return;
    state = const AsyncData(SessionStatus.signedIn);
  }

  /// Creates a customer and signs in. Throws `AuthFailure` on failure.
  Future<void> register({
    required String displayName,
    required String phone,
    required String password,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .register(displayName: displayName, phone: phone, password: password);
    if (!ref.mounted) return;
    state = const AsyncData(SessionStatus.signedIn);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) return;
    state = const AsyncData(SessionStatus.signedOut);
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    await future.catchError((_) => SessionStatus.signedOut);
  }
}
