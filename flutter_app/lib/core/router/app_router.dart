import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  redirect: (context, state) {
    final auth      = context.read<AuthProvider>();
    final loggedIn  = auth.isLoggedIn;
    final onSplash  = state.matchedLocation == '/splash';
    final onLogin   = state.matchedLocation == '/login';

    if (onSplash) return null;
    if (!loggedIn && !onLogin) return '/login';
    if (loggedIn  &&  onLogin) return '/home';
    return null;
  },
);
