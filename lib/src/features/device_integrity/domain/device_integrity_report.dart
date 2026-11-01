import 'package:flutter/foundation.dart';

import 'integrity_signal.dart';

/// Result of one run of the device checks.
@immutable
class DeviceIntegrityReport {
  const DeviceIntegrityReport({
    required this.platform,
    required this.signals,
    required this.checkedAt,
    this.supported = true,
  });

  /// Web and desktop have no root or jailbreak checks.
  const DeviceIntegrityReport.unsupported({
    required this.platform,
    required this.checkedAt,
  }) : signals = const {},
       supported = false;

  final TargetPlatform platform;
  final Set<IntegritySignal> signals;
  final DateTime checkedAt;
  final bool supported;

  /// The checks that run on [platform], in display order.
  List<IntegritySignal> get applicableChecks => [
    if (supported)
      for (final signal in IntegritySignal.values)
        if (signal.platforms.contains(platform)) signal,
  ];

  @override
  bool operator ==(Object other) =>
      other is DeviceIntegrityReport &&
      other.platform == platform &&
      setEquals(other.signals, signals) &&
      other.checkedAt == checkedAt &&
      other.supported == supported;

  @override
  int get hashCode => Object.hash(
    platform,
    Object.hashAllUnordered(signals),
    checkedAt,
    supported,
  );
}

/// Developer-mode overrides. Ignored in release builds.
@immutable
class IntegrityOverrides {
  const IntegrityOverrides({this.enforce = false, this.simulated = const {}});

  /// Debug builds only report what they find unless this is on.
  final bool enforce;

  /// Signals treated as detected, to preview how the app reacts.
  final Set<IntegritySignal> simulated;

  IntegrityOverrides copyWith({
    bool? enforce,
    Set<IntegritySignal>? simulated,
  }) => IntegrityOverrides(
    enforce: enforce ?? this.enforce,
    simulated: simulated ?? this.simulated,
  );

  @override
  bool operator ==(Object other) =>
      other is IntegrityOverrides &&
      other.enforce == enforce &&
      setEquals(other.simulated, simulated);

  @override
  int get hashCode => Object.hash(enforce, Object.hashAllUnordered(simulated));
}

/// What the app currently enforces, combining the checks and any overrides.
@immutable
class IntegrityStatus {
  const IntegrityStatus({
    required this.detected,
    required this.enforced,
    this.simulated = const {},
    this.checked = true,
  });

  final Set<IntegritySignal> detected;
  final Set<IntegritySignal> simulated;
  final bool enforced;

  /// False until the first check finishes.
  final bool checked;

  Set<IntegritySignal> get signals => {...detected, ...simulated};

  IntegrityRisk get risk => IntegrityRisk.highestOf(signals);

  IntegrityVerdict get verdict {
    if (!enforced) return IntegrityVerdict.allow;
    // Fail closed for money until the device has been checked.
    if (!checked) return IntegrityVerdict.blockPayments;
    return risk.verdict;
  }

  @override
  bool operator ==(Object other) =>
      other is IntegrityStatus &&
      setEquals(other.detected, detected) &&
      setEquals(other.simulated, simulated) &&
      other.enforced == enforced &&
      other.checked == checked;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(detected),
    Object.hashAllUnordered(simulated),
    enforced,
    checked,
  );
}

/// Thrown when the device's risk does not allow payments.
class PaymentsBlockedException implements Exception {
  const PaymentsBlockedException(this.risk);
  final IntegrityRisk risk;

  @override
  String toString() => 'PaymentsBlockedException(${risk.name})';
}
