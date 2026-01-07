import 'package:flutter/material.dart';

/// Тема додатку Anantata
/// Версія: 3.0.0 - Перехід на системний шрифт Roboto
/// Дата: 07.01.2026
///
/// Шрифти:
/// - Roboto: Системний шрифт Material Design для всього тексту

class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  // КОЛЬОРИ
  // ═══════════════════════════════════════════════════════════════

  /// Основний фіолетовий колір бренду
  static const Color primaryColor = Color(0xFF413659);

  /// Білий колір
  static const Color whiteColor = Color(0xFFFFFFFF);

  /// Фон сторінок
  static const Color backgroundColor = Color(0xFFF5F5F5);

  /// Основний текст
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Вторинний текст
  static const Color textSecondary = Color(0xFF666666);

  /// Зелений для прогресу
  static const Color successColor = Color(0xFF4CAF50);

  /// Помаранчевий для пропущених
  static const Color warningColor = Color(0xFFFF9800);

  /// Червоний для помилок
  static const Color errorColor = Color(0xFFF44336);

  // ═══════════════════════════════════════════════════════════════
  // ШРИФТИ
  // ═══════════════════════════════════════════════════════════════

  /// Системний шрифт (Roboto на Android, SF Pro на iOS)
  static const String fontFamily = 'Roboto';

  /// Аліаси для сумісності
  static const String fontHeading = fontFamily;
  static const String fontAccent = fontFamily;
  static const String fontBody = fontFamily;

  // ═══════════════════════════════════════════════════════════════
  // ТЕКСТОВІ СТИЛІ
  // ═══════════════════════════════════════════════════════════════

  /// Великий заголовок (H1)
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  /// Середній заголовок (H2)
  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontHeading,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
  );

  /// Малий заголовок (H3)
  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontHeading,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  /// Заголовок картки
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontHeading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Акцентний текст (кнопки, бейджі)
  static const TextStyle accentText = TextStyle(
    fontFamily: fontAccent,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: whiteColor,
    letterSpacing: 0.5,
  );

  /// Акцентний текст великий
  static const TextStyle accentLarge = TextStyle(
    fontFamily: fontAccent,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: whiteColor,
    letterSpacing: 0.5,
  );

  /// Основний текст
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  /// Основний текст середній
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );

  /// Малий текст
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  /// Підпис / Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  /// Текст кнопки
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontAccent,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );

  /// Текст малої кнопки
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontAccent,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.3,
  );

  // ═══════════════════════════════════════════════════════════════
  // ТЕМА ДОДАТКУ
  // ═══════════════════════════════════════════════════════════════

  /// Світла тема (основна)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: fontBody,

      // ColorScheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: whiteColor,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: whiteColor,
        ),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Картки
      cardTheme: CardThemeData(
        color: whiteColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: whiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          color: textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: fontBody,
          color: Colors.grey[400],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: whiteColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontSize: 12,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        elevation: 4,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return successColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(whiteColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER МЕТОДИ
  // ═══════════════════════════════════════════════════════════════

  /// Match Score колір залежно від значення
  static Color getMatchScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Зелений
    if (score >= 60) return const Color(0xFF8BC34A); // Світло-зелений
    if (score >= 40) return const Color(0xFFFFC107); // Жовтий
    if (score >= 20) return const Color(0xFFFF9800); // Помаранчевий
    return const Color(0xFFF44336); // Червоний
  }

  /// Статус колір
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return successColor;
      case 'skipped':
        return warningColor;
      case 'in_progress':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }
}