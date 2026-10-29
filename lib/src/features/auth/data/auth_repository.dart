import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/device_key_signer.dart';
import '../../../core/security/request_signer.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/user_profile.dart';

part 'auth_repository.g.dart';

/// Thrown when the credentials are valid but the account may not use the
/// mobile app (for example an administrator).
class SignInRejected implements Exception {
  const SignInRejected();
  @override
  String toString() => 'This account cannot sign in to the mobile app.';
}

/// Mobile sign-in against `/api/v1/auth`. Tokens and the user profile are
/// written only to [SecureStore]; nothing is cached in plain storage.
/// Login also binds this device's signing key to the customer.
class AuthRepository {
  AuthRepository(this._api, this._store, this._signer);
  final ApiClient _api;
  final SecureStore _store;
  final RequestSigner _signer;

  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final json = await _api.postJson(
      '/api/v1/auth/login',
      {
        'identifier': identifier,
        'password': password,
        'device': (await _signer.binding()).toJson(),
      },
      authenticated: false,
      retryAuthentication: false,
    );
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final principal = json['principal'];
    if (access is! String ||
        refresh is! String ||
        principal is! Map ||
        principal['sub'] is! String) {
      throw const FormatException('Sign-in response is incomplete.');
    }
    // The backend login accepts any account type; only customers may use
    // the mobile app, so nothing is stored for other accounts.
    if (principal['type'] != 'MOBILE_USER') throw const SignInRejected();

    final displayName = json['displayName'];
    final profile = UserProfile(
      id: principal['sub'] as String,
      displayName: displayName is String ? displayName : '',
    );
    await _api.saveTokens(access, refresh);
    await _store.write(SecureKey.userProfile, jsonEncode(profile.toJson()));
    return profile;
  }

  Future<bool> hasSession() => _api.hasAccessToken();

  /// The stored profile, or null when signed out or the value is unreadable.
  Future<UserProfile?> currentUser() async {
    final raw = await _store.read(SecureKey.userProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// Removes tokens and the profile; the device key stays.
  Future<void> signOut() => _api.clearSession();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  ref.watch(apiClientProvider),
  ref.watch(secureStoreProvider),
  ref.watch(requestSignerProvider),
);
