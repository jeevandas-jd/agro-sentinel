import 'package:agrisentinel/app/app_shell.dart';
import 'package:agrisentinel/features/auth/auth_models.dart';
import 'package:agrisentinel/features/auth/auth_service.dart';
import 'package:agrisentinel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('profile page shows identity and handles logout', (tester) async {
    bool loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: _ProfileHost(
          onLogout: () {
            loggedOut = true;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rajan Pillai'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(loggedOut, isTrue);
  });
}

class _ProfileHost extends StatefulWidget {
  final VoidCallback onLogout;

  const _ProfileHost({required this.onLogout});

  @override
  State<_ProfileHost> createState() => _ProfileHostState();
}

class _ProfileHostState extends State<_ProfileHost> {
  AppUser _user = const AppUser(
    name: 'Rajan Pillai',
    email: 'demo@agrisentinel.app',
    region: 'Palakkad District, Kerala',
  );

  @override
  Widget build(BuildContext context) {
    return AppShell(
      user: _user,
      authService: AuthService(),
      onUserUpdated: (user) async {
        setState(() => _user = user);
      },
      onLogout: () async {
        widget.onLogout();
      },
    );
  }
}
