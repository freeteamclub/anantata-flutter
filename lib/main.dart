import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/screens/splash/splash_screen.dart';
import 'package:anantata/screens/home/home_screen.dart';
import 'package:anantata/screens/auth/auth_screen.dart';

/// Anantata Career Coach
/// Версія: 2.1.0 - Fixed routes conflict
/// Дата: 14.12.2025
///
/// AI-powered career development application

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Завантаження змінних середовища
  await dotenv.load(fileName: ".env");

  // Ініціалізація Supabase
  await SupabaseService.initialize();

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

      // Початковий екран
      home: const AppStartup(),
    );
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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Показуємо splash на 2 секунди
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Показуємо екран авторизації якщо не авторизований
        _showAuth = !_supabase.isAuthenticated;
      });
    }
  }

  void _onAuthSuccess() {
    setState(() {
      _showAuth = false;
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