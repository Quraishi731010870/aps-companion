import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_environment.dart';
import '../domain/payment_gateway.dart';
import '../network/api_client.dart';
import 'backend_payment_gateway.dart';
import 'google_sheets_gateway.dart';
import 'mock_payment_gateway.dart';

part 'payment_gateway_provider.g.dart';

/// Single place that chooses the gateway: backend if `API_BASE_URL` is set,
/// otherwise Google Sheets, otherwise the offline mock.
@Riverpod(keepAlive: true)
PaymentGateway paymentGateway(Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.hasBackend) {
    return BackendPaymentGateway(ref.watch(apiClientProvider));
  }
  if (environment.hasSheets) {
    final gateway = GoogleSheetsGateway(
      endpoint: environment.sheetsEndpoint,
      apiKey: environment.sheetsApiKey,
    );
    ref.onDispose(gateway.dispose);
    return gateway;
  }
  return MockPaymentGateway();
}
