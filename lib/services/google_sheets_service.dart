import 'dart:convert';

import 'package:http/http.dart' as http;

class GoogleSheetsService {
  GoogleSheetsService({
    http.Client? client,
    String? endpoint,
    String? serviceToken,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? _configuredEndpoint,
       _serviceToken = serviceToken ?? _configuredServiceToken;

  static const _configuredEndpoint = String.fromEnvironment(
    'GOOGLE_SHEETS_SERVICE_URL',
  );
  static const _configuredServiceToken = String.fromEnvironment(
    'GOOGLE_SHEETS_SERVICE_TOKEN',
  );

  final http.Client _client;
  final String _endpoint;
  final String _serviceToken;

  bool get isConfigured {
    final uri = Uri.tryParse(_endpoint);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'script.google.com' &&
        uri.pathSegments.length >= 4 &&
        uri.pathSegments[0] == 'macros' &&
        uri.pathSegments[1] == 's' &&
        uri.pathSegments.last == 'exec' &&
        _serviceToken.trim().isNotEmpty;
  }

  Future<List<SheetUser>> readUsers() async {
    final response = await _request(
      () => _client.get(_serviceUri('listUsers')),
    );
    final data = _decode(response);
    final rows = data['users'];
    if (rows is! List) {
      throw const GoogleSheetsException(
        'The service returned an invalid users list.',
      );
    }
    return rows
        .whereType<List>()
        .map((row) => SheetUser.fromRow(row.cast<Object?>()))
        .toList(growable: false);
  }

  Future<void> appendUser(SheetUser user) async {
    final response = await _request(
      () => _client.post(
        _serviceUri('appendUser', includeToken: false),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'token': _serviceToken, 'user': user.toJson()}),
      ),
    );
    _decode(response);
  }

  void dispose() => _client.close();

  Uri _serviceUri(String action, {bool includeToken = true}) {
    if (!isConfigured) {
      throw const GoogleSheetsException(
        'Google Sheets is not configured in this app build. Deploy the Apps Script service and provide both GOOGLE_SHEETS_SERVICE_URL and GOOGLE_SHEETS_SERVICE_TOKEN using the local Dart-defines file.',
      );
    }
    final base = Uri.tryParse(_endpoint);
    if (base == null || base.host.isEmpty) {
      throw const GoogleSheetsException('The Sheets service URL is invalid.');
    }
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        'action': action,
        if (includeToken) 'token': _serviceToken,
      },
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 30));
    } on GoogleSheetsException {
      rethrow;
    } catch (_) {
      throw GoogleSheetsException(
        'Could not reach Google Sheets. Check the network and Apps Script deployment.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GoogleSheetsException(
        'Sheets service request failed (HTTP ${response.statusCode}).',
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      if (decoded['ok'] != true) {
        throw GoogleSheetsException(
          '${decoded['error'] ?? 'Google Sheets service request failed.'}',
        );
      }
      return decoded;
    } on GoogleSheetsException {
      rethrow;
    } catch (error) {
      throw GoogleSheetsException(
        'Invalid response from Sheets service: $error',
      );
    }
  }
}

class SheetUser {
  const SheetUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;

  factory SheetUser.fromRow(List<Object?> row) => SheetUser(
    id: _cell(row, 0),
    name: _cell(row, 1),
    email: _cell(row, 2),
    phone: _cell(row, 3),
    status: _cell(row, 4),
  );

  List<String> toRow() => [id, name, email, phone, status];

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'status': status,
  };

  static String _cell(List<Object?> row, int index) =>
      index < row.length ? '${row[index]}' : '';
}

class GoogleSheetsException implements Exception {
  const GoogleSheetsException(this.message);

  final String message;

  @override
  String toString() => message;
}
