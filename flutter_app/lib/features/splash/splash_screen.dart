import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    context.go(auth.isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // NDVI rainbow strip at top
          SizedBox(
            height: 6,
            child: Row(
              children: [
                Color(0xFF8B0000),
                Color(0xFFD44000),
                Color(0xFFFF8C00),
                Color(0xFFFFD700),
                Color(0xFFADFF2F),
                Color(0xFF00C800),
                Color(0xFF006400),
              ].map((c) => Expanded(child: Container(color: c))).toList(),
            ),
          ),
          // Main content
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: AppColors.accent,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.tagline,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
