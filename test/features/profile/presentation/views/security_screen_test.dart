import 'package:afghan_emi/src/features/profile/presentation/views/security_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Future<void> _open(WidgetTester tester, String action) async {
  await pumpScreen(tester, const SecurityScreen());
  await tester.tap(find.text(action).first);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _fill(WidgetTester tester, String label, String value) =>
    tester.enterText(find.widgetWithText(TextFormField, label), value);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a PIN must be four digits', (tester) async {
    await _open(tester, 'Change PIN');

    await _fill(tester, 'Current PIN', '12');
    await _fill(tester, 'New PIN', '5678');
    await _save(tester);

    expect(find.text('Enter 4 digits'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('a valid PIN change closes cleanly and confirms', (tester) async {
    await _open(tester, 'Change PIN');

    await _fill(tester, 'Current PIN', '1234');
    await _fill(tester, 'New PIN', '5678');
    await _save(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('PIN changed successfully'), findsOneWidget);
    // Regression: controllers used to be disposed while the dialog was
    // still animating out.
    expect(tester.takeException(), isNull);
  });

  testWidgets('passwords must be strong and match', (tester) async {
    await _open(tester, 'Change password');

    await _fill(tester, 'New password', 'weak');
    await _fill(tester, 'Confirm password', 'other');
    await _save(tester);

    expect(
      find.text('Use 8+ characters, upper/lowercase and a number'),
      findsOneWidget,
    );
    expect(find.text('Passwords do not match'), findsOneWidget);

    await _fill(tester, 'New password', 'Strong1pass');
    await _fill(tester, 'Confirm password', 'Strong1pass');
    await _save(tester);

    expect(find.text('Password changed successfully'), findsOneWidget);
  });

  testWidgets('cancel closes without confirming', (tester) async {
    await _open(tester, 'Change PIN');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('PIN changed successfully'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
