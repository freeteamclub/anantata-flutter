import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/gemini_service.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/profile_summary_service.dart';  // T7
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/screens/goal/goals_list_screen.dart';

/// Екран генерації кар'єрного плану
/// Показує анімацію та результати генерації
/// Версія: 1.2.0 - Плавний прогрес під час генерації
/// Дата: 21.12.2025
///
/// Виправлено:
/// - Баг #12a - Прогрес-бар більше не зависає на 40%

class GenerationScreen extends StatefulWidget {
  final Map<int, String> answers;
  final VoidCallback? onComplete;

  const GenerationScreen({
    super.key,
    required this.answers,
    this.onComplete,
  });

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with TickerProviderStateMixin {

  // Сервіси
  final GeminiService _gemini = GeminiService();
  final StorageService _storage = StorageService();
  final ProfileSummaryService _profileSummary = ProfileSummaryService();  // T7

  // Стан генерації
  GenerationState _state = GenerationState.analyzing;
  String _currentMessage = 'Аналізуємо ваші відповіді...';
  double _progress = 0.0;

  // Результат
  CareerPlanModel? _plan;
  String? _errorMessage;

  // 🆕 Інформація про слоти цілей
  int _goalsCount = 0;
  int _maxGoals = 3;

  // Анімації
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  // Баг #12a: Timer для симуляції прогресу
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startGeneration();
  }

  void _initAnimations() {
    // Пульсуюча анімація для іконки
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Контролер прогресу
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _stopProgressSimulation(); // Баг #12a: Зупиняємо timer
    super.dispose();
  }

  // Баг #12a: Запускаємо симуляцію прогресу під час очікування Gemini
  // Покращено: динамічний крок що сповільнюється — ніколи не "зависає"
  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_progress < 0.74 && mounted) {
        setState(() {
          // Динамічний крок: швидко на початку, повільніше ближче до 74%
          // Чим ближче до 74%, тим менший крок — прогрес ніколи не зупиняється
          final remaining = 0.74 - _progress;
          final step = remaining * 0.08; // 8% від залишку
          _progress += step.clamp(0.002, 0.02); // мін 0.2%, макс 2%

          // Змінюємо повідомлення на різних етапах
          if (_progress >= 0.45 && _progress < 0.55) {
            _currentMessage = 'Аналізуємо кар\'єрний потенціал...';
          } else if (_progress >= 0.55 && _progress < 0.65) {
            _currentMessage = 'Створюємо 10 напрямків розвитку...';
          } else if (_progress >= 0.65) {
            _currentMessage = 'Формуємо 100 конкретних кроків...';
          }
        });
      }
    });
  }

  // Баг #12a: Зупиняємо симуляцію прогресу
  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _startGeneration() async {
    try {
      // Етап 1: Аналіз (0-30%)
      await _updateState(
        GenerationState.analyzing,
        'Аналізуємо ваші відповіді...',
        0.1,
      );
      await Future.delayed(const Duration(milliseconds: 800));

      await _updateState(
        GenerationState.analyzing,
        'Визначаємо ваші сильні сторони...',
        0.2,
      );
      await Future.delayed(const Duration(milliseconds: 600));

      await _updateState(
        GenerationState.analyzing,
        'Оцінюємо кар\'єрний потенціал...',
        0.3,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Етап 2: Генерація (30-80%)
      await _updateState(
        GenerationState.generating,
        'Генеруємо персональний план...',
        0.4,
      );

      // Зберігаємо відповіді
      await _storage.saveAssessmentAnswers(widget.answers);

      // Баг #12a: Запускаємо симуляцію прогресу під час очікування
      _startProgressSimulation();

      // Генеруємо план через Gemini (може тривати 10-30 секунд)
      final generatedPlan = await _gemini.generateCareerPlan(widget.answers);

      // Баг #12a: Зупиняємо симуляцію після отримання відповіді
      _stopProgressSimulation();

      // Продовжуємо з 75%
      await _updateState(
        GenerationState.generating,
        'Фіналізуємо план...',
        0.75,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // Етап 3: Збереження (80-100%)
      await _updateState(
        GenerationState.saving,
        'Зберігаємо ваш план...',
        0.85,
      );

      // Зберігаємо план
      final savedPlan = await _storage.saveGeneratedPlan(generatedPlan);
      await _storage.setAssessmentComplete(true);

      // T7: Створюємо перший Profile Summary після assessment
      // Передаємо дані плану напряму щоб уникнути race condition з Supabase
      _profileSummary.checkAndUpdateSummary(
        trigger: TriggerType.assessmentCompleted,
        goalTitle: generatedPlan.goal.title,
        targetSalary: generatedPlan.goal.targetSalary,
      );

      // 🆕 Отримуємо інформацію про кількість цілей
      final goalsList = await _storage.getGoalsList();

      await _updateState(
        GenerationState.saving,
        'Фінальні штрихи...',
        0.95,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // Готово!
      setState(() {
        _state = GenerationState.complete;
        _currentMessage = 'Ваш план готовий!';
        _progress = 1.0;
        _plan = savedPlan;
        _goalsCount = goalsList.count;
        _maxGoals = GoalsListModel.maxGoals;
      });

      _pulseController.stop();

    } catch (e) {
      print('❌ Помилка генерації: $e');
      _stopProgressSimulation(); // Баг #12a: Зупиняємо timer при помилці
      setState(() {
        _state = GenerationState.error;
        _errorMessage = 'Не вдалося згенерувати план. Спробуйте ще раз.';
      });
      _pulseController.stop();
    }
  }

  Future<void> _updateState(
      GenerationState state,
      String message,
      double progress,
      ) async {
    if (mounted) {
      setState(() {
        _state = state;
        _currentMessage = message;
        _progress = progress;
      });
    }
  }

  void _retryGeneration() {
    setState(() {
      _state = GenerationState.analyzing;
      _currentMessage = 'Аналізуємо ваші відповіді...';
      _progress = 0.0;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: true);
    _startGeneration();
  }

  void _viewPlan() {
    widget.onComplete?.call();
  }

  /// 🆕 Перейти до списку цілей
  void _viewGoalsList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GoalsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _state == GenerationState.complete
              ? _buildCompleteContent()
              : _state == GenerationState.error
              ? _buildErrorContent()
              : _buildLoadingContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        // Анімована іконка
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStateIcon(),
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),

        // Повідомлення
        Text(
          _currentMessage,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Прогрес бар
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Підказка
        Text(
          'Це може зайняти до хвилини...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCompleteContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Іконка успіху
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),

          // Заголовок
          const Text(
            '🎉 Ваш план готовий!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),

          // Match Score
          _buildScoreCard(),
          const SizedBox(height: 20),

          // Gap Analysis
          _buildGapAnalysisCard(),
          const SizedBox(height: 20),

          // Статистика плану
          _buildPlanStatsCard(),
          const SizedBox(height: 32),

          // 🆕 Кнопки навігації
          _buildNavigationButtons(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 🆕 Кнопки навігації після генерації
  Widget _buildNavigationButtons() {
    return Column(
      children: [
        // Основна кнопка - Переглянути план
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Переглянути план',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Вторинна кнопка - Мої цілі
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewGoalsList,
            icon: const Icon(Icons.folder_outlined),
            label: Text('Мої цілі ($_goalsCount/$_maxGoals)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ваша відповідність цілі',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreDescription(score),
            style: TextStyle(
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
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Аналіз',
                style: TextStyle(
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
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStatsCard() {
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
          Text(
            '🎯 ${_plan?.goal.title ?? "Ваша ціль"}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Цільовий дохід: ${_plan?.goal.targetSalary ?? ""}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '10',
                'Напрямків',
                Icons.folder_outlined,
              ),
              _buildStatItem(
                '100',
                'Кроків',
                Icons.check_circle_outline,
              ),
              _buildStatItem(
                '1',
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Упс! Щось пішло не так',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Спробуйте ще раз',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _retryGeneration,
          icon: const Icon(Icons.refresh),
          label: const Text('Спробувати ще раз'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Повернутись назад'),
        ),
      ],
    );
  }

  IconData _getStateIcon() {
    switch (_state) {
      case GenerationState.analyzing:
        return Icons.psychology_outlined;
      case GenerationState.generating:
        return Icons.auto_awesome;
      case GenerationState.saving:
        return Icons.save_outlined;
      case GenerationState.complete:
        return Icons.check_circle;
      case GenerationState.error:
        return Icons.error_outline;
    }
  }

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Відмінний старт! Ви близькі до мети';
    if (score >= 60) return 'Хороша база. План допоможе заповнити прогалини';
    if (score >= 40) return 'Є над чим працювати. Крок за кроком досягнете мети';
    return 'Великий шлях попереду. Але ми з вами!';
  }
}

/// Стани генерації
enum GenerationState {
  analyzing,
  generating,
  saving,
  complete,
  error,
}