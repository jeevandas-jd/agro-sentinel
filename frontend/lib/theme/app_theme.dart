import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF8FAF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBright = Color(0xFFF2F7EB);
  static const Color inputFill = Color(0xFFF0F4EA);

  // Brand greens
  static const Color primary = Color(0xFF7CC22A);
  static const Color primaryDark = Color(0xFF5A9E1A);
  static const Color primaryLight = Color(0xFFB5E378);
  static const Color accent = Color(0xFF9DD84A);
  static const Color accentSoft = Color(0xFFD4EDAB);
  static const Color oliveLight = Color(0xFFE8F5D0);

  // Warm highlight (kept for weather icons etc.)
  static const Color highlightWarm = Color(0xFFFFB830);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnGreen = Color(0xFFFFFFFF);

  // Alerts
  static const Color alertHigh = Color(0xFFEF4444);
  static const Color alertMedium = Color(0xFFF59E0B);
  static const Color alertLow = Color(0xFFFBBF24);
  static const Color alertVerified = Color(0xFF3B82F6);

  // Misc
  static const Color border = Color(0xFFE5EADC);
  static const Color borderStrong = Color(0xFFCDD8BC);
  static const Color scanLine = Color(0x557CC22A);
  static const Color ndviPositive = Color(0xFF4CAF50);
  static const Color ndviNegative = Color(0xFFEF4444);

  // Dark overlay (for image overlays)
  static const Color darkOverlay = Color(0xCC1A2416);
}

class AppRadii {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 20;
  static const double xl = 28;
  static const double pill = 100;
}

class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
}

class AppShadows {
  static final List<BoxShadow> base = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.highlightWarm,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black12,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          fontSize: 48,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentSoft,
        elevation: 0,
        shadowColor: Colors.black12,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textMuted,
        errorStyle: const TextStyle(color: AppColors.alertHigh, fontSize: 11),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
