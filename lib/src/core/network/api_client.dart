import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_environment.dart';
import '../storage/secure_store.dart';

part 'api_client.g.dart';

/// App-wide HTTP client; closed when the provider is disposed.
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = ApiClient(
    baseUrl: ref.watch(appEnvironmentProvider).apiBaseUrl,
    store: ref.watch(secureStoreProvider),
  );
  ref.onDispose(client.dispose);
  return client;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client, SecureStore? store})
    : _client = client ?? http.Client(),
      _store = store ?? SecureStore();
  final String baseUrl;
  final http.Client _client;
  final SecureStore _store;
  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? etag,
    bool authenticated = true,
  }) async {
    var response = await _client
        .get(
          _uri(path),
          headers: await _headers(etag: etag, authenticated: authenticated),
        )
        .timeout(const Duration(seconds: 15));
    if (authenticated && response.statusCode == 401 && await _refreshTokens()) {
      response = await _client
          .get(
            _uri(path),
            headers: await _headers(etag: etag, authenticated: true),
          )
          .timeout(const Duration(seconds: 15));
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body, {
    bool authenticated = true,
    bool retryAuthentication = true,
  }) async {
    var response = await _client
        .post(
          _uri(path),
          headers: await _headers(authenticated: authenticated, json: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (authenticated &&
        retryAuthentication &&
        response.statusCode == 401 &&
        await _refreshTokens()) {
      response = await _client
          .post(
            _uri(path),
            headers: await _headers(authenticated: true, json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    }
    return _decode(response);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _store.write(SecureKey.accessToken, accessToken);
    await _store.write(SecureKey.refreshToken, refreshToken);
  }

  /// Ends the local session: tokens and the stored user profile.
  Future<void> clearSession() => _store.clearAll();

  Future<bool> hasAccessToken() async =>
      (await _store.read(SecureKey.accessToken))?.isNotEmpty == true;

  Future<bool> _refreshTokens() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final operation = _performRefresh();
    _refreshInFlight = operation;
    return operation.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _store.read(SecureKey.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _client
          .post(
            _uri('/api/v1/auth/refresh'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearSession();
        return false;
      }
      final json = jsonDecode(response.body);
      if (json is! Map ||
          json['accessToken'] is! String ||
          json['refreshToken'] is! String) {
        await clearSession();
        return false;
      }
      await saveTokens(
        json['accessToken'] as String,
        json['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri _uri(String path) => Uri.parse(baseUrl).resolve(path);
  Future<Map<String, String>> _headers({
    String? etag,
    required bool authenticated,
    bool json = false,
  }) async {
    final token = authenticated
        ? await _store.read(SecureKey.accessToken)
        : null;
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (etag != null) headers['If-None-Match'] = etag;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        'The AfghanPay service could not process this request.',
      );
    }
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected an API object.');
    }
    return value;
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}
