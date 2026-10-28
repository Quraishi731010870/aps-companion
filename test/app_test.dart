import 'package:afghan_emi/src/repositories/config_repository.dart';
import 'package:afghan_emi/src/state/mobile_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

/// Serves maintenance on the first load and a normal config afterwards.
var _loads = 0;

class _MaintenanceThenNormal extends MobileConfig {
  @override
  Future<MobileConfiguration> build() async => _loads++ == 0
      ? testConfig(
          values: {'maintenanceMode': true, 'maintenanceMessage': 'Back soon'},
        )
      : testConfig();
}

void main() {
  setUp(() => _loads = 0);

  testWidgets('maintenance mode replaces the app until it ends', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        mobileConfigProvider.overrideWith(_MaintenanceThenNormal.new),
      ],
    );

    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.text('Back soon'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduled maintenance'), findsNothing);
    expect(find.text('Available balance'), findsOneWidget);
  });

  testWidgets('switching to Dari translates the app and flips to RTL', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دری').last);
    await tester.pumpAndSettle();

    expect(find.text('خانه'), findsOneWidget); // "Home" in the nav bar
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
  });
}
