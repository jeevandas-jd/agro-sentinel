import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/auth_service.dart';
import 'app/app_router.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:agrisentinel/services/tutorial_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await dotenv.load(fileName: ".env");
  await TutorialService().init();
  runApp(const AgriSentinelApp());
}

/// InheritedNotifier that exposes [LocaleProvider] to the widget tree.
class AppLocaleScope extends InheritedNotifier<LocaleProvider> {
  const AppLocaleScope({
    super.key,
    required LocaleProvider super.notifier,
    required super.child,
  });

  static LocaleProvider of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLocaleScope>()!
        .notifier!;
  }
}

class AgriSentinelApp extends StatefulWidget {
  final AuthService? authService;

  const AgriSentinelApp({super.key, this.authService});

  @override
  State<AgriSentinelApp> createState() => _AgriSentinelAppState();
}

class _AgriSentinelAppState extends State<AgriSentinelApp> {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChanged);
    _localeProvider.dispose();
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      notifier: _localeProvider,
      child: MaterialApp(
        title: 'AgriSentinel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: _localeProvider.locale,
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('ml'),
          Locale('ta'),
          Locale('te'),
          Locale('gu'),
          Locale('ur'),
          Locale('kn'),
          Locale('pa'),
          Locale('mr'),
          Locale('or'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AppRouter(authService: widget.authService),
      ),
    );
  }
}
