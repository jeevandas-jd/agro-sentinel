import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel/main.dart';
import 'test_auth_service.dart';

void main() {
  testWidgets('agroSentinel app smoke test', (WidgetTester tester) async {
    final authService = buildTestAuthService();
    await tester.pumpWidget(AgroSentinelApp(authService: authService));
    expect(find.byType(AgroSentinelApp), findsOneWidget);
  });
}
