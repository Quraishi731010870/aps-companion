import 'package:afghan_emi/src/features/payments/domain/card_details.dart';
import 'package:afghan_emi/src/features/payments/presentation/view_models/linked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

Future<void> _pumpWithLinkedCard(WidgetTester tester) async {
  await pumpApp(tester);
  await containerOf(tester)
      .read(linkedCardProvider.notifier)
      .link(
        const CardDetails(
          pan: '6037991234561234',
          expiryMonth: 12,
          expiryYear: 2029,
          holderName: 'Demo Customer 001',
        ),
      );
  await tester.pump();
}

void main() {
  testWidgets('tapping a linked card shows its masked details', (tester) async {
    await _pumpWithLinkedCard(tester);

    await tester.tap(find.text('APS card 6037 99** **** 1234'));
    await tester.pumpAndSettle();

    expect(find.text('Your linked card'), findsOneWidget);
    expect(find.text('6037 99** **** 1234'), findsOneWidget);
    expect(find.text('Link your card'), findsNothing);
    expect(find.textContaining('6037991234561234'), findsNothing);
  });

  testWidgets('Replace card opens the link form', (tester) async {
    await _pumpWithLinkedCard(tester);

    await tester.tap(find.text('APS card 6037 99** **** 1234'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Replace card'));
    await tester.pumpAndSettle();

    expect(find.text('Your linked card'), findsNothing);
    expect(find.text('Link your card'), findsOneWidget);
  });
}
