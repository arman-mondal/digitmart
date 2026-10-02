import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fix or Bid smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('FIX OR BID'),
          ),
        ),
      ),
    );
    expect(find.text('FIX OR BID'), findsOneWidget);
  });
}
