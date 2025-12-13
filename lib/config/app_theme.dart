import 'package:flutter/material.dart';
import 'package:anantata/xelauikit/xela_color.dart';

/// Тема додатку Anantata
/// Версія: 1.0
/// Дата: 12.12.2025

class AppTheme {
  AppTheme._();

  // ============================================
  // КОЛЬОРИ БРЕНДУ
  // ============================================

  static const Color primaryColor = XelaColor.Ananta;        // #413659
  static const Color primaryLight = XelaColor.Ananta6;       // #7f6b9e
  static const Color primaryDark = XelaColor.Ananta1;        // #1e1829
  static const Color backgroundColor = XelaColor.Ananta12;   // #f8f6fb
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = XelaColor.Red;
  static const Color successColor = XelaColor.Green;
  static const Color warningColor = XelaColor.Orange;

  // ============================================
  // ТЕКСТОВІ КОЛЬОРИ
  // ============================================

  static const Color textPrimary = XelaColor.Gray1;          // Основний текст
  static const Color textSecondary = XelaColor.Gray5;        // Вторинний текст
  static const Color textHint = XelaColor.Gray7;             // Підказки
  static const Color textOnPrimary = Colors.white;           // Текст на primary

  // ============================================
  // РОЗМІРИ ШРИФТІВ
  // ============================================

  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 24.0;
  static const double fontSizeXXL = 32.0;
  static const double fontSizeHero = 48.0;

  // ============================================
  // ВІДСТУПИ
  // ============================================

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // ============================================
  // РАДІУСИ ЗАОКРУГЛЕНЬ
  // ============================================

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // ============================================
  // ТІНІ
  // ============================================

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // ТЕКСТОВІ СТИЛІ
  // ============================================

  static const TextStyle headingLarge = TextStyle(
    fontSize: fontSizeXXL,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: fontSizeL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSizeM,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSizeS,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontFamily: 'NunitoSans',
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: fontSizeM,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    fontFamily: 'NunitoSans',
  );

  // ============================================
  // ГОЛОВНА ТЕМА ДОДАТКУ
  // ============================================

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'NunitoSans',

    // Кольорова схема
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: textOnPrimary,
      surface: surfaceColor,
      error: errorColor,
    ),

    // Scaffold
    scaffoldBackgroundColor: backgroundColor,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: fontSizeL,
        fontWeight: FontWeight.w600,
        fontFamily: 'NunitoSans',
      ),
    ),

    // Кнопки
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: buttonText,
      ),
    ),

    // Outlined кнопки
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    ),

    // Text кнопки
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimary,
    ),

    // Input поля
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingM,
        vertical: paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: XelaColor.Gray9),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: XelaColor.Gray9),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: TextStyle(color: textHint),
    ),

    // Картки
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: XelaColor.Gray10,
      thickness: 1,
    ),
  );
}