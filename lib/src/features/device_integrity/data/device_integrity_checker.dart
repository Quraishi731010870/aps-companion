import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/device_integrity_report.dart';
import '../domain/integrity_signal.dart';

part 'device_integrity_checker.g.dart';

/// Runs the device checks. Never throws: a failed check is reported as
/// [IntegritySignal.checkFailed] so the app fails closed.
abstract interface class DeviceIntegrityChecker {
  Future<DeviceIntegrityReport> check();
}

/// RootBeer, Magisk and Frida checks on Android; IOSSecuritySuite on iOS.
class PluginDeviceIntegrityChecker implements DeviceIntegrityChecker {
  PluginDeviceIntegrityChecker({
    required this.platform,
    JailbreakRootDetection? detection,
    DateTime Function()? clock,
  }) : _detection = detection ?? JailbreakRootDetection.instance,
       _clock = clock ?? DateTime.now;

  /// Must match `PRODUCT_BUNDLE_IDENTIFIER`; a re-signed copy reports another.
  static const iosBundleId = 'af.emi.afghanEmi';

  final TargetPlatform platform;
  final JailbreakRootDetection _detection;
  final DateTime Function() _clock;

  @override
  Future<DeviceIntegrityReport> check() async {
    Set<IntegritySignal> signals;
    try {
      signals = {
        for (final issue in await _detection.checkForIssues) _signalFor(issue),
      };
      if (platform == TargetPlatform.iOS) {
        // The plugin's Cydia check looks for /bin/bash, which the simulator
        // sees on the Mac's file system. Real devices hide it, and a
        // simulator is already blocked from paying as an emulator.
        if (signals.contains(IntegritySignal.emulator)) {
          signals.remove(IntegritySignal.rootManagementApp);
        }
        if (await _detection.isTampered(iosBundleId)) {
          signals.add(IntegritySignal.tampered);
        }
      }
    } catch (error) {
      log('Device integrity check failed', error: error, name: 'integrity');
      signals = {IntegritySignal.checkFailed};
    }
    return DeviceIntegrityReport(
      platform: platform,
      signals: signals,
      checkedAt: _clock(),
    );
  }

  static IntegritySignal _signalFor(JailbreakIssue issue) => switch (issue) {
    JailbreakIssue.jailbreak => IntegritySignal.rooted,
    JailbreakIssue.cydiaFound => IntegritySignal.rootManagementApp,
    JailbreakIssue.fridaFound => IntegritySignal.hookingFramework,
    JailbreakIssue.tampered => IntegritySignal.tampered,
    JailbreakIssue.notRealDevice => IntegritySignal.emulator,
    JailbreakIssue.debugged => IntegritySignal.debugger,
    JailbreakIssue.reverseEngineered => IntegritySignal.reverseEngineeringTools,
    JailbreakIssue.proxied => IntegritySignal.proxy,
    JailbreakIssue.devMode => IntegritySignal.developerOptions,
    JailbreakIssue.onExternalStorage => IntegritySignal.externalStorage,
    // The plugin's Android side reports Magisk as a name its Dart enum does
    // not know, so it arrives as `unknown`.
    JailbreakIssue.unknown => IntegritySignal.rootManagementApp,
  };
}

/// Web and desktop: nothing to check.
class UnsupportedDeviceIntegrityChecker implements DeviceIntegrityChecker {
  const UnsupportedDeviceIntegrityChecker(this.platform);
  final TargetPlatform platform;

  @override
  Future<DeviceIntegrityReport> check() async =>
      DeviceIntegrityReport.unsupported(
        platform: platform,
        checkedAt: DateTime.now(),
      );
}

@Riverpod(keepAlive: true)
DeviceIntegrityChecker deviceIntegrityChecker(Ref ref) {
  final platform = defaultTargetPlatform;
  final mobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  return !kIsWeb && mobile
      ? PluginDeviceIntegrityChecker(platform: platform)
      : UnsupportedDeviceIntegrityChecker(platform);
}
