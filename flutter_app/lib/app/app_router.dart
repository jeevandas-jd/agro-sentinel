import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../features/auth/auth_models.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../screens/splash_screen.dart';
import 'app_shell.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

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
    const minSplashDuration = Duration(milliseconds: 4200);
    final splashStartedAt = DateTime.now();
    final elapsed = DateTime.now().difference(splashStartedAt);
    if (elapsed < minSplashDuration) {
      await Future<void>.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _ready = true;
    });
  }

  Future<void> _onLogout() async {
    await _authService.signOut();
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

    return StreamBuilder<firebase_auth.User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data;
        if (firebaseUser != null) {
          return FutureBuilder<AppUser>(
            future: _authService.getCurrentUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (profileSnapshot.hasError || !profileSnapshot.hasData) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        profileSnapshot.error?.toString() ??
                            'Failed to load account details.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              return AppShell(
                user: profileSnapshot.data!,
                authService: _authService,
                onUserUpdated: (_) async {
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                },
                onLogout: _onLogout,
              );
            },
          );
        }

        if (_showRegister) {
          return RegisterPage(
            authService: _authService,
            onRegistered: (_) async {
              if (!mounted) {
                return;
              }
              setState(() => _showRegister = false);
            },
            onLoginTap: () {
              setState(() => _showRegister = false);
            },
          );
        }

        return LoginPage(
          authService: _authService,
          onLoggedIn: (_) async {
            if (!mounted) {
              return;
            }
            setState(() => _showRegister = false);
          },
          onRegisterTap: () {
            setState(() => _showRegister = true);
          },
        );
      },
    );
  }
}
