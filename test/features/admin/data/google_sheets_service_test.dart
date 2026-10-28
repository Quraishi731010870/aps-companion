import 'dart:convert';

import 'package:afghan_emi/src/features/admin/data/google_sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _testEndpoint = 'https://script.google.com/macros/s/deployment/exec';
const _testToken = 'unit-test-value';

void main() {
  test('requires an HTTPS Apps Script /exec URL and a token', () {
    expect(GoogleSheetsService().isConfigured, isFalse);
    expect(GoogleSheetsService(endpoint: _testEndpoint).isConfigured, isFalse);
    expect(
      GoogleSheetsService(
        endpoint: 'http://script.google.com/macros/s/deployment/exec',
        serviceToken: _testToken,
      ).isConfigured,
      isFalse,
    );
    expect(
      GoogleSheetsService(
        endpoint: 'https://example.invalid/macros/s/deployment/exec',
        serviceToken: _testToken,
      ).isConfigured,
      isFalse,
    );
    expect(
      GoogleSheetsService(
        endpoint: _testEndpoint,
        serviceToken: _testToken,
      ).isConfigured,
      isTrue,
    );
  });

  test('requests the Users worksheet and parses rows', () async {
    Uri? requestedUri;
    final service = GoogleSheetsService(
      endpoint: _testEndpoint,
      serviceToken: _testToken,
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'ok': true,
            'users': [
              [
                'CUS-1',
                'Test User',
                'user@example.invalid',
                '+9300000000',
                'Active',
              ],
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    final users = await service.readUsers();

    expect(requestedUri?.queryParameters['action'], 'listUsers');
    expect(requestedUri?.queryParameters['token'], _testToken);
    expect(users, hasLength(1));
    expect(users.single.id, 'CUS-1');
    expect(users.single.name, 'Test User');
  });

  test('posts new rows to the Apps Script appendUser action', () async {
    http.Request? sentRequest;
    final service = GoogleSheetsService(
      endpoint: _testEndpoint,
      serviceToken: _testToken,
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    addTearDown(service.dispose);

    await service.appendUser(
      const SheetUser(
        id: 'CUS-2',
        name: 'Another User',
        email: 'another@example.invalid',
        phone: '+9300000001',
        status: 'Active',
      ),
    );

    expect(sentRequest?.url.queryParameters['action'], 'appendUser');
    final body = jsonDecode(sentRequest!.body) as Map<String, dynamic>;
    expect(body['token'], _testToken);
    expect((body['user'] as Map<String, dynamic>)['id'], 'CUS-2');
  });

  test('does not display a server response body on HTTP errors', () async {
    final service = GoogleSheetsService(
      endpoint: _testEndpoint,
      serviceToken: _testToken,
      client: MockClient((_) async => http.Response('internal response', 500)),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.readUsers(),
      throwsA(
        isA<GoogleSheetsException>().having(
          (error) => error.message,
          'message',
          isNot(contains('internal response')),
        ),
      ),
    );
  });
}
