import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080E08),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AgriSentinelApp());
}

class AgriSentinelApp extends StatelessWidget {
  const AgriSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSentinel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // We use a custom builder so that on desktop the entire
      // navigation stack is rendered inside the phone frame.
      home: const DeviceFrameGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gate: decides whether to show the phone frame (desktop)
// or render the app directly (mobile / narrow screen).
// ─────────────────────────────────────────────────────────────
class DeviceFrameGate extends StatelessWidget {
  const DeviceFrameGate({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop → phone frame containing its OWN Navigator
          return const DesktopPhoneFrame();
        }
        // Mobile → normal full-screen app
        return const SplashScreen();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phone frame that owns a nested Navigator.
// Every Navigator.push / pushReplacement / pushNamed call that
// happens inside SplashScreen (and every subsequent screen)
// will target this nested Navigator, keeping all screens
// contained within the frame.
// ─────────────────────────────────────────────────────────────
class DesktopPhoneFrame extends StatelessWidget {
  const DesktopPhoneFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Phone shell ──────────────────────────────────
            Container(
              width: 380,
              height: 780,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.black,
                border: Border.all(
                  color: Colors.grey.shade800,
                  width: 6,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 30,
                    color: Colors.black54,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                // Force mobile-like MediaQuery so every screen
                // inside thinks it is on a 380×780 phone.
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(380, 780),
                    devicePixelRatio: 2.0,
                    padding: const EdgeInsets.only(top: 40, bottom: 20),
                    viewInsets: EdgeInsets.zero,
                    viewPadding:
                        const EdgeInsets.only(top: 40, bottom: 20),
                  ),
                  // ── Nested Navigator ─────────────────────
                  // All navigation (push / pushReplacement /
                  // pushNamed) inside the app will use THIS
                  // navigator, so screens never escape the frame.
                  child: Navigator(
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const SplashScreen(),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "AgriSentinel PWA Prototype\nResize browser for mobile experience",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
