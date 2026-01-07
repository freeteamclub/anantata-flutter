import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';

/// Екран авторизації
/// Версія: 1.6.0 - SVG іконка Google
/// Дата: 06.01.2026
///
/// Що змінено:
/// - Використано SVG іконку Google з assets/icons/google.svg
/// - P3 #2 - Замінено withOpacity на withValues(alpha:) для Web сумісності
/// - Баг #1 - Логотип більше не обрізається на великих екранах
/// - Допрацювання #1 - Посилання на Політику конфіденційності

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

  // Допрацювання #1: URL Політики конфіденційності
  static const String _privacyPolicyUrl = 'https://privacy.anantata.ai/';

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

  // Допрацювання #1: Відкрити Політику конфіденційності
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не вдалося відкрити посилання'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Помилка відкриття URL: $e');
    }
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

              // Політика конфіденційності (клікабельна)
              _buildPrivacyNote(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Баг #1: Виправлено відображення логотипу
  Widget _buildLogo(BuildContext context) {
    // Адаптивний розмір логотипу для різних екранів
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth < 360 ? 100.0 : 120.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            // P3 #2: Виправлено withOpacity → withValues
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Баг #1: Додано padding щоб логотип не торкався країв
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/images/logo_anantata.png',
          // Баг #1: Змінено з BoxFit.cover на BoxFit.contain
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.auto_awesome,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      '100StepsCareer',
      style: TextStyle(
        fontFamily: 'Roboto',
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
        fontFamily: 'Roboto',
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
                fontFamily: 'Roboto',
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
                  // 🆕 SVG іконка Google
                  SvgPicture.asset(
                    'assets/icons/google.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Увійти через Google',
                    style: TextStyle(
                      fontFamily: 'Roboto',
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
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.grey[600],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // Допрацювання #1: Клікабельне посилання на Політику конфіденційності
  Widget _buildPrivacyNote() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Colors.grey[500],
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'Входячи, ви погоджуєтеся з '),
          TextSpan(
            text: 'Політикою конфіденційності',
            style: TextStyle(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
          ),
          const TextSpan(text: '\nта '),
          TextSpan(
            text: 'Умовами використання',
            style: TextStyle(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}
