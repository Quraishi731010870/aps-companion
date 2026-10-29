import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('renders the wallet dashboard and transaction services', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('Transaction services'), findsOneWidget);
    expect(find.text('Cash in'), findsOneWidget);
    expect(find.text('Bank push'), findsOneWidget);
  });

  testWidgets('profile opens a receive QR for the wallet identifier', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My wallet QR'));
    await tester.pumpAndSettle();

    expect(find.text('Receive to your wallet'), findsOneWidget);
    expect(find.text(testWallet.id), findsOneWidget);
    expect(find.textContaining('payment backend is connected'), findsOneWidget);
  });

  testWidgets('Google Sheets clearly reports missing build configuration', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Google Sheets'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Google Sheets'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not configured.'), findsOneWidget);
    expect(find.text('Connect Google Sheets'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNull,
    );
  });
}
