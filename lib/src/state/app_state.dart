import 'package:flutter/material.dart';

import '../repositories/config_repository.dart';

class AppState extends ChangeNotifier {
  Locale locale = const Locale('en');
  bool biometricEnabled = false;
  double dailyLimit = 50000;
  double monthlyLimit = 250000;
  int transactionCountLimit = 25;
  MobileConfiguration configuration = const MobileConfiguration(
    version: 0,
    updatedAt: null,
    values: {},
    features: {},
    content: [],
    fromCache: true,
  );
  bool configurationLoading = false;
  ConfigRepository? configRepository;

  bool get isDari => locale.languageCode == 'fa';
  bool featureEnabled(String key, {bool safeDefault = false}) =>
      configuration.featureEnabled(key, safeDefault: safeDefault);
  bool get maintenanceMode => configuration.values['maintenanceMode'] == true;

  Future<void> refreshConfiguration() async {
    final repository = configRepository;
    if (repository == null) return;
    configurationLoading = true;
    notifyListeners();
    try {
      configuration = await repository.load();
    } finally {
      configurationLoading = false;
      notifyListeners();
    }
  }

  void setLanguage(String code) {
    locale = Locale(code);
    notifyListeners();
  }

  void setBiometric(bool value) {
    biometricEnabled = value;
    notifyListeners();
  }

  void setLimits({
    required double daily,
    required double monthly,
    required int count,
  }) {
    dailyLimit = daily;
    monthlyLimit = monthly;
    transactionCountLimit = count;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
