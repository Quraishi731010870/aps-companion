import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_environment.g.dart';

/// Build-time configuration from `--dart-define`. Read only here and exposed
/// through [appEnvironmentProvider] so tests can override it.
class AppEnvironment {
  const AppEnvironment({
    this.apiBaseUrl = '',
    this.sheetsEndpoint = '',
    this.sheetsApiKey = '',
    this.testUserIdentifier = '',
    this.testUserPassword = '',
    this.isRelease = kReleaseMode,
  });

  const AppEnvironment.fromDefines()
    : apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
      sheetsEndpoint = const String.fromEnvironment('GOOGLE_SHEETS_API_URL'),
      sheetsApiKey = const String.fromEnvironment('GOOGLE_SHEETS_API_KEY'),
      testUserIdentifier = const String.fromEnvironment('TEST_USER_PHONE'),
      testUserPassword = const String.fromEnvironment('TEST_USER_PASSWORD'),
      isRelease = kReleaseMode;

  final String apiBaseUrl;
  final String sheetsEndpoint;
  final String sheetsApiKey;

  /// Seeded test account the app signs in as automatically, until the real
  /// sign-in screen exists. Local `dart_defines.local.json` only.
  final String testUserIdentifier;
  final String testUserPassword;
  final bool isRelease;

  /// Requires an explicit http(s) URL: `Uri` would otherwise read
  /// `localhost:8081` as scheme `localhost`.
  bool get hasBackend {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  bool get hasSheets => sheetsEndpoint.isNotEmpty;

  /// Never honoured in release builds, even if the defines are passed.
  bool get hasTestUser =>
      !isRelease &&
      testUserIdentifier.isNotEmpty &&
      testUserPassword.isNotEmpty;
}

@Riverpod(keepAlive: true)
AppEnvironment appEnvironment(Ref ref) => const AppEnvironment.fromDefines();
