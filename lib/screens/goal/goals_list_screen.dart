import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/goal/goal_screen.dart';
import 'package:anantata/screens/chat/chat_screen.dart';

/// Екран "Мої цілі" — управління до 3 цілей
/// Версія: 1.1.0 - Виправлено кнопки Обговорити та Додати нову ціль
/// Дата: 15.12.2025

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final StorageService _storage = StorageService();

  GoalsListModel? _goalsList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    final goalsList = await _storage.getGoalsList();

    setState(() {
      _goalsList = goalsList;
      _isLoading = false;
    });
  }

  Future<void> _setPrimaryGoal(String goalId) async {
    await _storage.setPrimaryGoal(goalId);
    await _loadGoals();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Головну ціль змінено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteGoal(String goalId, String goalTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити ціль?'),
        content: Text('Ви впевнені, що хочете видалити ціль "$goalTitle"?\n\nЦю дію неможливо скасувати.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteGoal(goalId);
      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Ціль видалено'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showGoalResults(GoalSummary goal) {
    // TODO: Оновити GoalScreen для підтримки конкретної цілі
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalScreen(),
      ),
    );
  }

  /// 🔧 ВИПРАВЛЕНО: Відкриває чат
  void _openChat(GoalSummary goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  void _shareGoal(GoalSummary goal) {
    // TODO: Поділитися результатами
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Функція "Поділитися" буде додана пізніше'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔧 ВИПРАВЛЕНО: Правильний flow для додавання нової цілі
  void _addNewGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentScreen(
          onComplete: () {},
          onSubmit: (answers) {
            // Закриваємо AssessmentScreen
            Navigator.pop(context);
            // Відкриваємо GenerationScreen
            _navigateToGeneration(answers);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Перехід до генерації плану
  void _navigateToGeneration(Map<int, String> answers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerationScreen(
          answers: answers,
          onComplete: () {
            // Закриваємо GenerationScreen
            Navigator.pop(context);
            // Оновлюємо список цілей
            _loadGoals();
            // Показуємо повідомлення
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Нову ціль додано!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.folder, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              'Мої цілі (${_goalsList?.count ?? 0}/${GoalsListModel.maxGoals})',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_goalsList == null || _goalsList!.goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Список цілей
        ...(_goalsList!.goals.map((goal) => _buildGoalCard(goal))),

        const SizedBox(height: 24),

        // Кнопка додавання нової цілі
        if (_goalsList!.canAddNew) _buildAddGoalButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'У вас ще немає цілей',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Пройдіть оцінювання, щоб створити\nперсональний план розвитку',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addNewGoal,
              icon: const Icon(Icons.add),
              label: const Text('Створити першу ціль'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(GoalSummary goal) {
    final isPrimary = _goalsList?.primaryGoalId == goal.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary
            ? Border.all(color: Colors.amber, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок з іконкою
            Row(
              children: [
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Головна',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
              goal.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Зарплата
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  goal.targetSalary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Дата створення
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  goal.formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Статус
            Row(
              children: [
                Icon(Icons.sync, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Активна',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Прогрес
            if (goal.totalSteps > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progress / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goal.progress >= 100 ? Colors.green : AppTheme.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${goal.completedSteps}/${goal.totalSteps}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Кнопки дій - Перший ряд
            Row(
              children: [
                // Результат
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Результат',
                    onTap: () => _showGoalResults(goal),
                  ),
                ),
                const SizedBox(width: 8),
                // Обговорити
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Обговорити',
                    onTap: () => _openChat(goal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Кнопки дій - Другий ряд
            Row(
              children: [
                // Головна ціль
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.star,
                    label: 'Головна ціль',
                    isHighlighted: isPrimary,
                    highlightColor: Colors.amber,
                    onTap: isPrimary ? null : () => _setPrimaryGoal(goal.id),
                  ),
                ),
                const SizedBox(width: 8),
                // Видалити
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Видалити',
                    textColor: Colors.red,
                    onTap: () => _deleteGoal(goal.id, goal.title),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Поділитися
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                icon: Icons.share,
                label: 'Поділитися',
                onTap: () => _shareGoal(goal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? textColor,
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    final color = textColor ?? Colors.grey[700];
    final bgColor = isHighlighted
        ? (highlightColor ?? AppTheme.primaryColor)
        : Colors.grey[100];
    final fgColor = isHighlighted ? Colors.white : color;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: fgColor,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGoalButton() {
    final availableSlots = _goalsList?.availableSlots ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addNewGoal,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Додати нову ціль',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(доступно ще $availableSlots)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}