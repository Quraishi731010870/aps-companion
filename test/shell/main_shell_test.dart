import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('starts on Home', (tester) async {
    await pumpApp(tester);

    expect(find.text('Available balance'), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });

  testWidgets('each tab shows its own page', (tester) async {
    await pumpApp(tester);

    final pages = {
      'Services': 'EMI services',
      'Activity': 'Audit-friendly payment history and receipts',
      'Profile': 'My wallet QR',
      'Home': 'Available balance',
    };
    for (final MapEntry(key: tab, value: marker) in pages.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(marker), findsOneWidget, reason: '$tab tab');
    }
  });

  testWidgets('the notifications button opens Activity', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('View transaction history'));
    await tester.pumpAndSettle();

    expect(
      find.text('Audit-friendly payment history and receipts'),
      findsOneWidget,
    );
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('tabs keep their state when switching away and back', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'cash');

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('cash'), findsOneWidget);
  });
}
