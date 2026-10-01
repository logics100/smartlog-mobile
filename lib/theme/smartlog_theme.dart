import 'package:flutter/material.dart';

class SmartLogColors {
  SmartLogColors._();

  static const navy = Color(0xFF062B63);
  static const deepBlue = Color(0xFF06499C);
  static const blue = Color(0xFF087BEA);
  static const cyan = Color(0xFF13B9EF);

  static const background = Color(0xFFF5F9FD);
  static const paleBlue = Color(0xFFEDF7FF);
  static const card = Colors.white;

  static const text = Color(0xFF17324D);
  static const muted = Color(0xFF667D91);
  static const border = Color(0xFFDBE7F2);

  static const success = Color(0xFF16875D);
  static const warning = Color(0xFFE99A16);
  static const danger = Color(0xFFD94A4A);
}

class SmartLogTheme {
  SmartLogTheme._();

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SmartLogColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: SmartLogColors.blue,
          secondary: SmartLogColors.cyan,
          surface: SmartLogColors.card,
          error: SmartLogColors.danger,
          onPrimary: Colors.white,
          onSurface: SmartLogColors.text,
          outline: SmartLogColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SmartLogColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: SmartLogColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: SmartLogColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: SmartLogColors.muted),
        hintStyle: const TextStyle(color: SmartLogColors.muted),
        prefixIconColor: SmartLogColors.blue,
        suffixIconColor: SmartLogColors.muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SmartLogColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SmartLogColors.blue, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SmartLogColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: SmartLogColors.danger,
            width: 1.7,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartLogColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SmartLogColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SmartLogColors.blue,
          side: const BorderSide(color: SmartLogColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SmartLogColors.cyan,
        linearTrackColor: SmartLogColors.paleBlue,
      ),

      dividerTheme: const DividerThemeData(color: SmartLogColors.border),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SmartLogColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SmartLogColors.blue,
        foregroundColor: Colors.white,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: SmartLogColors.paleBlue,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? SmartLogColors.blue
                : SmartLogColors.muted,
          ),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: SmartLogColors.navy,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: SmartLogColors.navy,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: SmartLogColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: SmartLogColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: SmartLogColors.text,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: SmartLogColors.text),
        bodyMedium: TextStyle(color: SmartLogColors.text),
      ),
    );
  }
}
