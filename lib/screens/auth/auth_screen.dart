import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';

/// Екран авторизації
/// Версія: 1.1.0 - Fixed
/// Дата: 14.12.2025

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Слухаємо зміни авторизації (для web redirect)
    _supabase.authStateChanges.listen((state) {
      if (state.session != null && mounted) {
        widget.onAuthSuccess();
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _supabase.signInWithGoogle();

      // Якщо user != null — успішний вхід на mobile
      // Якщо user == null — web redirect (слухач authStateChanges обробить)
      if (user != null && mounted) {
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Помилка входу. Спробуйте ще раз.';
        });
      }
      debugPrint('❌ Google Sign-In помилка: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipAuth() {
    // Пропустити авторизацію (гостьовий режим)
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Логотип
              _buildLogo(),
              const SizedBox(height: 32),

              // Заголовок
              _buildTitle(),
              const SizedBox(height: 16),

              // Опис
              _buildDescription(),
              const Spacer(flex: 2),

              // Помилка
              if (_errorMessage != null) _buildError(),

              // Кнопка Google
              _buildGoogleButton(),
              const SizedBox(height: 16),

              // Кнопка пропустити
              _buildSkipButton(),
              const SizedBox(height: 24),

              // Політика конфіденційності
              _buildPrivacyNote(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/images/logo_anantata.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.auto_awesome,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Anantata',
      style: TextStyle(
        fontFamily: 'Bitter',
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Ваш персональний AI кар\'єрний коуч.\nСтворіть план розвитку з 100 кроками.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'NunitoSans',
        fontSize: 16,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Увійти через Google',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading ? null : _skipAuth,
      child: Text(
        'Продовжити без входу',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 14,
          color: Colors.grey[600],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Text(
      'Входячи, ви погоджуєтеся з Політикою конфіденційності\nта Умовами використання',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'NunitoSans',
        fontSize: 12,
        color: Colors.grey[500],
        height: 1.4,
      ),
    );
  }
}