import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/mock_payment_gateway.dart';
import 'data/google_sheets_gateway.dart';
import 'data/backend_payment_gateway.dart';
import 'network/api_client.dart';
import 'network/config_sync_service.dart';
import 'repositories/config_repository.dart';
import 'screens/main_shell.dart';
import 'state/app_state.dart';

class AfghanEmiApp extends StatefulWidget {
  const AfghanEmiApp({super.key});

  @override
  State<AfghanEmiApp> createState() => _AfghanEmiAppState();
}

class _AfghanEmiAppState extends State<AfghanEmiApp> {
  final state = AppState();
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  late final ApiClient api = ApiClient(baseUrl: apiBaseUrl);
  late final ConfigSyncService sync = ConfigSyncService(
    baseUrl: apiBaseUrl,
    onConfigurationChanged: state.refreshConfiguration,
  );
  static const sheetsEndpoint = String.fromEnvironment('GOOGLE_SHEETS_API_URL');
  static const sheetsApiKey = String.fromEnvironment('GOOGLE_SHEETS_API_KEY');

  @override
  void initState() {
    super.initState();
    if (api.isConfigured) {
      state.configRepository = ConfigRepository(api);
      state.refreshConfiguration();
      sync.connect();
    }
  }

  @override
  void dispose() {
    sync.dispose();
    api.dispose();
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PayAfghan',
        locale: state.locale,
        supportedLocales: const [Locale('en'), Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087f67)),
          scaffoldBackgroundColor: const Color(0xfff5f7f6),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xfff0f3f2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xff087f67),
                width: 1.5,
              ),
            ),
          ),
        ),
        home: state.maintenanceMode
            ? _MaintenanceScreen(
                message:
                    '${state.configuration.values['maintenanceMessage'] ?? 'Services are temporarily unavailable for scheduled maintenance.'}',
                onRetry: state.refreshConfiguration,
              )
            : MainShell(
                gateway: api.isConfigured
                    ? BackendPaymentGateway(api)
                    : sheetsEndpoint.isEmpty
                    ? MockPaymentGateway()
                    : GoogleSheetsGateway(
                        endpoint: sheetsEndpoint,
                        apiKey: sheetsApiKey,
                      ),
              ),
      ),
    ),
  );
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.engineering_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Scheduled maintenance',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
