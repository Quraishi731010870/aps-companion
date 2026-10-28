import 'package:afghan_emi/src/app.dart';
import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/domain/card_vault.dart';
import 'package:afghan_emi/src/features/payments/domain/saved_card.dart';
import 'package:afghan_emi/src/core/remote_config/data/config_repository.dart';
import 'package:afghan_emi/src/features/payments/data/mock_payment_gateway.dart';
import 'package:afghan_emi/src/features/payments/data/payment_gateway_provider.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_gateway.dart';
import 'package:afghan_emi/src/features/payments/domain/payment_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gateway double that records requests and can be told to fail.
class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({
    this.state = TransactionState.successful,
    this.activities,
  });

  TransactionState state;
  Object? error;
  Object? activitiesError;
  List<WalletActivity>? activities;
  final requests = <PaymentRequest>[];
  int activityFetches = 0;

  @override
  Future<PaymentResult> execute(PaymentRequest request) async {
    requests.add(request);
    final failure = error;
    if (failure != null) throw failure;
    return PaymentResult(
      request: request,
      transactionId: 'TEST-${requests.length}',
      state: state,
      message: 'Test result',
      createdAt: DateTime(2026, 10, 28),
    );
  }

  @override
  Future<List<WalletActivity>> fetchActivities() async {
    activityFetches++;
    final failure = activitiesError;
    if (failure != null) throw failure;
    return activities ?? mockActivities;
  }
}

/// Backend environment with the seeded test user configured.
const backendWithTestUser = AppEnvironment(
  apiBaseUrl: 'http://localhost:8081',
  testUserIdentifier: '+93790000001',
  testUserPassword: 'test-password',
  isRelease: false,
);

/// Auth double that records sign-ins and can be told to fail.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.hasTokens = false, this.profile = testUser});

  static const testUser = UserProfile(
    id: 'user-1',
    displayName: 'Demo Customer 001',
  );

  bool hasTokens;
  Object? error;
  UserProfile profile;
  final signIns = <(String, String)>[];

  @override
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    signIns.add((identifier, password));
    hasTokens = true;
    return profile;
  }

  @override
  Future<bool> hasSession() async => hasTokens;

  @override
  Future<UserProfile?> currentUser() async => hasTokens ? profile : null;

  @override
  Future<void> signOut() async => hasTokens = false;
}

/// Card vault double: records what it was asked to encrypt; can fail.
class FakeCardVault implements CardVault {
  SavedCard? linked;
  Object? error;
  final encrypted = <CardDetails>[];

  static const envelope = CardEnvelope(
    kid: 'kid',
    ek: 'ek',
    iv: 'iv',
    ct: 'ct',
  );

  @override
  Future<SavedCard?> linkedCard() async => linked;

  @override
  Future<SavedCard> saveCard(CardDetails card) async {
    final failure = error;
    if (failure != null) throw failure;
    return linked = SavedCard(token: 'ctok_test', maskedPan: card.maskedPan);
  }

  @override
  Future<CardEnvelope> encryptForPayment(CardDetails card) async {
    final failure = error;
    if (failure != null) throw failure;
    encrypted.add(card);
    return envelope;
  }
}

/// Mocks both plugins [SecureStore] uses. [values] are pre-stored secure
/// values; the install marker is set so they are not wiped as a fresh install
/// unless [freshInstall] is true.
void mockSecureStorage({
  Map<SecureKey, String> values = const {},
  bool freshInstall = false,
  Map<String, Object> preferences = const {},
}) {
  FlutterSecureStorage.setMockInitialValues({
    for (final MapEntry(:key, :value) in values.entries) key.storageKey: value,
  });
  SharedPreferences.setMockInitialValues({
    ...preferences,
    if (!freshInstall) SecureStore.installMarker: true,
  });
}

/// Remote configuration with the given feature flags and values.
MobileConfiguration testConfig({
  Map<String, bool> features = const {},
  Map<String, dynamic> values = const {},
}) => MobileConfiguration(
  version: 1,
  updatedAt: null,
  values: values,
  features: features,
  content: const [],
  fromCache: false,
);

List<Override> _overrides(PaymentGateway? gateway, List<Override> extra) => [
  paymentGatewayProvider.overrideWithValue(gateway ?? FakePaymentGateway()),
  ...extra,
];

/// Pumps the full app with no network, using [gateway] for payments.
Future<void> pumpApp(
  WidgetTester tester, {
  PaymentGateway? gateway,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(gateway, overrides),
      child: const AfghanEmiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps a single [screen] inside a bare MaterialApp, for focused tests.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  PaymentGateway? gateway,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(gateway, overrides),
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the first scrollable until [finder] is built, then taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Makes the test window tall enough that whole forms are built at once.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Reads providers from inside a pumped widget tree.
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
