import 'package:agrisentinel/app/app_shell.dart';
import 'package:agrisentinel/features/auth/auth_models.dart';
import 'package:agrisentinel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('bottom navigation switches between major pages', (tester) async {
    final user = const AppUser(
      name: 'Rajan Pillai',
      email: 'demo@agrisentinel.app',
      region: 'Palakkad District, Kerala',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AppShell(
          user: user,
          authService: buildTestAuthService(),
          onUserUpdated: (_) async {},
          onLogout: () async {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Claims'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Claims History'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Help & support'), findsOneWidget);
  });
}
