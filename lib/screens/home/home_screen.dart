import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/screens/assessment/assessment_screen.dart';
import 'package:anantata/screens/assessment/generation_screen.dart';
import 'package:anantata/screens/profile/profile_screen.dart';
import 'package:anantata/screens/chat/chat_screen.dart';
import 'package:anantata/screens/chat/step_chat_screen.dart';
import 'package:anantata/services/analytics_service.dart';

/// Головний екран додатку v6.3
/// Версія: 6.3
/// Дата: 25.01.2026
///
/// Зміни v6.3:
/// - Баг #14: Збереження хмарного плану локально при логіні
///
/// Зміни v6.2:
/// - Баг #2: Нормалізація нумерації кроків (index-based замість AI)
///
/// Зміни v6.1:
/// - ChatScreen з embedded: true (без подвійного хедера)
///
/// Зміни v5.3:
/// - Прибрано дублюючий intro екран

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();

  final GlobalKey<ChatScreenState> _chatKey = GlobalKey<ChatScreenState>();

  CareerPlanModel? _plan;
  String _userName = '';
  bool _isLoading = true;
  bool _hasAutoNavigatedToAssessment = false;
  
  int? _expandedDirectionIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final name = await _storage.getUserName();
    final plan = await _storage.getCareerPlan();

    final displayName = _supabase.isAuthenticated
        ? (_supabase.userName ?? name ?? 'Користувач')
        : (name ?? 'Користувач');

    setState(() {
      _userName = displayName;
      _plan = plan;
      _isLoading = false;
    });

    // Автоматично відкриваємо assessment, якщо план == null
    if (_plan == null && !_hasAutoNavigatedToAssessment && _currentIndex == 0) {
      _hasAutoNavigatedToAssessment = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateToAssessment();
      });
    }
  }

  Future<void> _markStepDone(String stepId) async {
    await _storage.markStepDone(stepId);
    await _loadData();
  }

  Future<void> _resetStep(String stepId) async {
    await _storage.resetStep(stepId);
    await _loadData();
  }

  void _navigateToAssessment() async {
    final canAdd = await _storage.canAddNewGoal();

    if (!canAdd) {
      if (mounted) {
        _showGoalLimitDialog();
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

  void _showGoalLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: Colors.orange, size: 48),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 🆕 Динамічний AppBar - назва табу по центру
  PreferredSizeWidget _buildAppBar() {
    // Визначаємо назву залежно від табу
    String title;
    switch (_currentIndex) {
      case 0:
        title = 'Головна';
        break;
      case 1:
        title = 'Помічник';
        break;
      case 2:
        title = 'Профіль';
        break;
      default:
        title = 'Головна';
    }

    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: _currentIndex == 1
          ? [
              IconButton(
                onPressed: _saveChatToClipboard,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                tooltip: 'Зберегти чат',
              ),
              IconButton(
                onPressed: _clearChat,
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Очистити чат',
              ),
            ]
          : null,
    );
  }

  void _saveChatToClipboard() {
    final chatText = _chatKey.currentState?.getChatAsText() ?? '';
    
    if (chatText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Чат порожній'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    Clipboard.setData(ClipboardData(text: chatText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Чат скопійовано в буфер обміну'), backgroundColor: Colors.green),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 48),
        title: const Text('Очистити чат?'),
        content: const Text('Вся історія повідомлень буде видалена.', style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _chatKey.currentState?.clearChatMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Чат очищено'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ChatScreen(key: _chatKey, embedded: true); // 🆕 Вбудовано - без AppBar
      case 2:
        return ProfileScreen(onNavigateToTab: _navigateToTab);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_plan == null) {
      return _buildNoPlanCard();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGoalHeader()),
          SliverToBoxAdapter(child: _buildProgressCard()),
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final direction = _plan!.directions[index];
                return _buildDirectionCard(direction, index);
              },
              childCount: _plan!.directions.length,
            ),
          ),
          SliverToBoxAdapter(child: _buildDeleteGoalButton()),
          SliverToBoxAdapter(child: _buildNextBlockButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildGoalHeader() {
    final goalTitle = _plan?.goal.title ?? 'Моя ціль';
    final targetSalary = _plan?.goal.targetSalary ?? '';
    final matchScore = _plan?.matchScore ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'ВАША ЦІЛЬ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1),
              ),
              const Spacer(),
              if (matchScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('$matchScore%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goalTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (targetSalary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Цільовий дохід: $targetSalary',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _plan?.overallProgress ?? 0;
    final completedSteps = _plan?.completedStepsCount ?? 0;
    final totalSteps = _plan?.steps.length ?? 100;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
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
                style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(fontFamily: 'Roboto', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          Text(
            'Виконано $completedSteps з $totalSteps кроків',
            style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(DirectionModel direction, int directionIndex) {
    final isExpanded = _expandedDirectionIndex == directionIndex;
    final steps = _plan!.getStepsForDirection(direction.id);
    final progress = _plan!.getDirectionProgress(direction.id);
    final doneCount = steps.where((s) => s.status == ItemStatus.done).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? AppTheme.primaryColor.withValues(alpha: 0.5) : Colors.grey[200]!,
        ),
        boxShadow: isExpanded
            ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedDirectionIndex = isExpanded ? null : directionIndex),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: progress == 100 ? Colors.green : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: progress == 100
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : Text(
                              '${direction.directionNumber}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direction.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('$doneCount/10 кроків', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            const SizedBox(width: 8),
                            Text(
                              '• $progress%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: progress == 100 ? Colors.green : AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: steps.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
              itemBuilder: (context, stepIndex) {
                final step = steps[stepIndex];
                // 🆕 v6.2: Обчислюємо глобальний номер кроку на основі позиції
                // directionIndex (0-9) × 10 + stepIndex (0-9) + 1 = 1-100
                final globalStepNumber = (directionIndex * 10) + stepIndex + 1;
                return _buildStepItem(step, globalStepNumber);
              },
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 v6.2: Додано параметр displayNumber для коректної нумерації
  Widget _buildStepItem(StepModel step, int displayNumber) {
    final isDone = step.status == ItemStatus.done;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (isDone) {
                _resetStep(step.id);
                AnalyticsService().logStepReset(
                  stepId: step.id,
                  stepNumber: displayNumber,
                );
              } else {
                _markStepDone(step.id);
                AnalyticsService().logStepCompleted(
                  stepId: step.id,
                  stepNumber: displayNumber,
                  phaseNumber: ((displayNumber - 1) ~/ 10) + 1,
                );
              }
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDone ? Colors.green : Colors.grey[300]!, width: 2),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🆕 v6.2: Використовуємо displayNumber замість step.stepNumber
                Text(
                  'Крок $displayNumber',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.grey[500] : Colors.black87,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    step.description,
                    style: TextStyle(fontSize: 14, color: isDone ? Colors.grey[500] : Colors.black87, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openStepChat(step),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _openStepChat(StepModel step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepChatScreen(
          step: step,
          goalTitle: _plan?.goal.title ?? 'Моя ціль',
          goalId: _plan?.goal.id ?? '',
          targetSalary: _plan?.goal.targetSalary,
        ),
      ),
    );
  }

  Widget _buildNextBlockButton() {
    final completed = _plan?.completedStepsCount ?? 0;
    final total = _plan?.steps.length ?? 100;
    final allDone = completed >= total;
    final currentBlock = _plan?.currentBlock ?? 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allDone ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: allDone ? Colors.green.withValues(alpha: 0.3) : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(allDone ? Icons.celebration : Icons.lock_outline, size: 48, color: allDone ? Colors.green : Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            allDone ? '🎉 Блок $currentBlock завершено!' : 'Згенерувати блок ${currentBlock + 1}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: allDone ? Colors.green[700] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            allDone
                ? 'Ви виконали всі 100 кроків. Готові до наступного блоку?'
                : 'Виконайте всі кроки поточного блоку, щоб розблокувати наступний ($completed/$total виконано)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                allDone ? 'Згенерувати блок ${currentBlock + 1}' : 'Ще ${total - completed} кроків залишилось',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Кнопка видалення цілі
  Widget _buildDeleteGoalButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.delete_outline, size: 32, color: Colors.red[300]),
          const SizedBox(height: 8),
          Text(
            'Видалити поточну ціль',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red[700]),
          ),
          const SizedBox(height: 4),
          Text(
            'Щоб згенерувати нову ціль та план',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _deleteCurrentGoal,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Видалити ціль', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCurrentGoal() async {
    final goalTitle = _plan?.goal.title ?? 'Поточна ціль';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 48),
        title: const Text('Видалити ціль?'),
        content: Text(
          'Ви впевнені, що хочете видалити ціль "$goalTitle"?\n\nВесь прогрес буде втрачено. Після видалення ви зможете створити нову ціль.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final goalId = _plan?.goal.id;
      if (goalId != null) {
        await _storage.deleteGoal(goalId);
      } else {
        await _storage.clearAll();
      }
      
      if (mounted) {
        setState(() {
          _plan = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Ціль видалено. Тепер можна створити нову!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _generateNextBlock() {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Згенерувати'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Почніть свою подорож',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Пройдіть оцінювання, щоб отримати\nперсональний план з 100 кроками',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 15, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAssessment,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Почати оцінювання'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    // Закриваємо всі вкладені екрани (pop until root)
    Navigator.of(context).popUntil((route) => route.isFirst);

    _previousIndex = _currentIndex;
    setState(() => _currentIndex = index);

    if (index == 0 && _previousIndex != 0) {
      _loadData();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Головна'),
              _buildNavItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Помічник'),
              _buildNavItem(2, Icons.person_outline, Icons.person, 'Профіль'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
