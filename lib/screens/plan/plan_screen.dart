import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';

/// Екран плану з 10 напрямками та 100 кроками
/// Версія: 4.4.0 - Ліміт пропущених кроків
/// Дата: 21.12.2025
///
/// Виправлено:
/// - Баг #6 - Додано заголовок з назвою цілі та цільовим доходом
/// - Баг #8 - Додано callback onStepStatusChanged для автооновлення статистики
/// - Допрацювання #15 - Кнопка "Пройти оцінювання" на порожній сторінці
/// - Допрацювання #4 - Ліміт пропущених кроків (20)

class PlanScreen extends StatefulWidget {
  /// Callback при зміні статусу кроку (для оновлення статистики на головній)
  final VoidCallback? onStepStatusChanged;

  const PlanScreen({
    super.key,
    this.onStepStatusChanged,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final StorageService _storage = StorageService();
  CareerPlanModel? _plan;
  bool _isLoading = true;
  int? _expandedDirectionIndex;

  // Допрацювання #4: Ліміт пропущених кроків
  static const int _maxSkippedSteps = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plan = await _storage.getCareerPlan();
    setState(() {
      _plan = plan;
      _isLoading = false;
    });
  }

  Future<void> _markStepDone(String stepId) async {
    await _storage.markStepDone(stepId);
    await _loadData();
    // Баг #8: Викликаємо callback для оновлення статистики на головній
    widget.onStepStatusChanged?.call();
  }

  // Допрацювання #4: Перевірка ліміту перед пропуском
  Future<void> _skipStep(String stepId) async {
    final skippedCount = _plan?.skippedStepsCount ?? 0;

    // Перевіряємо ліміт
    if (skippedCount >= _maxSkippedSteps) {
      _showSkipLimitDialog();
      return;
    }

    await _storage.skipStep(stepId);
    await _loadData();
    // Баг #8: Викликаємо callback для оновлення статистики на головній
    widget.onStepStatusChanged?.call();
  }

  // Допрацювання #4: Діалог при досягненні ліміту
  void _showSkipLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange[700],
          size: 48,
        ),
        title: const Text('Ліміт пропусків досягнуто'),
        content: Text(
          'Ви вже пропустили $_maxSkippedSteps кроків.\n\n'
              'Щоб пропустити інші, спочатку виконайте або скасуйте пропуск деяких кроків.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.4,
          ),
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

  Future<void> _resetStep(String stepId) async {
    await _storage.resetStep(stepId);
    await _loadData();
    // Баг #8: Викликаємо callback для оновлення статистики на головній
    widget.onStepStatusChanged?.call();
  }

  // Допрацювання #15: Навігація на оцінювання
  void _navigateToAssessment() {
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
          },
        ),
      ),
    );
  }

  // Допрацювання #4: Перевірка чи можна пропускати
  bool get _canSkipMore {
    final skippedCount = _plan?.skippedStepsCount ?? 0;
    return skippedCount < _maxSkippedSteps;
  }

  // Допрацювання #4: Кількість пропущених кроків
  int get _skippedCount => _plan?.skippedStepsCount ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_plan == null) {
      return _buildNoPlan();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Баг #6: Заголовок з назвою цілі та цільовим доходом
          SliverToBoxAdapter(
            child: _buildGoalHeader(),
          ),

          // Шкала прогресу
          SliverToBoxAdapter(
            child: _buildProgressBar(),
          ),

          // Перемикач блоків
          SliverToBoxAdapter(
            child: _buildBlockSwitcher(),
          ),

          // Список напрямків
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '10 НАПРЯМКІВ, 100 КРОКІВ ДО МЕТИ!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Напрямки з кроками
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final direction = _plan!.directions[index];
                return _buildDirectionCard(direction, index);
              },
              childCount: _plan!.directions.length,
            ),
          ),

          // Кнопка генерації наступного блоку
          SliverToBoxAdapter(
            child: _buildNextBlockButton(),
          ),

          // Відступ знизу
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // Баг #6: Заголовок з назвою цілі та цільовим доходом
  Widget _buildGoalHeader() {
    final goalTitle = _plan?.goal.title ?? 'Моя ціль';
    final targetSalary = _plan?.goal.targetSalary ?? '';
    final matchScore = _plan?.matchScore ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Іконка та мітка
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ВАША ЦІЛЬ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Match Score
              if (matchScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$matchScore%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Назва цілі
          Text(
            goalTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Цільовий дохід
          if (targetSalary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Цільовий дохід: $targetSalary',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Допрацювання #15: Оновлено з кнопкою оцінювання
  Widget _buildNoPlan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Іконка
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),

            // Заголовок
            Text(
              'План ще не створено',
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Опис
            Text(
              'Пройдіть оцінювання, щоб отримати\nперсональний план з 100 кроками',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Допрацювання #15: Кнопка оцінювання
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAssessment,
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Пройти оцінювання'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Akrobat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _plan?.overallProgress ?? 0;
    final completed = _plan?.completedStepsCount ?? 0;
    final total = _plan?.steps.length ?? 100;

    return Container(
      margin: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ваш прогрес',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Прогрес бар - ЗЕЛЕНИЙ
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Допрацювання #4: Текст прогресу з індикатором пропущених
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Виконано $completed з $total кроків',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              // Індикатор пропущених кроків
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _canSkipMore
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _canSkipMore
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.skip_next,
                      size: 14,
                      color: _canSkipMore ? Colors.orange[700] : Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_skippedCount/$_maxSkippedSteps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _canSkipMore ? Colors.orange[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockSwitcher() {
    final currentBlock = _plan?.currentBlock ?? 1;
    final maxBlock = currentBlock; // Поки що тільки поточний блок доступний

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Кнопка назад
          IconButton(
            onPressed: currentBlock > 1 ? () => _switchBlock(currentBlock - 1) : null,
            icon: Icon(
              Icons.chevron_left,
              color: currentBlock > 1 ? AppTheme.primaryColor : Colors.grey[400],
              size: 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          const SizedBox(width: 16),

          // Номер блоку
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'БЛОК $currentBlock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Кнопка вперед
          IconButton(
            onPressed: currentBlock < maxBlock ? () => _switchBlock(currentBlock + 1) : null,
            icon: Icon(
              Icons.chevron_right,
              color: currentBlock < maxBlock ? AppTheme.primaryColor : Colors.grey[400],
              size: 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  void _switchBlock(int blockNumber) {
    // TODO: Implement block switching when multiple blocks exist
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Перехід до блоку $blockNumber (в розробці)')),
    );
  }

  Widget _buildDirectionCard(DirectionModel direction, int index) {
    final isExpanded = _expandedDirectionIndex == index;
    final steps = _plan!.getStepsForDirection(direction.id);
    final progress = _plan!.getDirectionProgress(direction.id);
    final doneCount = steps.where((s) => s.status == ItemStatus.done).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primaryColor.withOpacity(0.5)
              : Colors.grey[200]!,
        ),
        boxShadow: isExpanded
            ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Column(
        children: [
          // Заголовок напрямку
          InkWell(
            onTap: () {
              setState(() {
                _expandedDirectionIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Номер напрямку
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: progress == 100
                          ? Colors.green
                          : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: progress == 100
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : Text(
                        '${direction.directionNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Назва та прогрес
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direction.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$doneCount/10 кроків',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• $progress%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: progress == 100
                                    ? Colors.green
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Стрілка
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Кроки (якщо розгорнуто)
          if (isExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: steps.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 60,
              ),
              itemBuilder: (context, stepIndex) {
                final step = steps[stepIndex];
                return _buildStepItem(step);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(StepModel step) {
    final isDone = step.status == ItemStatus.done;
    final isSkipped = step.status == ItemStatus.skipped;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Чекбокс
          GestureDetector(
            onTap: () {
              if (isDone || isSkipped) {
                _resetStep(step.id);
              } else {
                _markStepDone(step.id);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green
                    : isSkipped
                    ? Colors.orange
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone
                      ? Colors.green
                      : isSkipped
                      ? Colors.orange
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : isSkipped
                  ? const Icon(Icons.skip_next, color: Colors.white, size: 20)
                  : null,
            ),
          ),

          // Контент кроку
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Номер кроку
                Text(
                  'Крок ${step.localNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                // Заголовок - ЧОРНИЙ
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDone || isSkipped
                        ? Colors.grey[500]
                        : Colors.black87,
                    decoration: isDone || isSkipped
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  // Опис - ЧОРНИЙ
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone || isSkipped
                          ? Colors.grey[500]
                          : Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Допрацювання #4: Кнопка пропустити (заблокована якщо ліміт)
          if (!isDone && !isSkipped)
            IconButton(
              onPressed: _canSkipMore ? () => _skipStep(step.id) : null,
              icon: Icon(
                Icons.skip_next,
                color: _canSkipMore ? Colors.grey[400] : Colors.grey[300],
                size: 24,
              ),
              tooltip: _canSkipMore
                  ? 'Пропустити'
                  : 'Ліміт пропусків досягнуто ($_skippedCount/$_maxSkippedSteps)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextBlockButton() {
    final completed = _plan?.completedStepsCount ?? 0;
    final skipped = _plan?.skippedStepsCount ?? 0;
    final total = _plan?.steps.length ?? 100;
    final allDone = (completed + skipped) >= total;
    final currentBlock = _plan?.currentBlock ?? 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allDone
            ? Colors.green.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? Colors.green.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            allDone ? Icons.celebration : Icons.lock_outline,
            size: 48,
            color: allDone ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            allDone
                ? '🎉 Блок $currentBlock завершено!'
                : 'Згенерувати блок ${currentBlock + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: allDone ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allDone
                ? 'Ви виконали всі 100 кроків. Готові до наступного блоку?'
                : 'Виконайте всі кроки поточного блоку, щоб розблокувати наступний ($completed/$total виконано)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allDone ? _generateNextBlock : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                allDone
                    ? 'Згенерувати блок ${currentBlock + 1}'
                    : 'Ще ${total - completed - skipped} кроків залишилось',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateNextBlock() {
    // TODO: Implement next block generation with Gemini
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Генерація нового блоку'),
        content: const Text(
          'Зараз буде згенеровано новий блок з 100 кроками на основі вашого прогресу. Це може зайняти до 1 хвилини.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⏳ Генерація наступного блоку... (в розробці)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Згенерувати'),
          ),
        ],
      ),
    );
  }
}