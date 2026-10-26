import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/payment_transaction.dart';
import 'mock_payment_gateway.dart';

class GoogleSheetsGateway implements PaymentGateway {
  GoogleSheetsGateway({
    required this.endpoint,
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  final String endpoint;
  final String apiKey;
  final http.Client client;

  @override
  Future<PaymentResult> execute(PaymentRequest request) async {
    final response = await client
        .post(
          Uri.parse(endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'createTransaction',
            'apiKey': apiKey,
            'data': request.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    final now = DateTime.tryParse('${body['createdAt']}') ?? DateTime.now();
    return PaymentResult(
      request: request,
      transactionId: '${body['rrn'] ?? body['transactionId']}',
      state: TransactionState.successful,
      message: '${body['message'] ?? 'Transaction saved to Google Sheets'}',
      createdAt: now,
    );
  }

  @override
  Future<List<WalletActivity>> fetchActivities() async {
    final uri = Uri.parse(endpoint).replace(
      queryParameters: {'action': 'listTransactions', 'apiKey': apiKey},
    );
    final response = await client.get(uri).timeout(const Duration(seconds: 15));
    final body = _decode(response);
    final rows = body['data'];
    if (rows is! List) return const [];
    return rows.whereType<Map>().map((row) {
      final code = int.tryParse('${row['transactionType']}') ?? 774;
      final operation = PaymentOperation.values.firstWhere(
        (item) => item.code == code,
        orElse: () => PaymentOperation.purchase,
      );
      final amount = double.tryParse('${row['amount']}') ?? 0;
      return WalletActivity(
        title: '${row['title'] ?? operation.label}',
        subtitle: '${row['destination'] ?? ''}',
        amount: amount,
        incoming: row['direction'] == 'credit',
        operation: operation,
        date: DateTime.tryParse('${row['createdAt']}') ?? DateTime.now(),
        source: '${row['source'] ?? ''}',
        destination: '${row['destination'] ?? ''}',
        rrn: '${row['rrn'] ?? row['transactionId'] ?? ''}',
        cardNumber: '${row['cardNumber'] ?? '•••• 1087'}',
        currency: '${row['currency'] ?? 'AFN'}',
        fee: double.tryParse('${row['fee']}') ?? 0,
      );
    }).toList();
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Sheets request failed (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Google Sheets response');
    }
    if (decoded['ok'] != true) {
      throw Exception(
        '${decoded['error'] ?? 'Google Sheets operation failed'}',
      );
    }
    return decoded;
  }
}
