import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/gemini_service.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Екран генерації кар'єрного плану
/// Показує анімацію та результати генерації
/// Версія: 1.0.0
/// Дата: 13.12.2025

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

  // Стан генерації
  GenerationState _state = GenerationState.analyzing;
  String _currentMessage = 'Аналізуємо ваші відповіді...';
  double _progress = 0.0;

  // Результат
  CareerPlanModel? _plan;
  String? _errorMessage;

  // Анімації
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

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
    super.dispose();
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

      // Етап 2: Генерація (30-80%)
      await _updateState(
        GenerationState.generating,
        'Генеруємо персональний план...',
        0.4,
      );

      // Зберігаємо відповіді
      await _storage.saveAssessmentAnswers(widget.answers);

      // Генеруємо план через Gemini
      final generatedPlan = await _gemini.generateCareerPlan(widget.answers);

      await _updateState(
        GenerationState.generating,
        'Створюємо 10 напрямків розвитку...',
        0.6,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      await _updateState(
        GenerationState.generating,
        'Формуємо 100 конкретних кроків...',
        0.75,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Етап 3: Збереження (80-100%)
      await _updateState(
        GenerationState.saving,
        'Зберігаємо ваш план...',
        0.85,
      );

      // Зберігаємо план
      final savedPlan = await _storage.saveGeneratedPlan(generatedPlan);
      await _storage.setAssessmentComplete(true);

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
      });

      _pulseController.stop();

    } catch (e) {
      print('❌ Помилка генерації: $e');
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
    setState(() {
      _state = state;
      _currentMessage = message;
      _progress = progress;
    });
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

          // Кнопка
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
          const SizedBox(height: 24),
        ],
      ),
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
            'Match Score',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
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