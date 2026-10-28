import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_environment.dart';
import '../../data/auth_repository.dart';
import '../../domain/session_status.dart';

part 'session.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// ViewModel deciding whether the app can reach authenticated endpoints.
///
/// Until the sign-in screen exists, debug builds sign in as the seeded test
/// user from `TEST_USER_PHONE` / `TEST_USER_PASSWORD` on every launch, which
/// also replaces any expired tokens.
///
/// Never retried automatically: repeated failed sign-ins would lock the
/// account (5 attempts on the backend). Retry is the user's choice.
@Riverpod(keepAlive: true, retry: _noRetry)
class Session extends _$Session {
  @override
  Future<SessionStatus> build() async {
    final environment = ref.watch(appEnvironmentProvider);
    if (!environment.hasBackend) return SessionStatus.signedIn;

    final repository = ref.watch(authRepositoryProvider);
    if (environment.hasTestUser) {
      await repository.signIn(
        identifier: environment.testUserIdentifier,
        password: environment.testUserPassword,
      );
      return SessionStatus.signedIn;
    }
    return await repository.hasSession()
        ? SessionStatus.signedIn
        : SessionStatus.signedOut;
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    await future.catchError((_) => SessionStatus.signedOut);
  }
}
