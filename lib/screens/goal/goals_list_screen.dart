import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/goal/goal_screen.dart';
import 'package:anantata/screens/chat/chat_screen.dart';

/// Екран "Мої цілі" — управління до 3 цілей
/// Версія: 1.3.0 - Додано нижнє меню навігації
/// Дата: 23.12.2025
///
/// Виправлено:
/// - Баг #4 - Додано BottomNavigationBar для консистентності

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalScreen(goalId: goal.id),
      ),
    ).then((result) {
      // Якщо користувач натиснув "Переглянути план"
      if (result == 'openPlan') {
        Navigator.pop(context, 'openPlan');
      }
    });
  }

  void _openChat(GoalSummary goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          goalId: goal.id,
          goalTitle: goal.title,
        ),
      ),
    );
  }

  void _shareGoal(GoalSummary goal) {
    final shareText = '''
🎯 Моя ціль в Anantata

📌 ${goal.title}
💰 Цільова зарплата: ${goal.targetSalary}
📊 Match Score: ${goal.matchScore}%
📈 Прогрес: ${goal.completedSteps}/${goal.totalSteps} кроків виконано

Створи свій план на anantata.ai 🚀
''';

    Share.share(shareText, subject: 'Моя ціль в Anantata');
  }

  /// Завантажити план у форматі MD
  Future<void> _downloadPlan(GoalSummary goal) async {
    // Показуємо індикатор завантаження
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Генерую файл...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Отримуємо повний план
      final plan = await _storage.getPlanForGoal(goal.id);

      if (plan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ План не знайдено'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Генеруємо MD контент
      final mdContent = _generateMarkdown(plan);

      // Зберігаємо файл
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'anantata_plan_${DateTime.now().millisecondsSinceEpoch}.md';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(mdContent);

      // Ділимося файлом
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Мій план Anantata',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Генерує Markdown контент плану
  String _generateMarkdown(CareerPlanModel plan) {
    final buffer = StringBuffer();

    // Заголовок
    buffer.writeln('# 🎯 Мій кар\'єрний план - Anantata');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Ціль
    buffer.writeln('## 📌 Ціль');
    buffer.writeln('**${plan.goal.title}**');
    buffer.writeln();
    buffer.writeln('💰 **Цільова зарплата:** ${plan.goal.targetSalary}');
    buffer.writeln();

    // Match Score
    buffer.writeln('## 📊 Match Score: ${plan.matchScore}%');
    buffer.writeln();

    // Gap Analysis
    buffer.writeln('## 🔍 Аналіз розриву');
    buffer.writeln(plan.gapAnalysis);
    buffer.writeln();

    // Прогрес
    buffer.writeln('## 📈 Прогрес');
    buffer.writeln('- Виконано: **${plan.completedStepsCount}/${plan.steps.length}** кроків');
    buffer.writeln('- Прогрес: **${plan.overallProgress.toStringAsFixed(0)}%**');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 100 кроків
    buffer.writeln('## 📋 100 кроків до мети');
    buffer.writeln();

    for (final direction in plan.directions) {
      final dirSteps = plan.getStepsForDirection(direction.id);
      final doneCount = dirSteps.where((s) => s.status == ItemStatus.done).length;

      buffer.writeln('### ${direction.directionNumber}. ${direction.title}');
      buffer.writeln('*Прогрес: $doneCount/${dirSteps.length} кроків*');
      buffer.writeln();

      for (final step in dirSteps) {
        final checkbox = step.status == ItemStatus.done ? '[x]' : '[ ]';
        final statusEmoji = step.status == ItemStatus.done
            ? ' ✅'
            : (step.status == ItemStatus.skipped ? ' ⏭️' : '');

        buffer.writeln('- $checkbox **Крок ${step.localNumber}:** ${step.title}$statusEmoji');
        if (step.description.isNotEmpty) {
          buffer.writeln('  - ${step.description}');
        }
      }
      buffer.writeln();
    }

    // Футер
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('*Згенеровано в [Anantata](https://anantata.ai) — ${DateTime.now().toString().substring(0, 16)}*');

    return buffer.toString();
  }

  void _addNewGoal() async {
    // P2 #2: Перевіряємо ліміт цілей
    final canAdd = await _storage.canAddNewGoal();
    
    if (!canAdd) {
      _showGoalLimitDialog();
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

  void _navigateToGeneration(Map<int, String> answers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerationScreen(
          answers: answers,
          onComplete: () {
            Navigator.pop(context);
            _loadGoals();
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

  // Баг #4: Навігація через нижнє меню
  void _onBottomNavTap(int index) {
    // Закриваємо поточний екран і повертаємось на головний з потрібним індексом
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Профіль / Моя ціль',
          style: TextStyle(
            fontFamily: 'Bitter',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _buildContent(),
      // Баг #4: Додано нижнє меню навігації
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Баг #4: Побудова нижнього меню (3 пункти)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Головна',
                index: 0,
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Помічник',
                index: 1,
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Профіль',
                index: 2,
                isActive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final color = isActive ? AppTheme.primaryColor : Colors.grey[600];

    return InkWell(
      onTap: () => _onBottomNavTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_goalsList == null || _goalsList!.goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...(_goalsList!.goals.map((goal) => _buildGoalCard(goal))),
        const SizedBox(height: 24),
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
              child: const Icon(
                Icons.flag_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'У вас ще немає цілей',
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Пройдіть оцінювання, щоб створити\nперсональний план розвитку',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addNewGoal,
              icon: const Icon(Icons.add),
              label: const Text(
                'Створити першу ціль',
                style: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: const TextStyle(
                fontFamily: 'Bitter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  goal.targetSalary,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  goal.formattedDate,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Результат',
                    onTap: () => _showGoalResults(goal),
                  ),
                ),
                const SizedBox(width: 8),
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
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Поділитися',
                    onTap: () => _shareGoal(goal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download,
                    label: 'Завантажити',
                    onTap: () => _downloadPlan(goal),
                  ),
                ),
              ],
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
                    fontFamily: 'NunitoSans',
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
                  child: const Icon(
                    Icons.add,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Додати нову ціль',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(доступно ще $availableSlots)',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
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