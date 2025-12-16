import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';

/// Екран "Моя ціль" - показує Match Score та Gap Analysis
/// Версія: 2.1.0 - Виправлено кнопку "Переглянути план" + зелена шкала
/// Дата: 15.12.2025

class GoalScreen extends StatefulWidget {
  /// ID цілі для відображення. Якщо null - показує поточний/головний план
  final String? goalId;

  const GoalScreen({super.key, this.goalId});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final StorageService _storage = StorageService();
  CareerPlanModel? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    CareerPlanModel? plan;

    // Якщо передано goalId - завантажуємо конкретну ціль
    if (widget.goalId != null) {
      plan = await _storage.getPlanForGoal(widget.goalId!);
    }

    // Якщо goalId не передано або план не знайдено - завантажуємо поточний
    plan ??= await _storage.getCareerPlan();

    setState(() {
      _plan = plan;
      _isLoading = false;
    });
  }

  /// Перехід до екрану плану
  void _navigateToPlan() {
    // Повертаємось назад з результатом 'openPlan'
    Navigator.pop(context, 'openPlan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Моя ціль',
          style: TextStyle(
            fontFamily: 'Bitter',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      )
          : _plan == null
          ? _buildNoPlan()
          : _buildContent(),
    );
  }

  Widget _buildNoPlan() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Ціль ще не встановлена',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Пройдіть оцінювання, щоб отримати план',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Картка цілі
          _buildGoalCard(),
          const SizedBox(height: 24),

          // Match Score
          _buildMatchScoreCard(),
          const SizedBox(height: 20),

          // Gap Analysis
          _buildGapAnalysisCard(),
          const SizedBox(height: 20),

          // Статистика
          _buildStatsCard(),
          const SizedBox(height: 24),

          // Кнопка переглянути план - ВИПРАВЛЕНО: відкриває PlanScreen
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToPlan,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text(
                'Переглянути план',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Кнопка пройти оцінювання знову
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Пройти оцінювання знову',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ваша ціль',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_plan?.goal.isPrimary == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⭐ Головна',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _plan?.goal.title ?? 'Кар\'єрний розвиток',
            style: const TextStyle(
              fontFamily: 'Bitter',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                'Цільовий дохід: ${_plan?.goal.targetSalary ?? "\$3,000-5,000"}',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchScoreCard() {
    final score = _plan?.matchScore ?? 0;
    final scoreColor = score >= 70
        ? Colors.green
        : (score >= 40 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          const Text(
            'Match Score',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: 'Akrobat',
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontFamily: 'Akrobat',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getScoreDescription(score),
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGapAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Аналіз розриву',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _plan?.gapAnalysis ?? 'Аналіз недоступний',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final completedSteps = _plan?.completedStepsCount ?? 0;
    final totalSteps = _plan?.steps.length ?? 100;
    final completedDirs = _plan?.directions
        .where((d) => d.status == ItemStatus.done)
        .length ??
        0;
    final totalDirs = _plan?.directions.length ?? 10;
    final progress = _plan?.overallProgress ?? 0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ваш прогрес',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              _buildStatItem(
                '$completedSteps/$totalSteps',
                'Кроків',
                Icons.check_circle_outline,
              ),
              _buildStatItem(
                '$completedDirs/$totalDirs',
                'Напрямків',
                Icons.folder_outlined,
              ),
              _buildStatItem(
                '${_plan?.currentBlock ?? 1}',
                'Блок',
                Icons.layers_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Akrobat',
            fontSize: 20,
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

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Відмінний старт! Ви близькі до мети';
    if (score >= 60) return 'Хороша база. План допоможе заповнити прогалини';
    if (score >= 40) return 'Є над чим працювати. Крок за кроком досягнете мети';
    return 'Великий шлях попереду. Але ми з вами!';
  }
}