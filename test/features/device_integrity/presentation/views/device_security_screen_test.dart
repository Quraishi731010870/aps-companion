import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:afghan_emi/src/features/device_integrity/presentation/views/device_security_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  late FakeDeviceIntegrityChecker checker;

  setUp(() => checker = FakeDeviceIntegrityChecker());

  Future<void> pump(WidgetTester tester, {bool isRelease = false}) {
    useTallScreen(tester);
    return pumpScreen(
      tester,
      const DeviceSecurityScreen(),
      integrity: checker,
      overrides: [
        appEnvironmentProvider.overrideWithValue(
          AppEnvironment(isRelease: isRelease),
        ),
      ],
    );
  }

  testWidgets('a clean device passes every check', (tester) async {
    await pump(tester, isRelease: true);

    expect(find.text('This device passed the security checks'), findsOneWidget);
    expect(find.text('Root or jailbreak'), findsOneWidget);
    expect(find.text('Developer options'), findsOneWidget);
    expect(find.text('Not detected'), findsWidgets);
    expect(find.text('Developer mode'), findsNothing);
  });

  testWidgets('shows what was found and the debug-build note', (tester) async {
    checker.signals = {IntegritySignal.rooted};
    await pump(tester);

    expect(find.text('This device cannot be used'), findsOneWidget);
    expect(find.textContaining('Detected • High risk'), findsOneWidget);
    expect(
      find.textContaining('Debug build: nothing is blocked'),
      findsOneWidget,
    );
    expect(find.text('Developer mode'), findsOneWidget);
  });

  testWidgets('check again re-runs the device checks', (tester) async {
    await pump(tester);
    expect(checker.checks, 1);

    checker.signals = {IntegritySignal.developerOptions};
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(checker.checks, 2);
    expect(find.text('Security warning'), findsOneWidget);
  });
}
