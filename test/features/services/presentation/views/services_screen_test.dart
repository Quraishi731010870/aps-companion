import 'package:afghan_emi/src/core/remote_config/state/mobile_config.dart';
import 'package:afghan_emi/src/features/services/presentation/views/services_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('lists every enabled operation', (tester) async {
    useTallScreen(tester);
    await pumpScreen(tester, const ServicesScreen());

    expect(find.text('Balance Inquiry'), findsOneWidget);
    expect(find.text('Cash-Out'), findsOneWidget);
  });

  testWidgets('search filters by name or transaction code', (tester) async {
    useTallScreen(tester);
    await pumpScreen(tester, const ServicesScreen());

    await tester.enterText(find.byType(TextField), 'cash');
    await tester.pump();
    expect(find.text('Cash-In'), findsOneWidget);
    expect(find.text('Cash-Out'), findsOneWidget);
    expect(find.text('Balance Inquiry'), findsNothing);

    await tester.enterText(find.byType(TextField), '702');
    await tester.pump();
    expect(find.text('Balance Inquiry'), findsOneWidget);
    expect(find.text('Cash-In'), findsNothing);
  });

  testWidgets('operations switched off remotely are not listed', (
    tester,
  ) async {
    useTallScreen(tester);
    await pumpScreen(
      tester,
      const ServicesScreen(),
      overrides: [
        currentConfigProvider.overrideWithValue(
          testConfig(features: {'cash_out': false}),
        ),
      ],
    );

    expect(find.text('Cash-Out'), findsNothing);
    expect(find.text('Cash-In'), findsOneWidget);
  });
}
