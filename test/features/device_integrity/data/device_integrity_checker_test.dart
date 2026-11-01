import 'package:afghan_emi/src/features/device_integrity/data/device_integrity_checker.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('jailbreak_root_detection');
  final calls = <MethodCall>[];

  void answer({List<String> issues = const [], bool tampered = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'checkForIssues' => issues,
            'isTampered' => tampered,
            _ => null,
          };
        });
  }

  setUp(calls.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  PluginDeviceIntegrityChecker checker(TargetPlatform platform) =>
      PluginDeviceIntegrityChecker(
        platform: platform,
        clock: () => DateTime(2026, 11, 1),
      );

  test('maps the plugin issues to signals', () async {
    answer(
      issues: ['jailbreak', 'fridaFound', 'devMode', 'magiskFound', 'debugged'],
    );
    final report = await checker(TargetPlatform.android).check();
    expect(report.signals, {
      IntegritySignal.rooted,
      IntegritySignal.hookingFramework,
      IntegritySignal.developerOptions,
      IntegritySignal.rootManagementApp,
      IntegritySignal.debugger,
    });
    expect(report.checkedAt, DateTime(2026, 11, 1));
    expect(calls.map((c) => c.method), isNot(contains('isTampered')));
  });

  test('checks the bundle id on iOS', () async {
    answer(issues: ['notRealDevice'], tampered: true);
    final report = await checker(TargetPlatform.iOS).check();
    expect(report.signals, {
      IntegritySignal.emulator,
      IntegritySignal.tampered,
    });
    final tamperCall = calls.singleWhere((c) => c.method == 'isTampered');
    expect(tamperCall.arguments, {
      'bundleId': PluginDeviceIntegrityChecker.iosBundleId,
    });
  });

  test('ignores the Cydia check on the iOS simulator only', () async {
    answer(issues: ['notRealDevice', 'cydiaFound']);
    final simulator = await checker(TargetPlatform.iOS).check();
    expect(simulator.signals, {IntegritySignal.emulator});

    answer(issues: ['cydiaFound']);
    final device = await checker(TargetPlatform.iOS).check();
    expect(device.signals, {IntegritySignal.rootManagementApp});

    answer(issues: ['notRealDevice', 'magiskFound']);
    final android = await checker(TargetPlatform.android).check();
    expect(android.signals, contains(IntegritySignal.rootManagementApp));
  });

  test('a clean device reports nothing', () async {
    answer();
    final report = await checker(TargetPlatform.iOS).check();
    expect(report.signals, isEmpty);
    expect(report.supported, isTrue);
  });

  test('fails closed when the plugin throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'boom'),
        );
    final report = await checker(TargetPlatform.android).check();
    expect(report.signals, {IntegritySignal.checkFailed});
  });

  test('desktop and web report as unsupported', () async {
    final report = await const UnsupportedDeviceIntegrityChecker(
      TargetPlatform.macOS,
    ).check();
    expect(report.supported, isFalse);
    expect(report.signals, isEmpty);
  });
}
