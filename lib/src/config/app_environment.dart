import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_environment.g.dart';

/// Build-time configuration from `--dart-define`. Read only here and exposed
/// through [appEnvironmentProvider] so tests can override it.
class AppEnvironment {
  const AppEnvironment({
    this.apiBaseUrl = '',
    this.sheetsEndpoint = '',
    this.sheetsApiKey = '',
  });

  const AppEnvironment.fromDefines()
    : apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
      sheetsEndpoint = const String.fromEnvironment('GOOGLE_SHEETS_API_URL'),
      sheetsApiKey = const String.fromEnvironment('GOOGLE_SHEETS_API_KEY');

  final String apiBaseUrl;
  final String sheetsEndpoint;
  final String sheetsApiKey;

  /// Requires an explicit http(s) URL: `Uri` would otherwise read
  /// `localhost:8081` as scheme `localhost`.
  bool get hasBackend {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  bool get hasSheets => sheetsEndpoint.isNotEmpty;
}

@Riverpod(keepAlive: true)
AppEnvironment appEnvironment(Ref ref) => const AppEnvironment.fromDefines();
