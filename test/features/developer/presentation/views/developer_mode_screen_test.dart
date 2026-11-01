import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/developer/presentation/views/developer_mode_screen.dart';
import 'package:afghan_emi/src/features/device_integrity/domain/integrity_signal.dart';
import 'package:afghan_emi/src/features/device_integrity/presentation/view_models/device_integrity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  setUp(mockSecureStorage);

  testWidgets('simulating a signal under enforcement changes the verdict', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpScreen(tester, const DeveloperModeScreen());
    final container = containerOf(tester);

    expect(find.text('Enforce in this build'), findsOneWidget);
    expect(find.text('Build and environment'), findsOneWidget);
    expect(find.text('offline mock'), findsOneWidget);

    await tester.tap(find.text('Enforce in this build'));
    await tester.pumpAndSettle();
    await scrollToAndTap(tester, find.text('Emulator or simulator'));

    final status = container.read(integrityStatusProvider);
    expect(status.simulated, {IntegritySignal.emulator});
    expect(status.verdict, IntegrityVerdict.blockPayments);

    await scrollToAndTap(tester, find.text('Reset developer overrides'));
    expect(
      container.read(integrityStatusProvider).verdict,
      IntegrityVerdict.allow,
    );
  });

  testWidgets('shows nothing in a release build', (tester) async {
    await pumpScreen(
      tester,
      const DeveloperModeScreen(),
      overrides: [
        appEnvironmentProvider.overrideWithValue(
          const AppEnvironment(isRelease: true),
        ),
      ],
    );

    expect(
      find.text('Developer mode is off in release builds.'),
      findsOneWidget,
    );
    expect(find.text('Enforce in this build'), findsNothing);
  });
}
