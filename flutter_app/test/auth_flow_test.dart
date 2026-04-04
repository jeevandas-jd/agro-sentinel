import 'package:agrisentinel/features/auth/auth_models.dart';
import 'package:agrisentinel/features/auth/login_page.dart';
import 'package:agrisentinel/features/auth/register_page.dart';
import 'package:agrisentinel/theme/app_theme.dart';
import 'package:agrisentinel/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('login succeeds with demo credentials', (tester) async {
    AppUser? loggedInUser;
    final authService = buildTestAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: LoginPage(
          authService: authService,
          onLoggedIn: (user) async {
            loggedInUser = user;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@agrisentinel.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'demo123');
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(loggedInUser, isNotNull);
    expect(loggedInUser!.email, 'demo@agrisentinel.app');
  });

  testWidgets('register validates and submits', (tester) async {
    AppUser? registeredUser;
    final authService = buildTestAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: RegisterPage(
          authService: authService,
          onRegistered: (user) async {
            registeredUser = user;
          },
          onLoginTap: () {},
        ),
      ),
    );

    await tester.tap(find.text('Register'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Farmer');
    await tester.enterText(find.byType(TextFormField).at(1), 'Olive Hills');
    await tester.enterText(find.byType(TextFormField).at(2), 'test@farm.app');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret12');
    await tester.enterText(find.byType(TextFormField).at(4), 'secret12');

    final registerButton = find.widgetWithText(AppPrimaryButton, 'Register');
    await tester.ensureVisible(registerButton.first);
    await tester.tap(registerButton.first);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(registeredUser, isNotNull);
    expect(registeredUser!.name, 'Test Farmer');
    expect(registeredUser!.region, 'Olive Hills');
  });
}
