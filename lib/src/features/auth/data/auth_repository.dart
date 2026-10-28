import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';

part 'auth_repository.g.dart';

/// Mobile sign-in against `/api/v1/auth`. Tokens go to secure storage through
/// [ApiClient]; nothing here keeps them in memory.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final json = await _api.postJson(
      '/api/v1/auth/login',
      {'identifier': identifier, 'password': password},
      authenticated: false,
      retryAuthentication: false,
    );
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    if (access is! String || refresh is! String) {
      throw const FormatException('Sign-in response is missing tokens.');
    }
    await _api.saveTokens(access, refresh);
  }

  Future<bool> hasSession() => _api.hasAccessToken();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(apiClientProvider));
