import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/payments/data/backend_payment_gateway.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../helpers/test_app.dart';

const _request = PaymentRequest(
  operation: PaymentOperation.purchase,
  source: 'WALLET-7814',
  destination: 'MERCHANT-1',
  amount: 250,
  reference: 'groceries',
  idempotencyKey: 'key-1',
);

BackendPaymentGateway _gateway(http.Response Function(http.Request) reply) =>
    BackendPaymentGateway(
      ApiClient(
        baseUrl: 'http://api.test',
        client: MockClient((request) async => reply(request)),
      ),
    );

void main() {
  setUp(mockSecureStorage);

  test('posts the request body to /api/v1/transactions', () async {
    late http.Request sent;
    await _gateway((request) {
      sent = request;
      return http.Response(
        jsonEncode({'id': 'AFG-1', 'status': 'PENDING'}),
        200,
      );
    }).execute(_request);

    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/v1/transactions');
    expect(jsonDecode(sent.body), {
      'transactionType': 774,
      'source': 'WALLET-7814',
      'destination': 'MERCHANT-1',
      'amount': 250,
      'currency': 'AFN',
      'reference': 'groceries',
      'idempotencyKey': 'key-1',
    });
  });

  for (final (status, expected) in [
    ('SUCCESS', TransactionState.successful),
    ('success', TransactionState.successful),
    ('FAILED', TransactionState.failed),
    ('TIMEOUT', TransactionState.failed),
    ('REVERSED', TransactionState.reversed),
    ('PENDING', TransactionState.processing),
    ('SOMETHING_NEW', TransactionState.processing),
  ]) {
    test('maps backend status $status to $expected', () async {
      final result = await _gateway(
        (_) => http.Response(
          jsonEncode({
            'id': 'AFG-1',
            'status': status,
            'createdAt': '2026-10-28T10:00:00Z',
          }),
          200,
        ),
      ).execute(_request);

      expect(result.state, expected);
      expect(result.transactionId, 'AFG-1');
      expect(result.createdAt, DateTime.utc(2026, 10, 28, 10));
    });
  }

  test('parses the activity list and tolerates unknown codes', () async {
    final activities = await _gateway(
      (_) => http.Response(
        jsonEncode({
          'items': [
            {
              'operationCode': 651,
              'operationLabel': 'Card Title Fetch',
              'amount': 0,
              'status': 'reversed',
              'rrn': '880000000377',
              'createdAt': '2026-10-28T05:20:07Z',
            },
            {'operationCode': 9999, 'operationLabel': 'Future op'},
          ],
        }),
        200,
      ),
    ).fetchActivities();

    expect(activities, hasLength(2));
    expect(activities[0].operation, PaymentOperation.nameInquiry);
    expect(activities[0].status, TransactionState.reversed);
    expect(activities[0].rrn, '880000000377');
    expect(activities[1].operation, PaymentOperation.purchase);
  });

  test('a missing items list yields no activities', () async {
    final activities = await _gateway(
      (_) => http.Response(jsonEncode({'total': 0}), 200),
    ).fetchActivities();

    expect(activities, isEmpty);
  });
}
