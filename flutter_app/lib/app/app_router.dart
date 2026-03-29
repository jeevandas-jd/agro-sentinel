import 'package:flutter/material.dart';

import '../features/auth/auth_models.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../screens/splash_screen.dart';
import 'app_shell.dart';
import 'session_state.dart';

class AppRouter extends StatefulWidget {
  final SessionState sessionState;

  const AppRouter({super.key, required this.sessionState});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final AuthService _authService = AuthService();
  bool _showRegister = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.sessionState.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }
    setState(() {
      _ready = true;
    });
  }

  Future<void> _onAuthenticated(DemoUser user) async {
    await widget.sessionState.setSession(user);
  }

  Future<void> _onUserUpdated(DemoUser user) async {
    await widget.sessionState.updateCurrentUser(user);
  }

  Future<void> _onLogout() async {
    await widget.sessionState.clearSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _showRegister = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SplashScreen(standaloneMode: true);
    }

    return AnimatedBuilder(
      animation: widget.sessionState,
      builder: (context, _) {
        if (widget.sessionState.isAuthenticated) {
          return AppShell(
            user: widget.sessionState.currentUser!,
            authService: _authService,
            onUserUpdated: _onUserUpdated,
            onLogout: _onLogout,
          );
        }

        if (_showRegister) {
          return RegisterPage(
            authService: _authService,
            onRegistered: _onAuthenticated,
            onLoginTap: () {
              setState(() {
                _showRegister = false;
              });
            },
          );
        }

        return LoginPage(
          authService: _authService,
          onLoggedIn: _onAuthenticated,
          onRegisterTap: () {
            setState(() {
              _showRegister = true;
            });
          },
        );
      },
    );
  }
}
