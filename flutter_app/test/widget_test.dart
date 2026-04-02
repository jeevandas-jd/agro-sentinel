import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel/main.dart';
import 'test_auth_service.dart';

void main() {
  testWidgets('AgriSentinel app smoke test', (WidgetTester tester) async {
    final authService = buildTestAuthService();
    await tester.pumpWidget(AgriSentinelApp(authService: authService));
    expect(find.byType(AgriSentinelApp), findsOneWidget);
  });
}
