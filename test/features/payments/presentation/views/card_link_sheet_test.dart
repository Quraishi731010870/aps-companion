import 'package:afghan_emi/src/features/payments/presentation/view_models/linked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Finder get _linkButton => find.widgetWithText(FilledButton, 'Link card');

Future<void> _openSheet(WidgetTester tester) async {
  await pumpApp(tester);
  await tester.tap(find.text('Link card'));
  await tester.pumpAndSettle();
  expect(find.text('Link your card'), findsOneWidget);
}

void main() {
  testWidgets('rejects an invalid card number and expiry', (tester) async {
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Card number'),
      '1234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expiry MM/YY'),
      '13/30',
    );
    await tester.tap(_linkButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid card number'), findsOneWidget);
    expect(find.text('Use MM/YY'), findsOneWidget);
    expect(containerOf(tester).read(linkedCardProvider).value, isNull);
  });

  testWidgets('a valid card is linked, masked and shown on Home', (
    tester,
  ) async {
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Card number'),
      '6037991234561234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expiry MM/YY'),
      '12/29',
    );
    await tester.tap(_linkButton);
    await tester.pumpAndSettle();

    expect(find.text('Link your card'), findsNothing);
    expect(find.text('Card linked successfully for testing.'), findsOneWidget);
    expect(find.text('APS card 6037 99** **** 1234'), findsOneWidget);
    expect(find.textContaining('6037991234561234'), findsNothing);
    expect(
      containerOf(tester).read(linkedCardProvider).value?.maskedPan,
      '603799******1234',
    );
  });
}
