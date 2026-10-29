import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' show ClientException;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/device_key_signer.dart';
import '../../../core/security/request_signer.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/auth_failure.dart';
import '../domain/user_profile.dart';

part 'auth_repository.g.dart';

/// Mobile sign-in and sign-up against `/api/v1/auth`. Tokens and the user
/// profile are written only to [SecureStore]; nothing is cached in plain
/// storage. Both bind this device's signing key to the customer.
///
/// Failures are thrown as [AuthFailure]; a malformed response as
/// [FormatException].
class AuthRepository {
  AuthRepository(this._api, this._store, this._signer);
  final ApiClient _api;
  final SecureStore _store;
  final RequestSigner _signer;

  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async => _startSession('/api/v1/auth/login', {
    'identifier': identifier,
    'password': password,
  });

  /// Creates a customer with an empty wallet and signs in as them.
  Future<UserProfile> register({
    required String displayName,
    required String phone,
    required String password,
  }) async => _startSession('/api/v1/auth/register', {
    'displayName': displayName,
    'phone': phone,
    'password': password,
  });

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

  /// Revokes the session on the server when reachable, then removes tokens
  /// and the profile; the device key stays.
  Future<void> signOut() async {
    try {
      if (await _api.hasAccessToken()) {
        await _api.postJson('/api/v1/auth/logout', const {});
      }
    } catch (_) {
      // Offline or already expired: signing out locally is what matters.
    } finally {
      await _api.clearSession();
    }
  }

  Future<UserProfile> _startSession(
    String path,
    Map<String, Object?> body,
  ) async {
    final Map<String, dynamic> json;
    try {
      json = await _api.postJson(
        path,
        {...body, 'device': (await _signer.binding()).toJson()},
        authenticated: false,
        retryAuthentication: false,
      );
    } on ApiException catch (error) {
      throw _failure(error);
    } on ClientException {
      throw AuthFailure.network;
    } on TimeoutException {
      throw AuthFailure.network;
    }
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final principal = json['principal'];
    if (access is! String ||
        refresh is! String ||
        principal is! Map ||
        principal['sub'] is! String) {
      throw const FormatException('Sign-in response is incomplete.');
    }
    // Only customers may use the mobile app; nothing is stored for others.
    if (principal['type'] != 'MOBILE_USER') throw AuthFailure.notAllowed;

    final displayName = json['displayName'];
    final profile = UserProfile(
      id: principal['sub'] as String,
      displayName: displayName is String ? displayName : '',
    );
    await _api.saveTokens(access, refresh);
    await _store.write(SecureKey.userProfile, jsonEncode(profile.toJson()));
    return profile;
  }

  static AuthFailure _failure(ApiException error) => switch (error.code) {
    'INVALID_CREDENTIALS' => AuthFailure.invalidCredentials,
    'ACCOUNT_LOCKED' => AuthFailure.accountLocked,
    'PHONE_IN_USE' => AuthFailure.phoneInUse,
    'REGISTRATION_DISABLED' => AuthFailure.registrationClosed,
    _ when error.statusCode == 401 => AuthFailure.invalidCredentials,
    _ => AuthFailure.unknown,
  };
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  ref.watch(apiClientProvider),
  ref.watch(secureStoreProvider),
  ref.watch(requestSignerProvider),
);
