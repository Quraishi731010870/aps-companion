import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_environment.dart';
import '../security/device_key_signer.dart';
import '../security/request_signer.dart';
import '../storage/secure_store.dart';

part 'api_client.g.dart';

/// App-wide HTTP client; closed when the provider is disposed.
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = ApiClient(
    baseUrl: ref.watch(appEnvironmentProvider).apiBaseUrl,
    store: ref.watch(secureStoreProvider),
    signer: ref.watch(requestSignerProvider),
  );
  ref.onDispose(client.dispose);
  return client;
}

/// Every request is signed by [RequestSigner] (when given) so the backend can
/// check it comes from the device bound to the session.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    SecureStore? store,
    this._signer,
  }) : _client = client ?? http.Client(),
       _store = store ?? SecureStore();
  final String baseUrl;
  final http.Client _client;
  final SecureStore _store;
  final RequestSigner? _signer;
  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? etag,
    bool authenticated = true,
  }) async {
    final uri = _uri(path);
    Future<http.Response> send() async => _client
        .get(
          uri,
          headers: await _headers(
            method: 'GET',
            uri: uri,
            etag: etag,
            authenticated: authenticated,
          ),
        )
        .timeout(const Duration(seconds: 15));
    var response = await send();
    if (authenticated && response.statusCode == 401 && await _refreshTokens()) {
      response = await send();
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body, {
    bool authenticated = true,
    bool retryAuthentication = true,
  }) async {
    final uri = _uri(path);
    // The exact bytes that are signed are the bytes that are sent.
    final bytes = utf8.encode(jsonEncode(body));
    Future<http.Response> send() async => _client
        .post(
          uri,
          headers: await _headers(
            method: 'POST',
            uri: uri,
            body: bytes,
            authenticated: authenticated,
            json: true,
          ),
          body: bytes,
        )
        .timeout(const Duration(seconds: 20));
    var response = await send();
    if (authenticated &&
        retryAuthentication &&
        response.statusCode == 401 &&
        await _refreshTokens()) {
      response = await send();
    }
    return _decode(response);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _store.write(SecureKey.accessToken, accessToken);
    await _store.write(SecureKey.refreshToken, refreshToken);
  }

  /// Ends the local session: tokens, profile and linked card. The device key
  /// stays so this device is still recognised at the next login.
  Future<void> clearSession() => _store.clearSession();

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
      final uri = _uri('/api/v1/auth/refresh');
      final bytes = utf8.encode(jsonEncode({'refreshToken': refreshToken}));
      final response = await _client
          .post(
            uri,
            headers: await _headers(
              method: 'POST',
              uri: uri,
              body: bytes,
              authenticated: false,
              json: true,
            ),
            body: bytes,
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
    required String method,
    required Uri uri,
    List<int> body = const [],
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
    final signer = _signer;
    if (signer != null) {
      headers.addAll(await signer.sign(method: method, uri: uri, body: body));
    }
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
