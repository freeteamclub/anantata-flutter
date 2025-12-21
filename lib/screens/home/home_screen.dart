import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/sync_service.dart';
import 'package:anantata/screens/plan/plan_screen.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/profile/profile_screen.dart';
import 'package:anantata/screens/chat/chat_screen.dart';
import 'package:anantata/screens/goal/goals_list_screen.dart';

/// Головний екран додатку v4.4
/// + Автооновлення статистики при поверненні на головну
/// Версія: 4.4
/// Дата: 21.12.2025
///
/// Виправлено:
/// - Баг #8 - Статистика оновлюється автоматично при переході на головну

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0; // Баг #8: Зберігаємо попередній таб
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();
  final SyncService _sync = SyncService();

  // Дані плану
  CareerPlanModel? _plan;
  String _userName = '';
  bool _isLoading = true;

  // Інформація про цілі
  int _goalsCount = 0;
  int _maxGoals = 3;

  @override
  void initState() {
    super.initState();
    // Баг #8: Слухаємо зміни життєвого циклу додатку
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Баг #8: Оновлюємо дані коли додаток повертається на передній план
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final name = await _storage.getUserName();

    // Спочатку завантажуємо локальний план
    var plan = await _storage.getCareerPlan();

    // Якщо авторизований - синхронізуємо з хмарою
    if (_supabase.isAuthenticated && plan == null) {
      final cloudPlan = await _sync.syncPlanFromCloud();
      if (cloudPlan != null) {
        plan = cloudPlan;
        debugPrint('☁️ План завантажено з хмари');
      }
    }

    // Отримуємо інформацію про цілі
    final goalsList = await _storage.getGoalsList();

    final displayName = _supabase.isAuthenticated
        ? (_supabase.userName ?? name ?? 'Користувач')
        : (name ?? 'Користувач');

    setState(() {
      _userName = displayName;
      _plan = plan;
      _goalsCount = goalsList.count;
      _maxGoals = GoalsListModel.maxGoals;
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброго ранку';
    if (hour < 18) return 'Доброго дня';
    return 'Доброго вечора';
  }

  void _navigateToAssessment() async {
    final canAdd = await _storage.canAddNewGoal();

    if (!canAdd) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Досягнуто максимум цілей (3/3). Видаліть існуючу, щоб додати нову.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        _navigateToGoalsList();
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentScreen(
          onComplete: () {},
          onSubmit: (answers) {
            Navigator.pop(context);
            _navigateToGeneration(answers);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
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
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Ваш план готовий! Починайте виконувати кроки'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
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
      _loadData();
      // Якщо результат 'openPlan' - переходимо на таб План
      if (result == 'openPlan') {
        _navigateToTab(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _currentIndex == 2 ? null : _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_anantata.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'Anantata',
            style: TextStyle(
              fontFamily: 'Bitter',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () => _navigateToTab(3),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
      // Баг #8: PlanScreen з callback для оновлення даних
        return PlanScreen(
          onStepStatusChanged: _onPlanDataChanged,
        );
      case 2:
        return const ChatScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  // Баг #8: Callback коли дані плану змінились
  void _onPlanDataChanged() {
    // Оновлюємо локальну копію плану
    _storage.getCareerPlan().then((plan) {
      if (mounted) {
        setState(() {
          _plan = plan;
        });
      }
    });
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Готові до нових досягнень?',
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            const Text(
              'Швидкі дії',
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 24),
            if (_plan == null) _buildNoPlanCard(),
            if (_plan != null) _buildAIChatBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _plan?.overallProgress ?? 0;
    final completedSteps = _plan?.completedStepsCount ?? 0;
    final totalSteps = _plan?.steps.length ?? 100;
    final completedDirections = _plan?.directions
        .where((d) => d.status == ItemStatus.done)
        .length ?? 0;
    final totalDirections = _plan?.directions.length ?? 10;

    return GestureDetector(
      // ✅ ВИПРАВЛЕНО: Клік веде на PlanScreen (таб 1), а не на Профіль
      onTap: _plan != null ? () => _navigateToTab(1) : null,
      child: Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ваш прогрес',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                // ✅ ВИПРАВЛЕНО: Бейдж тепер ЗЕЛЕНИЙ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Akrobat',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ ВИПРАВЛЕНО: Шкала тепер ЗЕЛЕНА
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('$completedSteps/$totalSteps', 'Кроків', Icons.check_circle_outline),
                _buildStatItem('$completedDirections/$totalDirections', 'Напрямків', Icons.folder_outlined),
                _buildStatItem('${_plan?.currentBlock ?? 1}', 'Блок', Icons.layers_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Akrobat',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionCard(icon: Icons.chat_bubble_outline, label: 'AI Чат', onTap: () => _navigateToTab(2))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(icon: Icons.assignment_outlined, label: 'Оцінювання', onTap: _navigateToAssessment)),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(icon: Icons.insights, label: 'План', onTap: () => _navigateToTab(1))),
          ],
        ),
        const SizedBox(height: 12),
        _buildGoalsCard(),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return GestureDetector(
      onTap: _navigateToGoalsList,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
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
              child: const Icon(Icons.folder, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Мої цілі', style: TextStyle(fontFamily: 'Bitter', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_goalsCount > 0 ? 'Активних цілей: $_goalsCount/$_maxGoals' : 'Створіть свою першу ціль', style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.rocket_launch_outlined, color: AppTheme.primaryColor, size: 48),
          const SizedBox(height: 16),
          const Text('Почніть свою подорож', style: TextStyle(fontFamily: 'Bitter', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Пройдіть оцінювання, щоб отримати персональний план з 100 кроками', style: TextStyle(fontFamily: 'NunitoSans', color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _navigateToAssessment,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text('Почати оцінювання', style: TextStyle(fontFamily: 'Akrobat', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIChatBanner() {
    return GestureDetector(
      onTap: () => _navigateToTab(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.psychology, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Потрібна допомога?', style: TextStyle(fontFamily: 'Bitter', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Запитайте AI коуча про ваш план', style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // Баг #8: Оновлюємо дані при переході на головну
  void _navigateToTab(int index) {
    _previousIndex = _currentIndex;
    setState(() => _currentIndex = index);

    // Якщо переходимо на головну з іншого табу - оновлюємо дані
    if (index == 0 && _previousIndex != 0) {
      _loadData();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Головна'),
              _buildNavItem(1, Icons.insights_outlined, Icons.insights, 'План'),
              _buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble, 'Чат'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Профіль'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected ? BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'NunitoSans', fontSize: 12, color: isSelected ? AppTheme.primaryColor : Colors.grey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}