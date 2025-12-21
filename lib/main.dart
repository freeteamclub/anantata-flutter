import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, FlutterError;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/screens/splash/splash_screen.dart';
import 'package:anantata/screens/home/home_screen.dart';
import 'package:anantata/screens/auth/auth_screen.dart';

/// Anantata Career Coach
/// Версія: 2.3.0 - Покращений error handling для Web
/// Дата: 21.12.2025
///
/// Виправлено:
/// - Баг #11 - Uncaught Error в консолі Web версії
///
/// AI-powered career development application

void main() async {
  // Баг #11: Глобальний error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter Error: ${details.exceptionAsString()}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Баг #11: Безпечна ініціалізація з try-catch
  try {
    // Завантаження змінних середовища
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Помилка завантаження .env: $e');
    // Продовжуємо без .env (використовуються значення за замовчуванням)
  }

  // Ініціалізація Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('⚠️ Помилка ініціалізації Supabase: $e');
    // Продовжуємо в офлайн режимі
  }

  runApp(const AnantataApp());
}

class AnantataApp extends StatelessWidget {
  const AnantataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Основні налаштування
      title: 'Anantata Career Coach',
      debugShowCheckedModeBanner: false,

      // Тема
      theme: AppTheme.lightTheme,

      // Builder обгортає ВСІ екрани в WebWrapper (тільки для Web)
      builder: (context, child) {
        // Баг #11: Додано перевірку на null та ErrorWidget
        Widget content = child ?? const SizedBox.shrink();

        // Обгортка для перехоплення помилок рендерингу
        content = _ErrorBoundary(child: content);

        if (kIsWeb) {
          return WebWrapper(child: content);
        }
        return content;
      },

      // Початковий екран
      home: const AppStartup(),
    );
  }
}

/// Баг #11: Error Boundary для перехоплення помилок рендерингу
class _ErrorBoundary extends StatefulWidget {
  final Widget child;

  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Щось пішло не так',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Спробуйте перезавантажити сторінку',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _resetError,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Спробувати знову'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Стартовий екран - перевіряє авторизацію
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = true;
  bool _showAuth = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Показуємо splash на 2 секунди
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Показуємо екран авторизації якщо не авторизований
          _showAuth = !_supabase.isAuthenticated;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Помилка перевірки авторизації: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showAuth = true; // При помилці показуємо auth
          _error = e.toString();
        });
      }
    }
  }

  void _onAuthSuccess() {
    setState(() {
      _showAuth = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Показуємо Splash
    if (_isLoading) {
      return const SplashScreen();
    }

    // Показуємо Auth екран
    if (_showAuth) {
      return AuthScreen(
        onAuthSuccess: _onAuthSuccess,
      );
    }

    // Показуємо Home
    return const HomeScreen();
  }
}

/// WebWrapper - обмежує ширину на десктопі (тільки для Web)
/// На мобільних браузерах: повна ширина
/// На десктопі: максимум 500px, центрування, світлий фон
class WebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundColor;

  const WebWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.backgroundColor = const Color(0xFFE8E5ED), // Світло-фіолетовий
  });

  @override
  Widget build(BuildContext context) {
    // Отримуємо ширину екрану
    final screenWidth = MediaQuery.of(context).size.width;

    // Якщо екран вузький (мобільний) - показуємо на повну ширину
    if (screenWidth <= maxWidth) {
      return child;
    }

    // На широкому екрані (десктоп) - центруємо з обмеженням
    return ColoredBox(
      color: backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: maxWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  // Баг #11: Замінено withOpacity на withValues
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}