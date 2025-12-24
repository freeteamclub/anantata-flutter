import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/goal/goals_list_screen.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Екран профілю користувача
/// Версія: 2.5.0 - Додано блок "Моя ціль"
/// Дата: 25.12.2025
///
/// Виправлено:
/// - P2 #2 - Додано блок "Моя ціль" (перенесено з головної)
/// - P3 #8 - Перейменовано "Пройти оцінювання знову" → "Пройти оцінювання"
/// - Баг #9 - Передача onBack до AssessmentScreen
/// - Баг #7 (профіль) - Оновлено версію з 1.0.0 на 2.0.0
/// - Допрацювання #3 - Текст "Видалити ціль, план та прогрес"

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

  bool _isLoading = false;
  int _completedSteps = 0;
  int _completedDirections = 0;
  int _progressPercent = 0;

  // P2 #2: Інформація про ціль
  GoalSummary? _currentGoal;
  bool _hasGoal = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.signInWithGoogle();

      if (mounted) {
        setState(() {});
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
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ви вийшли з акаунту')),
        );
      }
    }
  }

  // Допрацювання #3: Оновлено текст діалогу
  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистити дані?'),
        // Допрацювання #3: Додано "вашу ціль"
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
          // Допрацювання #3: Оновлено текст підтвердження
          const SnackBar(content: Text('Ціль, план та прогрес видалено')),
        );
      }
    }
  }

  // P3 #8: Оновлено текст діалогу
  Future<void> _startAssessment() async {
    // P2 #2: Перевіряємо чи можна додати нову ціль
    final canAdd = await _storage.canAddNewGoal();

    if (!canAdd) {
      _showGoalLimitDialog();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // P3 #8: Прибрано "знову"
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
      // Баг #9: Передаємо всі необхідні callbacks
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentScreen(
            // Баг #9: onBack - дозволяє вийти з оцінювання
            onBack: () {
              Navigator.pop(context);
            },
            // onComplete викликається після успішної генерації
            onComplete: () {
              // Нічого не робимо тут, бо onSubmit вже обробляє навігацію
            },
            // onSubmit - обробляємо відповіді та переходимо до генерації
            onSubmit: (answers) {
              Navigator.pop(context); // Закриваємо AssessmentScreen
              _navigateToGeneration(answers);
            },
          ),
        ),
      );
    }
  }

  // P2 #2: Попап при досягненні ліміту цілей
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

  // Баг #9: Додано метод навігації до генерації плану
  void _navigateToGeneration(Map<int, String> answers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerationScreen(
          answers: answers,
          onComplete: () {
            Navigator.pop(context); // Закриваємо GenerationScreen
            _loadStats(); // Оновлюємо статистику
          },
        ),
      ),
    );
  }

  // P2 #2: Перехід до екрану цілей
  void _navigateToGoalsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalsListScreen(),
      ),
    ).then((result) {
      _loadStats(); // Оновлюємо після повернення
      // Якщо результат 'openPlan' - переходимо на таб План
      if (result == 'openPlan' && widget.onNavigateToTab != null) {
        widget.onNavigateToTab!(1); // 1 = Plan tab
      }
    });
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
            color: Colors.black.withValues(alpha: 0.05),
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
        // Іконка гостя
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

        // Текст
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

        // Кнопка Google Sign-In
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
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
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
        // Аватар
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
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

        // Ім'я
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

        // Email
        Text(
          email,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),

        // Бейдж "Синхронізовано"
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

        // Кнопка виходу
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

  // P2 #2: Блок "Моя ціль"
  Widget _buildGoalSection() {
    return GestureDetector(
      onTap: _hasGoal ? _navigateToGoalsList : _startAssessment,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: Colors.amber.withValues(alpha: 0.1),
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

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            // P3 #8: Прибрано "знову"
            title: 'Пройти оцінювання',
            // P3 #8: Змінено "Оновити" → "Створити"
            subtitle: 'Створити ціль та план',
            onTap: _startAssessment,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.delete_outline,
            title: 'Очистити дані',
            // Допрацювання #3: Оновлено subtitle
            subtitle: 'Видалити ціль, план та прогрес',
            onTap: _clearData,
            isDestructive: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'Про додаток',
            // Баг #7 (профіль): Оновлено версію
            subtitle: 'Anantata Career Coach v2.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Anantata Career Coach',
                // Баг #7 (профіль): Оновлено версію
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
