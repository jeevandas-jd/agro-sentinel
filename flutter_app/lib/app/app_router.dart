import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../features/auth/auth_models.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../services/report_demo_repository.dart';

class AppRouter extends StatefulWidget {
  final AuthService? authService;

  const AppRouter({super.key, this.authService});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final AuthService _authService;
  bool _showSplash = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        authService: _authService,
        onFinished: (_) {
          if (!mounted) {
            return;
          }
          setState(() => _showSplash = false);
        },
      );
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data;
        if (firebaseUser != null) {
          if (_showRegister) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _showRegister = false);
              }
            });
          }
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
              final AppUser user = profileSnapshot.data!;
              final farmer = ReportDemoRepository.farmerFor(
                uid: firebaseUser.uid,
                displayName: user.name,
                email: user.email,
              );
              final farm = ReportDemoRepository.farmFor(farmer.uid);
              final events = ReportDemoRepository.eventsFor(
                farmerUid: farmer.uid,
                farmId: farm.id,
              );
              return HomeScreen(
                farmer: farmer,
                farm: farm,
                events: events,
                authService: _authService,
              );
            },
          );
        }

        if (_showRegister) {
          return RegisterPage(
            authService: _authService,
            onRegistered: (_) async {
              if (mounted) {
                setState(() {});
              }
            },
            onLoginTap: () {
              setState(() => _showRegister = false);
            },
          );
        }

        return LoginScreen(
          authService: _authService,
          onLoggedIn: (_) async {
            setState(() {});
          },
          onRegisterTap: () {
            setState(() => _showRegister = true);
          },
        );
      },
    );
  }
}
