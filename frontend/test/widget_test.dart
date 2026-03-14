import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel/main.dart';

void main() {
  testWidgets('AgriSentinel app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    expect(find.byType(AgriSentinelApp), findsOneWidget);
  });
}
