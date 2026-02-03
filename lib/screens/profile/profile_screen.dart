import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/sync_service.dart';
import 'package:anantata/services/telegram_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/goal/goals_list_screen.dart';
import 'package:anantata/screens/settings/notification_settings_screen.dart';
import 'package:anantata/screens/settings/social_networks_screen.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Екран профілю користувача
/// Версія: 4.0.0 - Уніфіковані стилі + окремий екран соцмереж
/// Дата: 07.01.2026
///
/// Що змінено:
/// - Всі картки однакового стилю (білий фон, без кольорових рамок)
/// - Блок Telegram → картка-посилання "Соцмережі"
/// - Прибрано статистику (є на головній)

class ProfileScreen extends StatefulWidget {
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

  // Інформація про ціль
  GoalSummary? _currentGoal;
  bool _hasGoal = false;

  // Telegram статус (для subtitle)
  TelegramLinkStatus? _telegramStatus;

  // Налаштування нагадувань (для картки)
  bool _pushEnabled = false;
  String _reminderTime = '09:00';
  String _frequency = 'daily';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final goalsList = await _storage.getGoalsList();

    if (mounted) {
      setState(() {
        _hasGoal = goalsList.goals.isNotEmpty;
        _currentGoal = goalsList.primaryGoal;
      });
    }

    _loadTelegramStatus();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    if (!_supabase.isAuthenticated) return;

    try {
      final settings = await _supabase.getNotificationSettings();
      if (settings != null && mounted) {
        setState(() {
          _pushEnabled = settings['push_enabled'] ?? false;
          _reminderTime = settings['reminder_time'] ?? '09:00';
          _frequency = settings['frequency'] ?? 'daily';
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _loadTelegramStatus() async {
    if (!_supabase.isAuthenticated) {
      setState(() {
        _telegramStatus = TelegramLinkStatus.notAuthenticated();
      });
      return;
    }

    try {
      final status = await _telegram.getLinkStatus();
      if (mounted) {
        setState(() => _telegramStatus = status);
      }
    } catch (e) {
      debugPrint('Error loading telegram status: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.signInWithGoogle();

      if (mounted) {
        // Перевірка конфлікту планів після входу
        await _handleSyncConflict();

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

  Future<void> _handleSyncConflict() async {
    final sync = SyncService();
    final result = await sync.checkConflict();

    switch (result.conflict) {
      case SyncConflict.both:
        if (!mounted) return;
        await _showConflictDialog(sync, result);
        break;

      case SyncConflict.cloudOnly:
        await sync.applyCloudPlan(result.cloudPlan!);
        break;

      case SyncConflict.localOnly:
        await sync.applyLocalPlan(result.localPlan!);
        break;

      case SyncConflict.none:
        break;
    }
  }

  Future<void> _showConflictDialog(SyncService sync, SyncConflictResult result) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_sync, color: Color(0xFF6C63FF), size: 48),
        title: const Text('Знайдено план в акаунті'),
        content: Text(
          'В акаунті вже є збережена ціль «${result.cloudGoalTitle}».\n\n'
          'Поточне локальне тестування буде замінено даними з акаунту.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'keepLocal'),
            child: const Text('Зберегти локальний'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'useCloud'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );

    if (choice == 'keepLocal') {
      await sync.applyLocalPlan(result.localPlan!);
    } else {
      await sync.applyCloudPlan(result.cloudPlan!);
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
        title: const Text('Очистити всі дані?'),
        content: const Text(
          'Це видалить:\n'
          '• Всі цілі та плани\n'
          '• Прогрес виконання\n'
          '• Історію чату з ШІ\n'
          '• Прив\'язку Telegram\n'
          '• Налаштування сповіщень\n\n'
          'Цю дію неможливо скасувати.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистити все'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Очищаємо локальні дані
      await _storage.clearAll();

      // Очищаємо дані в хмарі (якщо авторизований)
      if (_supabase.isAuthenticated) {
        await _supabase.clearAllUserData();
      }

      if (mounted) {
        setState(() {
          _hasGoal = false;
          _currentGoal = null;
          _telegramStatus = _supabase.isAuthenticated
              ? TelegramLinkStatus.notLinked()
              : TelegramLinkStatus.notAuthenticated();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Всі дані очищено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToGoalsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalsListScreen()),
    ).then((result) {
      _loadData();
      if (result == 'openPlan' && widget.onNavigateToTab != null) {
        widget.onNavigateToTab!(0);
      }
    });
  }

  void _navigateToSocialNetworks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SocialNetworksScreen()),
    ).then((_) {
      _loadTelegramStatus();
    });
  }

  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
    ).then((_) {
      _loadNotificationSettings();
    });
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Щодня';
      case '3days':
        return 'Кожні 3 дні';
      case 'weekly':
        return 'Раз на тиждень';
      case 'disabled':
        return 'Вимкнено';
      default:
        return 'Щодня';
    }
  }

  String _getSocialNetworksSubtitle() {
    if (!_supabase.isAuthenticated) return 'Увійдіть для підключення';
    if (_telegramStatus?.isLinked == true) {
      final username = _telegramStatus?.telegramUsername;
      return username != null ? 'Telegram: @$username' : 'Telegram підключено';
    }
    return 'Не підключено';
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
            _buildProfileCard(),
            const SizedBox(height: 12),

            // Моя ціль
            _buildMenuCard(
              icon: Icons.flag,
              title: 'Моя ціль',
              subtitle: _hasGoal
                  ? (_currentGoal?.title ?? 'Переглянути ціль')
                  : 'Створіть свою першу ціль',
              onTap: _navigateToGoalsList,
            ),
            const SizedBox(height: 12),

            // Соцмережі
            _buildMenuCard(
              icon: Icons.hub,
              title: 'Соцмережі',
              subtitle: _getSocialNetworksSubtitle(),
              onTap: _navigateToSocialNetworks,
            ),
            const SizedBox(height: 12),

            // Налаштування нагадувань (тільки для авторизованих)
            if (_supabase.isAuthenticated) ...[
              _buildMenuCard(
                icon: Icons.notifications_active,
                title: 'Налаштування нагадувань',
                subtitle: _pushEnabled
                    ? 'Push увімкнено • ${_getFrequencyText(_frequency)} о $_reminderTime'
                    : 'Push вимкнено • ${_getFrequencyText(_frequency)} о $_reminderTime',
                onTap: _navigateToNotificationSettings,
              ),
              const SizedBox(height: 12),
            ],

            // Очистити дані
            _buildMenuCard(
              icon: Icons.delete_outline,
              title: 'Очистити дані',
              subtitle: 'Видалити ціль, план та прогрес',
              onTap: _clearData,
            ),
          ],
        ),
      ),
    );
  }

  // Картка профілю
  Widget _buildProfileCard() {
    final isAuth = _supabase.isAuthenticated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline, size: 28, color: Colors.grey[500]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Гостьовий режим',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Увійдіть для синхронізації',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : SvgPicture.asset('assets/icons/google.svg', width: 18, height: 18),
            label: const Text('Увійти'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.email, size: 28, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                email,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _signOut,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[700],
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Вийти',
            style: TextStyle(fontFamily: 'Roboto', fontSize: 13),
          ),
        ),
      ],
    );
  }

  // Уніфікована картка меню (всі іконки в одному стилі)
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
