import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MenuGrid shows item names', (tester) async {
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('Cappuccino'), findsOneWidget);
  });
}
