import 'package:flutter/foundation.dart';

/// How dangerous a device signal is. Ordered: later values are worse.
enum IntegrityRisk {
  none,
  low,
  medium,
  high;

  /// Response policy from APS p.44: warn on low risk, block payments on
  /// medium (balance and history stay visible), block the app on high.
  IntegrityVerdict get verdict => switch (this) {
    none => IntegrityVerdict.allow,
    low => IntegrityVerdict.warn,
    medium => IntegrityVerdict.blockPayments,
    high => IntegrityVerdict.blockApp,
  };

  static IntegrityRisk highestOf(Iterable<IntegritySignal> signals) =>
      signals.fold(
        none,
        (worst, signal) =>
            signal.risk.index > worst.index ? signal.risk : worst,
      );
}

/// What the app does about the device's current risk.
enum IntegrityVerdict {
  allow,
  warn,
  blockPayments,
  blockApp;

  bool get paymentsAllowed => index < blockPayments.index;
}

const _both = {TargetPlatform.android, TargetPlatform.iOS};

/// One thing the device checks can find (APS p.44–45).
enum IntegritySignal {
  rooted(
    'Root or jailbreak',
    'The system has been changed to give apps full control of the device.',
    IntegrityRisk.high,
    _both,
  ),
  rootManagementApp(
    'Root management tools',
    'Tools such as Magisk or Cydia are installed.',
    IntegrityRisk.high,
    _both,
  ),
  hookingFramework(
    'Hooking framework',
    'Frida or a similar tool can change the app while it runs.',
    IntegrityRisk.high,
    _both,
  ),
  tampered(
    'App signature',
    'The app has been modified or re-signed.',
    IntegrityRisk.high,
    {TargetPlatform.iOS},
  ),
  emulator(
    'Emulator or simulator',
    'The app is running on a virtual device, not a real phone.',
    IntegrityRisk.medium,
    _both,
  ),
  debugger(
    'Debugger',
    'A debugger is attached to the app.',
    IntegrityRisk.medium,
    _both,
  ),
  reverseEngineeringTools(
    'Reverse-engineering tools',
    'Tools for inspecting the app were found.',
    IntegrityRisk.medium,
    {TargetPlatform.iOS},
  ),
  checkFailed(
    'Device checks',
    'The device checks could not run.',
    IntegrityRisk.medium,
    _both,
  ),
  proxy(
    'Network proxy',
    'Traffic goes through a proxy that could read it.',
    IntegrityRisk.low,
    {TargetPlatform.iOS},
  ),
  developerOptions(
    'Developer options',
    'Android developer options are turned on.',
    IntegrityRisk.low,
    {TargetPlatform.android},
  ),
  externalStorage(
    'External storage',
    'The app is installed on an SD card that other apps can read.',
    IntegrityRisk.low,
    {TargetPlatform.android},
  );

  const IntegritySignal(
    this.label,
    this.description,
    this.risk,
    this.platforms,
  );

  final String label;
  final String description;
  final IntegrityRisk risk;

  /// Platforms where this is actually checked.
  final Set<TargetPlatform> platforms;
}
