import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/remote_config/state/mobile_config.dart';
import 'features/auth/presentation/views/session_gate.dart';
import 'features/settings/presentation/view_models/settings.dart';
import 'shell/main_shell.dart';

class AfghanEmiApp extends ConsumerWidget {
  const AfghanEmiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(
      settingsProvider.select((settings) => settings.languageCode),
    );
    final maintenanceMode = ref.watch(
      currentConfigProvider.select((config) => config.maintenanceMode),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PayAfghan',
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en'), Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme,
      home: maintenanceMode
          ? const _MaintenanceScreen()
          : const SessionGate(child: MainShell()),
    );
  }
}

final _theme = ThemeData(
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
      borderSide: const BorderSide(color: Color(0xff087f67), width: 1.5),
    ),
  ),
);

class _MaintenanceScreen extends ConsumerWidget {
  const _MaintenanceScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      currentConfigProvider.select((config) => config.maintenanceMessage),
    );
    return Scaffold(
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
                  Text(
                    message ?? 'Services are temporarily unavailable for scheduled maintenance.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(mobileConfigProvider.notifier).refresh(),
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
}
