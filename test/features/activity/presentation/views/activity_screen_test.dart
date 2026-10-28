import 'package:afghan_emi/src/features/activity/domain/activity_csv.dart';
import 'package:afghan_emi/src/features/activity/presentation/views/activity_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('shows every activity from the gateway', (tester) async {
    useTallScreen(tester);
    await pumpScreen(tester, const ActivityScreen());

    expect(find.text('Salary payment'), findsOneWidget);
    expect(find.text('Cash deposit'), findsOneWidget);
  });

  testWidgets('a load error shows retry instead of mock data', (tester) async {
    final gateway = FakePaymentGateway()..activitiesError = Exception('down');
    await pumpScreen(tester, const ActivityScreen(), gateway: gateway);

    expect(find.text('Your activity could not be loaded.'), findsOneWidget);
    expect(find.text('Salary payment'), findsNothing);

    gateway.activitiesError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Salary payment'), findsOneWidget);
  });

  testWidgets('export copies the loaded history as CSV', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpScreen(tester, const ActivityScreen());

    await tester.tap(find.byTooltip('Export CSV report'));
    await tester.pumpAndSettle();

    expect(copied, startsWith(ActivityCsv.header));
    expect(copied!.split('\n'), hasLength(6)); // header + 5 activities
    expect(find.text('CSV transaction report copied.'), findsOneWidget);
  });
}
