import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/telegram_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/goal/goals_list_screen.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/main.dart';

/// Екран профілю користувача
/// Версія: 2.8.0 - SVG іконка Google + виправлений FCM
/// Дата: 06.01.2026
///
/// Що змінено:
/// - SVG іконка Google замість градієнта
/// - Використання FCMService.requestPermissionAndGetToken() замість прямого виклику

class ProfileScreen extends StatefulWidget {
  /// Callback для навігації на інший таб (напр. Plan)
  final void Function(int tabIndex)? onNavigateToTab;

  const ProfileScreen({super.key, this.onNavigateToTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();
  final TelegramService _telegram = TelegramService();

  bool _isLoading = false;
  int _completedSteps = 0;
  int _completedDirections = 0;
  int _progressPercent = 0;

  // P2 #2: Інформація про ціль
  GoalSummary? _currentGoal;
  bool _hasGoal = false;

  // Telegram
  TelegramLinkStatus? _telegramStatus;
  bool _isTelegramLoading = false;
  String? _pendingLinkCode;

  // 🆕 Notification settings
  bool _pushEnabled = false;
  bool _telegramNotifyEnabled = true;
  String _reminderTime = '09:00';
  String _frequency = 'daily';
  bool _motivational = true;
  bool _stepReminders = true;
  bool _achievements = true;
  bool _weeklyStats = false;
  bool _isNotificationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadTelegramStatus();
    _loadNotificationSettings();
  }

  Future<void> _loadStats() async {
    final plan = await _storage.getCareerPlan();
    final goalsList = await _storage.getGoalsList();

    if (mounted) {
      int completed = 0;
      int directions = 0;
      int total = 100;

      if (plan != null) {
        completed = plan.steps.where((s) => s.status == ItemStatus.done).length;
        directions = plan.directions.where((d) => d.status == ItemStatus.done).length;
        total = plan.steps.length;
      }

      setState(() {
        _completedSteps = completed;
        _completedDirections = directions;
        _progressPercent = total > 0 ? ((completed / total) * 100).round() : 0;
        _hasGoal = goalsList.goals.isNotEmpty;
        _currentGoal = goalsList.primaryGoal;
      });
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (!_supabase.isAuthenticated) return;

    try {
      final settings = await _supabase.getNotificationSettings();
      if (settings != null && mounted) {
        setState(() {
          _pushEnabled = settings['push_enabled'] ?? false;
          _telegramNotifyEnabled = settings['telegram_enabled'] ?? true;
          _reminderTime = settings['reminder_time'] ?? '09:00';
          _frequency = settings['frequency'] ?? 'daily';
          _motivational = settings['motivational'] ?? true;
          _stepReminders = settings['step_reminders'] ?? true;
          _achievements = settings['achievements'] ?? true;
          _weeklyStats = settings['weekly_stats'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (!_supabase.isAuthenticated) return;

    try {
      await _supabase.saveNotificationSettings(
        pushEnabled: _pushEnabled,
        telegramEnabled: _telegramNotifyEnabled,
        reminderTime: _reminderTime,
        frequency: _frequency,
        motivational: _motivational,
        stepReminders: _stepReminders,
        achievements: _achievements,
        weeklyStats: _weeklyStats,
      );
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// 🆕 Оновлений метод - використовує FCMService
  Future<void> _togglePushNotifications(bool enabled) async {
    if (enabled) {
      // Запитуємо дозвіл через FCMService
      setState(() => _isNotificationLoading = true);
      
      try {
        final success = await FCMService().requestPermissionAndGetToken();

        if (success) {
          setState(() => _pushEnabled = true);
          await _saveNotificationSettings();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Push-сповіщення увімкнено'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Дозвіл на сповіщення не надано'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error enabling push: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Помилка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isNotificationLoading = false);
      }
    } else {
      // Вимикаємо
      setState(() => _pushEnabled = false);
      await _saveNotificationSettings();
    }
  }

  Future<void> _loadTelegramStatus() async {
    if (!_supabase.isAuthenticated) {
      setState(() {
        _telegramStatus = TelegramLinkStatus.notAuthenticated();
      });
      return;
    }

    setState(() => _isTelegramLoading = true);

    try {
      final status = await _telegram.getLinkStatus();
      if (mounted) {
        setState(() {
          _telegramStatus = status;
          if (status.isPending) {
            _pendingLinkCode = status.linkCode;
          }
        });
      }
    } catch (e) {
      print('Error loading telegram status: $e');
    } finally {
      if (mounted) {
        setState(() => _isTelegramLoading = false);
      }
    }
  }

  Future<void> _generateTelegramCode() async {
    setState(() => _isTelegramLoading = true);

    try {
      final result = await _telegram.generateLinkCode();

      if (result.success && mounted) {
        setState(() {
          _pendingLinkCode = result.linkCode;
          _telegramStatus = TelegramLinkStatus.pendingLink(
            linkCode: result.linkCode!,
            expiresAt: result.expiresAt!,
          );
        });

        _showTelegramLinkDialog(result.linkCode!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTelegramLoading = false);
      }
    }
  }

  void _showTelegramLinkDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0088cc).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.telegram,
                color: Color(0xFF0088cc),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Прив\'язати Telegram'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Відкрий бота та надішли цей код:',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            // Код
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Код скопійовано!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.copy, color: Colors.grey[600], size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Код дійсний 15 хвилин',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Або просто натисни кнопку нижче:',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрити'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse(_telegram.getBotLinkWithCode(code));
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.telegram, size: 20),
            label: const Text('Відкрити бота'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088cc),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkTelegram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Відв\'язати Telegram?'),
        content: const Text(
          'Ви більше не будете отримувати сповіщення в Telegram.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Відв\'язати'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isTelegramLoading = true);

      final success = await _telegram.unlinkTelegram();

      if (mounted) {
        setState(() => _isTelegramLoading = false);

        if (success) {
          setState(() {
            _telegramStatus = TelegramLinkStatus.notLinked();
            _pendingLinkCode = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Telegram відв\'язано')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Помилка відв\'язки'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.signInWithGoogle();

      if (mounted) {
        setState(() {});
        _loadTelegramStatus();
        _loadNotificationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Вхід успішний!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка входу: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вийти з акаунту?'),
        content: const Text('Ваші локальні дані залишаться на пристрої.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.signOut();
      if (mounted) {
        setState(() {
          _telegramStatus = TelegramLinkStatus.notAuthenticated();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ви вийшли з акаунту')),
        );
      }
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистити дані?'),
        content: const Text(
          'Це видалить вашу ціль, план та весь прогрес. Цю дію неможливо скасувати.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.clearAll();
      if (mounted) {
        setState(() {
          _completedSteps = 0;
          _completedDirections = 0;
          _progressPercent = 0;
          _hasGoal = false;
          _currentGoal = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ціль, план та прогрес видалено')),
        );
      }
    }
  }

  Future<void> _startAssessment() async {
    final canAdd = await _storage.canAddNewGoal();

    if (!canAdd) {
      _showGoalLimitDialog();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пройти оцінювання?'),
        content: const Text(
          'Це створить нову ціль та план розвитку.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Почати'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentScreen(
            onBack: () {
              Navigator.pop(context);
            },
            onComplete: () {},
            onSubmit: (answers) {
              Navigator.pop(context);
              _navigateToGeneration(answers);
            },
          ),
        ),
      );
    }
  }

  void _showGoalLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.lock_outline,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Ціль вже розпочата'),
        content: const Text(
          'Вам доступна 1 ціль. Завершіть поточну ціль або видаліть її, щоб створити нову.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );
  }

  void _navigateToGeneration(Map<int, String> answers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerationScreen(
          answers: answers,
          onComplete: () {
            Navigator.pop(context);
            _loadStats();
          },
        ),
      ),
    );
  }

  void _navigateToGoalsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalsListScreen(),
      ),
    ).then((result) {
      _loadStats();
      if (result == 'openPlan' && widget.onNavigateToTab != null) {
        widget.onNavigateToTab!(1);
      }
    });
  }

  void _showTimePickerDialog() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = newTime);
      await _saveNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Секція профілю / авторизації
            _buildProfileSection(),
            const SizedBox(height: 24),

            // P2 #2: Блок "Моя ціль"
            _buildGoalSection(),
            const SizedBox(height: 24),

            // Telegram секція
            _buildTelegramSection(),
            const SizedBox(height: 24),

            // 🆕 Секція сповіщень
            if (_supabase.isAuthenticated) ...[
              _buildNotificationsSection(),
              const SizedBox(height: 24),
            ],

            // Статистика
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Налаштування
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final isAuth = _supabase.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isAuth ? _buildAuthenticatedProfile() : _buildGuestProfile(),
    );
  }

  Widget _buildGuestProfile() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            size: 40,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Гостьовий режим',
          style: TextStyle(
            fontFamily: 'Bitter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Увійдіть, щоб синхронізувати\nваш прогрес між пристроями',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          fontFamily: 'NunitoSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedProfile() {
    final name = _supabase.userName ?? 'Користувач';
    final email = _supabase.userEmail ?? '';
    final avatarUrl = _supabase.userAvatar;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Bitter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                'Синхронізовано',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Вийти з акаунту'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[700],
            side: BorderSide(color: Colors.red[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSection() {
    return GestureDetector(
      onTap: _hasGoal ? _navigateToGoalsList : _startAssessment,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flag, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Моя ціль',
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasGoal
                        ? (_currentGoal?.title ?? 'Переглянути ціль')
                        : 'Створіть свою першу ціль',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  /// Секція Telegram
  Widget _buildTelegramSection() {
    final isAuth = _supabase.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0088cc).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0088cc).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.telegram,
                  color: Color(0xFF0088cc),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telegram',
                      style: TextStyle(
                        fontFamily: 'Bitter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTelegramSubtitle(),
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTelegramLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Контент залежно від статусу
          if (!isAuth)
            _buildTelegramNotAuthContent()
          else if (_telegramStatus?.isLinked == true)
            _buildTelegramLinkedContent()
          else
            _buildTelegramNotLinkedContent(),
        ],
      ),
    );
  }

  String _getTelegramSubtitle() {
    if (!_supabase.isAuthenticated) {
      return 'Увійдіть для підключення';
    }
    if (_telegramStatus?.isLinked == true) {
      final username = _telegramStatus?.telegramUsername;
      return username != null ? '@$username' : 'Підключено';
    }
    if (_telegramStatus?.isPending == true) {
      return 'Очікує прив\'язки';
    }
    return 'Отримуйте нагадування';
  }

  Widget _buildTelegramNotAuthContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Увійдіть в акаунт, щоб прив\'язати Telegram',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramLinkedContent() {
    return Column(
      children: [
        // Статус підключення
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telegram підключено',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                    if (_telegramStatus?.telegramFirstName != null)
                      Text(
                        _telegramStatus!.telegramFirstName!,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Кнопка відв'язки
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isTelegramLoading ? null : _unlinkTelegram,
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('Відв\'язати'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelegramNotLinkedContent() {
    return Column(
      children: [
        // Опис переваг
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Підключіть Telegram, щоб:',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 8),
              _buildBenefitItem('Отримувати нагадування про кроки'),
              _buildBenefitItem('Переглядати прогрес'),
              _buildBenefitItem('Вести щоденник успіхів'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Кнопка прив'язки
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isTelegramLoading ? null : _generateTelegramCode,
            icon: const Icon(Icons.telegram, size: 20),
            label: const Text('Прив\'язати Telegram'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088cc),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Якщо є pending код
        if (_telegramStatus?.isPending == true && _pendingLinkCode != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showTelegramLinkDialog(_pendingLinkCode!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Код очікує: $_pendingLinkCode',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        Text(
                          'Натисніть, щоб переглянути інструкції',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.orange[400], size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.blue[700], size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 12,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Секція сповіщень
  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.purple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Нагадування',
                      style: TextStyle(
                        fontFamily: 'Bitter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Налаштуйте сповіщення',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isNotificationLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Канали
          _buildNotificationToggle(
            icon: Icons.phone_android,
            title: 'Push-сповіщення',
            subtitle: 'На телефон та браузер',
            value: _pushEnabled,
            onChanged: _togglePushNotifications,
          ),

          const SizedBox(height: 12),

          _buildNotificationToggle(
            icon: Icons.telegram,
            title: 'Telegram',
            subtitle: _telegramStatus?.isLinked == true ? 'Підключено' : 'Не підключено',
            value: _telegramNotifyEnabled && _telegramStatus?.isLinked == true,
            onChanged: _telegramStatus?.isLinked == true
                ? (val) async {
                    setState(() => _telegramNotifyEnabled = val);
                    await _saveNotificationSettings();
                  }
                : null,
          ),

          const Divider(height: 32),

          // Час та частота
          _buildTimeSelector(),

          const SizedBox(height: 16),

          _buildFrequencySelector(),

          const Divider(height: 32),

          // Типи сповіщень
          const Text(
            'Типи повідомлень',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildNotificationTypeCheckbox(
            title: 'Мотиваційні',
            subtitle: 'Щоденні надихаючі повідомлення',
            value: _motivational,
            onChanged: (val) async {
              setState(() => _motivational = val ?? true);
              await _saveNotificationSettings();
            },
          ),

          _buildNotificationTypeCheckbox(
            title: 'Нагадування про кроки',
            subtitle: 'Нагадування про наступний крок',
            value: _stepReminders,
            onChanged: (val) async {
              setState(() => _stepReminders = val ?? true);
              await _saveNotificationSettings();
            },
          ),

          _buildNotificationTypeCheckbox(
            title: 'Досягнення',
            subtitle: 'Повідомлення про прогрес',
            value: _achievements,
            onChanged: (val) async {
              setState(() => _achievements = val ?? true);
              await _saveNotificationSettings();
            },
          ),

          _buildNotificationTypeCheckbox(
            title: 'Тижнева статистика',
            subtitle: 'Звіт про прогрес за тиждень',
            value: _weeklyStats,
            onChanged: (val) async {
              setState(() => _weeklyStats = val ?? false);
              await _saveNotificationSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    final isEnabled = onChanged != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEnabled ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppTheme.textPrimary : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _showTimePickerDialog,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Час нагадувань',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Коли надсилати сповіщення',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _reminderTime,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Частота',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Як часто нагадувати',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _frequency,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Щодня')),
                DropdownMenuItem(value: '3days', child: Text('Кожні 3 дні')),
                DropdownMenuItem(value: 'weekly', child: Text('Раз на тиждень')),
                DropdownMenuItem(value: 'disabled', child: Text('Вимкнено')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _frequency = val);
                  await _saveNotificationSettings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваша статистика',
            style: TextStyle(
              fontFamily: 'Bitter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                color: Colors.green,
                value: '$_completedSteps',
                label: 'Виконано кроків',
              ),
              _buildStatItem(
                icon: Icons.folder,
                color: AppTheme.primaryColor,
                value: '$_completedDirections',
                label: 'Напрямків',
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                color: Colors.orange,
                value: '$_progressPercent%',
                label: 'Прогрес',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Bitter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Налаштування',
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.refresh,
            title: 'Пройти оцінювання',
            subtitle: 'Створити ціль та план',
            onTap: _startAssessment,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.delete_outline,
            title: 'Очистити дані',
            subtitle: 'Видалити ціль, план та прогрес',
            onTap: _clearData,
            isDestructive: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'Про додаток',
            subtitle: 'Anantata Career Coach v2.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Anantata Career Coach',
                applicationVersion: 'v2.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                children: [
                  const Text(
                    'AI-powered career development application.\n\n'
                    '© 2024-2025 Anantata',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[700] : AppTheme.textPrimary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }
}
