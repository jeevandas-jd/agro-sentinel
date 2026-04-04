import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final void Function(bool signedIn) onFinished;

  const SplashScreen({
    super.key,
    required this.authService,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _bootstrapTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _bootstrap() {
    if (!mounted) {
      return;
    }

    _bootstrapTimer?.cancel();
    _bootstrapTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final signedIn = widget.authService.currentUser != null;
      widget.onFinished(signedIn);
    });
  }

  @override
  void dispose() {
    _bootstrapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bands = <Color>[
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFFFDD835),
      Color(0xFF43A047),
      Color(0xFF1E88E5),
      Color(0xFF3949AB),
      Color(0xFF8E24AA),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0F),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 18,
              child: Row(
                children: bands
                    .map(
                      (band) => Expanded(
                        child: ColoredBox(color: band),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: Colors.white, size: 72),
                    SizedBox(height: 14),
                    Text(
                      'AGRO SENTINEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'From Space to Soil',
                      style: TextStyle(
                        color: Color(0xFFB5E378),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
