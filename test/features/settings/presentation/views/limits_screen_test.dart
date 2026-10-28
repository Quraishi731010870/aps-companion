import 'package:afghan_emi/src/features/settings/domain/app_settings.dart';
import 'package:afghan_emi/src/features/settings/presentation/view_models/settings.dart';
import 'package:afghan_emi/src/features/settings/presentation/views/limits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Future<void> _enterLimits(
  WidgetTester tester, {
  required String daily,
  required String monthly,
  required String count,
}) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Daily amount limit'),
    daily,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Monthly amount limit'),
    monthly,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Daily transaction count'),
    count,
  );
  await tester.tap(find.text('Save limits'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fields start with the current limits', (tester) async {
    await pumpScreen(tester, const LimitsScreen());

    expect(find.text('50000'), findsOneWidget);
    expect(find.text('250000'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('valid limits are saved to settings', (tester) async {
    await pumpScreen(tester, const LimitsScreen());

    await _enterLimits(tester, daily: '1000', monthly: '5000', count: '3');

    expect(find.text('Settings saved'), findsOneWidget);
    expect(
      containerOf(tester).read(settingsProvider).limits,
      const TransactionLimits(daily: 1000, monthly: 5000, dailyCount: 3),
    );
  });

  testWidgets('monthly below daily is rejected', (tester) async {
    await pumpScreen(tester, const LimitsScreen());

    await _enterLimits(tester, daily: '5000', monthly: '1000', count: '3');

    expect(
      find.text('Enter valid limits; monthly must be at least daily.'),
      findsOneWidget,
    );
    expect(
      containerOf(tester).read(settingsProvider).limits,
      const TransactionLimits(),
    );
  });
}
