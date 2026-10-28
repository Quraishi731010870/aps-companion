import '../domain/payment_gateway.dart';
import '../domain/payment_transaction.dart';
import '../network/api_client.dart';

class BackendPaymentGateway implements PaymentGateway {
  BackendPaymentGateway(this.api);
  final ApiClient api;
  @override
  Future<PaymentResult> execute(PaymentRequest request) async {
    final json = await api.postJson('/api/v1/transactions', request.toJson());
    return PaymentResult(
      request: request,
      transactionId: '${json['id']}',
      state: _state('${json['status']}'),
      message: '${json['responseDescription'] ?? 'Transaction submitted'}',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }

  @override
  Future<List<WalletActivity>> fetchActivities() async {
    final json = await api.getJson('/api/v1/transactions?page=0&pageSize=50');
    final values = json['items'];
    if (values is! List) return const [];
    return values.whereType<Map>().map((raw) {
      final row = raw.cast<String, dynamic>();
      final code = int.tryParse('${row['operationCode']}') ?? 774;
      final operation = PaymentOperation.values.firstWhere(
        (value) => value.code == code,
        orElse: () => PaymentOperation.purchase,
      );
      return WalletActivity(
        title: '${row['operationLabel']}',
        subtitle: '${row['destination'] ?? ''}',
        amount: double.tryParse('${row['amount']}') ?? 0,
        incoming: false,
        operation: operation,
        date: DateTime.tryParse('${row['createdAt']}') ?? DateTime.now(),
        source: '${row['source'] ?? ''}',
        destination: '${row['destination'] ?? ''}',
        rrn: '${row['rrn'] ?? ''}',
        currency: '${row['currency'] ?? 'AFN'}',
        status: _state('${row['status']}'),
      );
    }).toList();
  }

  TransactionState _state(String value) => switch (value.toUpperCase()) {
    'SUCCESS' => TransactionState.successful,
    'FAILED' || 'TIMEOUT' => TransactionState.failed,
    'REVERSED' => TransactionState.reversed,
    _ => TransactionState.processing,
  };
}
