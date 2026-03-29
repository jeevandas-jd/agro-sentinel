import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_router.dart';
import 'app/session_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AgriSentinelApp());
}

class AgriSentinelApp extends StatelessWidget {
  const AgriSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = SessionState();
    return MaterialApp(
      title: 'AgriSentinel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: AppRouter(sessionState: sessionState),
    );
  }
}
