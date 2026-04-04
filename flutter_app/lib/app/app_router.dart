import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../features/auth/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../models/farmer_model.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../services/farmer_service.dart';

class AppRouter extends StatefulWidget {
  final AuthService? authService;

  const AppRouter({super.key, this.authService});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final AuthService _authService;
  late final FarmerService _farmerService;
  bool _showSplash = true;
  bool _showRegister = false;
  bool _onboardingJustCompleted = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _farmerService = FarmerService();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        authService: _authService,
        onFinished: (_) {
          if (!mounted) return;
          setState(() => _showSplash = false);
        },
      );
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data;

        if (firebaseUser != null) {
          // Clear register flag once authenticated
          if (_showRegister) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showRegister = false);
            });
          }

          return FutureBuilder<FarmerModel?>(
            future: _farmerService.getFarmerProfile(firebaseUser.uid),
            builder: (context, farmerSnapshot) {
              if (farmerSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (farmerSnapshot.hasError) {
                return _ErrorView(
                  message:
                      farmerSnapshot.error?.toString() ??
                      'Failed to load your profile.',
                  onRetry: () => setState(() {}),
                );
              }

              // If the Firestore profile doc doesn't exist yet, build a minimal
              // FarmerModel from the Firebase Auth user so the app still opens.
              final farmer =
                  farmerSnapshot.data ??
                  FarmerModel(
                    uid: firebaseUser.uid,
                    name: firebaseUser.displayName?.trim().isNotEmpty == true
                        ? firebaseUser.displayName!.trim()
                        : 'Farmer',
                    phone: '',
                    email: firebaseUser.email ?? '',
                    aadhaarLast4: '',
                    createdAt: null,
                  );

              return FutureBuilder<bool>(
                future: OnboardingScreen.isCompleted(),
                builder: (context, onboardingSnapshot) {
                  if (onboardingSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final completed = onboardingSnapshot.data ?? false;
                  if (!completed && !_onboardingJustCompleted) {
                    return OnboardingScreen(
                      onCompleted: () {
                        if (!mounted) return;
                        setState(() => _onboardingJustCompleted = true);
                      },
                    );
                  }

                  return HomeScreen(farmer: farmer, authService: _authService);
                },
              );
            },
          );
        }

        // ── Unauthenticated ────────────────────────────────────────────────
        if (_showRegister) {
          return RegisterPage(
            authService: _authService,
            onRegistered: (_) async {
              if (mounted) setState(() {});
            },
            onLoginTap: () => setState(() => _showRegister = false),
          );
        }

        return LoginScreen(
          authService: _authService,
          onLoggedIn: (_) async => setState(() {}),
          onRegisterTap: () => setState(() => _showRegister = true),
        );
      },
    );
  }
}

/// Full-screen error state with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load your profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
