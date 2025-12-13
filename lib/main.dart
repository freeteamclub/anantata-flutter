import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/config/app_constants.dart';
import 'package:anantata/screens/splash/splash_screen.dart';
import 'package:anantata/screens/home/home_screen.dart';

/// Anantata Career Coach
/// Версія: 1.1.0
/// Дата: 13.12.2025
///
/// AI-powered career development application

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Завантаження змінних середовища
  await dotenv.load(fileName: ".env");

  runApp(const AnantataApp());
}

class AnantataApp extends StatelessWidget {
  const AnantataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Основні налаштування
      title: AppConstants.appFullName,
      debugShowCheckedModeBanner: false,

      // Тема
      theme: AppTheme.lightTheme,

      // Початковий маршрут
      initialRoute: AppConstants.routeSplash,

      // Маршрути
      routes: _buildRoutes(),

      // Обробка невідомих маршрутів
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const _NotFoundScreen(),
        );
      },
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppConstants.routeSplash: (context) => const SplashScreen(),
      AppConstants.routeHome: (context) => const HomeScreen(),

      // TODO: Додати інші екрани
      // AppConstants.routeOnboarding: (context) => const OnboardingScreen(),
      // AppConstants.routeLogin: (context) => const LoginScreen(),
      // AppConstants.routeRegister: (context) => const RegisterScreen(),
      // AppConstants.routeAssessment: (context) => const AssessmentScreen(),
      // AppConstants.routeResults: (context) => const ResultsScreen(),
      // AppConstants.routeChat: (context) => const ChatScreen(),
      // AppConstants.routeProfile: (context) => const ProfileScreen(),
      // AppConstants.routeSettings: (context) => const SettingsScreen(),
    };
  }
}

/// Екран для невідомих маршрутів
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сторінку не знайдено'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Сторінку не знайдено',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.routeHome,
                      (route) => false,
                );
              },
              child: const Text('На головну'),
            ),
          ],
        ),
      ),
    );
  }
}