// Smoke test for ParkSmart.

import 'package:flutter_test/flutter_test.dart';

import 'package:parksmart/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkSmartApp());
    await tester.pump();

    // The app name should be visible on first paint.
    expect(find.text('ParkSmart'), findsWidgets);
  });
}
