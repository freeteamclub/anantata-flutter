import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';

/// Splash Screen Anantata
/// Версія: 1.2 - Виправлено deprecated withOpacity
/// Дата: 24.12.2025
///
/// Виправлено:
/// - P3 #2 - Замінено withOpacity на withValues(alpha:) для Web сумісності
/// - Видалено власну навігацію (конфлікт з AppStartup в main.dart)
/// - Тепер це чистий UI компонент

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Навігація тепер керується з main.dart -> AppStartup
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Назва
              const Text(
                '100StepsCareer',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Bitter',
                ),
              ),
              const SizedBox(height: 8),
              // Слоган
              Text(
                'AI Career Coach',
                style: TextStyle(
                  fontSize: 16,
                  // P3 #2: Виправлено withOpacity → withValues
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'NunitoSans',
                ),
              ),
              const SizedBox(height: 48),
              // Індикатор завантаження
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    // P3 #2: Виправлено withOpacity → withValues
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
