import 'package:flutter/foundation.dart';

/// User preferences and client-side spending limits.
@immutable
class AppSettings {
  const AppSettings({
    this.languageCode = 'en',
    this.biometricEnabled = false,
    this.limits = const TransactionLimits(),
  });

  final String languageCode;
  final bool biometricEnabled;
  final TransactionLimits limits;

  bool get isDari => languageCode == 'fa';

  AppSettings copyWith({
    String? languageCode,
    bool? biometricEnabled,
    TransactionLimits? limits,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    limits: limits ?? this.limits,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.languageCode == languageCode &&
      other.biometricEnabled == biometricEnabled &&
      other.limits == limits;

  @override
  int get hashCode => Object.hash(languageCode, biometricEnabled, limits);
}

@immutable
class TransactionLimits {
  const TransactionLimits({
    this.daily = 50000,
    this.monthly = 250000,
    this.dailyCount = 25,
  });

  final double daily;
  final double monthly;
  final int dailyCount;

  /// Monthly must cover at least one full day.
  bool get isValid => daily > 0 && monthly >= daily && dailyCount > 0;

  bool allows(double amount) => amount <= daily && amount <= monthly;

  @override
  bool operator ==(Object other) =>
      other is TransactionLimits &&
      other.daily == daily &&
      other.monthly == monthly &&
      other.dailyCount == dailyCount;

  @override
  int get hashCode => Object.hash(daily, monthly, dailyCount);
}
