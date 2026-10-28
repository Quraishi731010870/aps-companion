import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/payments/data/backend_payment_gateway.dart';
import 'package:afghan_emi/src/features/payments/data/google_sheets_gateway.dart';
import 'package:afghan_emi/src/features/payments/data/mock_payment_gateway.dart';
import 'package:afghan_emi/src/features/payments/data/payment_gateway_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _with(AppEnvironment environment) => ProviderContainer.test(
  overrides: [appEnvironmentProvider.overrideWithValue(environment)],
);

void main() {
  test('uses the mock gateway when nothing is configured', () {
    final gateway = _with(const AppEnvironment()).read(paymentGatewayProvider);
    expect(gateway, isA<MockPaymentGateway>());
  });

  test('prefers the backend when API_BASE_URL is set', () {
    final gateway = _with(
      const AppEnvironment(
        apiBaseUrl: 'http://localhost:8081',
        sheetsEndpoint: 'https://script.google.com/x/exec',
      ),
    ).read(paymentGatewayProvider);
    expect(gateway, isA<BackendPaymentGateway>());
  });

  test('falls back to Google Sheets when only it is configured', () {
    final gateway = _with(
      const AppEnvironment(sheetsEndpoint: 'https://script.google.com/x/exec'),
    ).read(paymentGatewayProvider);
    expect(gateway, isA<GoogleSheetsGateway>());
  });

  test('an API URL without a scheme does not count as a backend', () {
    expect(
      const AppEnvironment(apiBaseUrl: 'localhost:8081').hasBackend,
      isFalse,
    );
    expect(const AppEnvironment(apiBaseUrl: '').hasBackend, isFalse);
    expect(const AppEnvironment(apiBaseUrl: 'ftp://host').hasBackend, isFalse);
    expect(
      const AppEnvironment(apiBaseUrl: 'http://10.0.2.2:8081').hasBackend,
      isTrue,
    );
  });
}
