import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/profile_summary_service.dart';  // T7
import 'package:uuid/uuid.dart';

/// Сервіс для локального збереження даних
/// Версія: 4.4.0 - Баг #9: синхронізація видалення цілі з Supabase
/// Дата: 18.01.2026

class StorageService {
  static const String _keyUserName = 'user_name';
  static const String _keyAssessmentComplete = 'assessment_complete';
  static const String _keyAssessmentAnswers = 'assessment_answers';
  static const String _keyCareerPlan = 'career_plan';
  static const String _keyMatchScore = 'match_score';
  static const String _keyGapAnalysis = 'gap_analysis';

  // Ключі для списку цілей
  static const String _keyGoalsList = 'goals_list';
  static const String _keyPrimaryGoalId = 'primary_goal_id';
  static const String _keyAllPlans = 'all_plans';
  static const String _keyChatHistory = 'chat_history';

  final Uuid _uuid = const Uuid();
  final SupabaseService _supabase = SupabaseService();

  // ═══════════════════════════════════════════════════════════════
  // USER DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSESSMENT
  // ═══════════════════════════════════════════════════════════════

  Future<void> setAssessmentComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAssessmentComplete, complete);
  }

  Future<bool> isAssessmentComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAssessmentComplete) ?? false;
  }

  Future<void> saveAssessmentAnswers(Map<int, String> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = answers.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_keyAssessmentAnswers, jsonEncode(jsonMap));

    if (_supabase.isAuthenticated) {
      await _supabase.saveAssessmentAnswers(answers);
    }
  }

  Future<Map<int, String>?> getAssessmentAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAssessmentAnswers);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      return jsonMap.map((key, value) => MapEntry(int.parse(key), value as String));
    } catch (e) {
      debugPrint('❌ Помилка читання відповідей: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CHAT HISTORY (локальна історія для кожної цілі)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getLocalChatHistory(String? goalId) async {
    if (goalId == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final allChatsJson = prefs.getString(_keyChatHistory);

    if (allChatsJson == null) return [];

    try {
      final allChats = jsonDecode(allChatsJson) as Map<String, dynamic>;
      if (allChats.containsKey(goalId)) {
        final messages = allChats[goalId] as List<dynamic>;
        return List<Map<String, dynamic>>.from(
          messages.map((m) => Map<String, dynamic>.from(m as Map)),
        );
      }
    } catch (e) {
      debugPrint('❌ Помилка читання історії чату: $e');
    }

    return [];
  }

  Future<void> saveLocalChatMessage({
    required String goalId,
    required String text,
    required bool isUser,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> allChats = {};
    final allChatsJson = prefs.getString(_keyChatHistory);
    if (allChatsJson != null) {
      allChats = Map<String, dynamic>.from(jsonDecode(allChatsJson) as Map);
    }

    List<dynamic> messages = [];
    if (allChats.containsKey(goalId)) {
      messages = List<dynamic>.from(allChats[goalId] as List);
    }

    messages.add({
      'text': text,
      'is_user': isUser,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (messages.length > 100) {
      messages = messages.sublist(messages.length - 100);
    }

    allChats[goalId] = messages;
    await prefs.setString(_keyChatHistory, jsonEncode(allChats));

    debugPrint('💬 Повідомлення збережено для цілі $goalId');
  }

  Future<void> clearLocalChatHistory(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final allChatsJson = prefs.getString(_keyChatHistory);

    if (allChatsJson == null) return;

    try {
      final allChats = Map<String, dynamic>.from(jsonDecode(allChatsJson) as Map);
      allChats.remove(goalId);
      await prefs.setString(_keyChatHistory, jsonEncode(allChats));
      debugPrint('🗑️ Історія чату очищена для цілі $goalId');
    } catch (e) {
      debugPrint('❌ Помилка очищення історії чату: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GOALS LIST (до 3 цілей)
  // ═══════════════════════════════════════════════════════════════

  Future<GoalsListModel> getGoalsList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyGoalsList);

    // Якщо локально є дані - повертаємо їх
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final localGoals = GoalsListModel.fromJson(json);
        if (localGoals.goals.isNotEmpty) {
          debugPrint('✅ Завантажено ${localGoals.count} цілей локально');
          return localGoals;
        }
      } catch (e) {
        debugPrint('❌ Помилка читання списку цілей: $e');
      }
    }

    // 🆕 Якщо локально пусто І користувач авторизований - завантажуємо з Supabase
    if (_supabase.isAuthenticated) {
      debugPrint('☁️ Локально пусто, завантажуємо з Supabase...');
      final cloudGoals = await _loadGoalsFromCloud();
      if (cloudGoals.goals.isNotEmpty) {
        await _saveGoalsList(cloudGoals);
        return cloudGoals;
      }
    }

    // Перевіряємо старий формат (міграція)
    final oldPlan = await getCareerPlan();
    if (oldPlan != null) {
      final summary = GoalSummary.fromCareerPlan(oldPlan);
      final goalsList = GoalsListModel(
        goals: [summary.copyWith(isPrimary: true)],
        primaryGoalId: summary.id,
      );
      await _saveGoalsList(goalsList);
      return goalsList;
    }

    return GoalsListModel.empty();
  }

  /// 🆕 Завантажити цілі з Supabase та конвертувати в GoalsListModel
  Future<GoalsListModel> _loadGoalsFromCloud() async {
    try {
      final goalsData = await _supabase.getAllGoals();
      if (goalsData.isEmpty) {
        debugPrint('📭 Supabase: цілей не знайдено');
        return GoalsListModel.empty();
      }

      final List<GoalSummary> goals = [];
      String? primaryGoalId;

      for (final goalData in goalsData) {
        final goalId = goalData['id'] as String;
        final isActive = goalData['is_active'] as bool? ?? false;
        
        // Завантажуємо повний план для підрахунку прогресу
        final stepsData = await _supabase.getSteps(goalId);
        final completedSteps = stepsData.where((s) => s['status'] == 'done').length;
        final totalSteps = stepsData.length;
        final progress = totalSteps > 0 ? (completedSteps / totalSteps * 100) : 0.0;

        final summary = GoalSummary(
          id: goalId,
          title: goalData['title'] as String? ?? 'Кар\'єрна ціль',
          targetSalary: goalData['target_salary'] as String? ?? '',
          matchScore: goalData['match_score'] as int? ?? 0,
          gapAnalysis: goalData['gap_analysis'] as String? ?? '',
          progress: progress,
          completedSteps: completedSteps,
          totalSteps: totalSteps,
          isPrimary: isActive,
          createdAt: DateTime.tryParse(goalData['created_at'] as String? ?? '') ?? DateTime.now(),
        );

        goals.add(summary);

        if (isActive) {
          primaryGoalId = goalId;
        }

        // Завантажуємо повний план для конкретної цілі та зберігаємо локально
        final fullPlan = await _supabase.loadPlanForGoal(goalId, goalData);
        if (fullPlan != null) {
          await _savePlanToAllPlans(fullPlan);
          if (isActive) {
            await _saveCurrentPlan(fullPlan);
          }
        }
      }

      // Якщо немає активної цілі - робимо першу активною
      if (primaryGoalId == null && goals.isNotEmpty) {
        primaryGoalId = goals.first.id;
        goals[0] = goals.first.copyWith(isPrimary: true);
      }

      debugPrint('✅ Завантажено ${goals.length} цілей з Supabase');
      return GoalsListModel(goals: goals, primaryGoalId: primaryGoalId);
    } catch (e) {
      debugPrint('❌ Помилка завантаження цілей з Supabase: $e');
      return GoalsListModel.empty();
    }
  }

  Future<void> _saveGoalsList(GoalsListModel goalsList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoalsList, jsonEncode(goalsList.toJson()));
    if (goalsList.primaryGoalId != null) {
      await prefs.setString(_keyPrimaryGoalId, goalsList.primaryGoalId!);
    }
    debugPrint('✅ Список цілей збережено: ${goalsList.count}/${GoalsListModel.maxGoals}');
  }

  Future<bool> canAddNewGoal() async {
    final goalsList = await getGoalsList();
    return goalsList.canAddNew;
  }

  Future<int> getAvailableGoalSlots() async {
    final goalsList = await getGoalsList();
    return goalsList.availableSlots;
  }

  Future<void> setPrimaryGoal(String goalId) async {
    final goalsList = await getGoalsList();
    final updatedList = goalsList.setPrimaryGoal(goalId);
    await _saveGoalsList(updatedList);

    final plan = await _getPlanById(goalId);
    if (plan != null) {
      await _saveCurrentPlan(plan);
    }

    debugPrint('⭐ Головна ціль: $goalId');
  }

  Future<void> deleteGoal(String goalId) async {
    final goalsList = await getGoalsList();
    final updatedList = goalsList.removeGoal(goalId);
    await _saveGoalsList(updatedList);

    await _deletePlanById(goalId);
    await clearLocalChatHistory(goalId);

    if (updatedList.primaryGoal != null) {
      final newPrimaryPlan = await _getPlanById(updatedList.primaryGoal!.id);
      if (newPrimaryPlan != null) {
        await _saveCurrentPlan(newPrimaryPlan);
      }
    } else {
      await clearPlan();
    }

    debugPrint('🗑️ Ціль видалено локально: $goalId');

    // 🆕 Баг #9: Синхронізація видалення з Supabase
    if (_supabase.isAuthenticated) {
      try {
        final success = await _supabase.deleteGoal(goalId);
        if (success) {
          debugPrint('☁️ Ціль видалено з Supabase');
        }
      } catch (e) {
        debugPrint('⚠️ Помилка видалення з Supabase: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ALL PLANS STORAGE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _savePlanToAllPlans(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> allPlans = {};
    final allPlansJson = prefs.getString(_keyAllPlans);
    if (allPlansJson != null) {
      allPlans = jsonDecode(allPlansJson) as Map<String, dynamic>;
    }

    allPlans[plan.goal.id] = plan.toJson();

    await prefs.setString(_keyAllPlans, jsonEncode(allPlans));
    debugPrint('💾 План збережено в allPlans: ${plan.goal.id}');
  }

  Future<CareerPlanModel?> _getPlanById(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final allPlansJson = prefs.getString(_keyAllPlans);

    if (allPlansJson == null) return null;

    try {
      final allPlans = jsonDecode(allPlansJson) as Map<String, dynamic>;
      if (allPlans.containsKey(goalId)) {
        return CareerPlanModel.fromJson(allPlans[goalId] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('❌ Помилка читання плану: $e');
    }

    return null;
  }

  Future<void> _deletePlanById(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final allPlansJson = prefs.getString(_keyAllPlans);

    if (allPlansJson == null) return;

    try {
      final allPlans = jsonDecode(allPlansJson) as Map<String, dynamic>;
      allPlans.remove(goalId);
      await prefs.setString(_keyAllPlans, jsonEncode(allPlans));
      debugPrint('🗑️ План видалено з allPlans: $goalId');
    } catch (e) {
      debugPrint('❌ Помилка видалення плану: $e');
    }
  }

  Future<void> _saveCurrentPlan(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));
    await prefs.setInt(_keyMatchScore, plan.matchScore);
    await prefs.setString(_keyGapAnalysis, plan.gapAnalysis);
  }

  // ═══════════════════════════════════════════════════════════════
  // CAREER PLAN - SAVE
  // ═══════════════════════════════════════════════════════════════

  Future<CareerPlanModel> saveGeneratedPlan(GeneratedPlan generated) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyMatchScore, generated.matchScore);
    await prefs.setString(_keyGapAnalysis, generated.gapAnalysis);

    final goalsList = await getGoalsList();
    final isFirstGoal = goalsList.count == 0;

    final goalId = _uuid.v4();
    final goal = GoalModel(
      id: goalId,
      userId: _supabase.userId ?? 'local_user',
      title: generated.goal.title,
      targetSalary: generated.goal.targetSalary,
      isPrimary: isFirstGoal,
      status: 'active',
      createdAt: DateTime.now(),
    );

    // Напрямок 1: "Знайомство" — завжди додається автоматично
    final znayomstvoId = _uuid.v4();
    final List<DirectionModel> directions = [
      DirectionModel(
        id: znayomstvoId,
        goalId: goalId,
        directionNumber: 1,
        title: 'Знайомство',
        description: 'Познайомтесь з додатком та визначте свої пріоритети',
        status: ItemStatus.pending,
        blockNumber: 1,
      ),
    ];

    // Додаємо інші напрямки (2-10) від Gemini
    for (final genDir in generated.directions) {
      directions.add(DirectionModel(
        id: _uuid.v4(),
        goalId: goalId,
        directionNumber: genDir.number,
        title: genDir.title,
        description: genDir.description,
        status: ItemStatus.pending,
        blockNumber: 1,
      ));
    }

    // Кроки 1-10: "Знайомство" (3 статичні + 7 вступних)
    final List<StepModel> steps = _createZnayomstvoSteps(goalId, znayomstvoId);

    // Кроки 11-100: від Gemini
    for (final genStep in generated.steps) {
      final direction = directions.firstWhere(
            (d) => d.directionNumber == genStep.directionNumber,
        orElse: () => directions.first,
      );

      steps.add(StepModel(
        id: _uuid.v4(),
        goalId: goalId,
        directionId: direction.id,
        blockNumber: 1,
        stepNumber: genStep.number,
        localNumber: genStep.localNumber,
        title: genStep.title,
        description: genStep.description,
        status: ItemStatus.pending,
        type: genStep.type,
        difficulty: genStep.difficulty,
        estimatedTime: genStep.estimatedTime,
        expectedOutcome: genStep.expectedOutcome,
      ));
    }

    steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    final plan = CareerPlanModel(
      goal: goal,
      matchScore: generated.matchScore,
      gapAnalysis: generated.gapAnalysis,
      directions: directions,
      steps: steps,
      currentBlock: 1,
    );

    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));
    await _savePlanToAllPlans(plan);

    final summary = GoalSummary.fromCareerPlan(plan);
    final updatedGoalsList = goalsList.addGoal(summary.copyWith(isPrimary: isFirstGoal));
    await _saveGoalsList(updatedGoalsList);

    debugPrint('✅ План збережено локально: ${directions.length} напрямків, ${steps.length} кроків');
    debugPrint('📋 Цілей: ${updatedGoalsList.count}/${GoalsListModel.maxGoals}');

    if (_supabase.isAuthenticated) {
      debugPrint('☁️ Синхронізація плану з Supabase...');
      try {
        final success = await _supabase.saveFullPlan(plan);
        if (success) {
          debugPrint('✅ План синхронізовано з Supabase');
        }
      } catch (e) {
        debugPrint('❌ Помилка синхронізації: $e');
      }
    }

    return plan;
  }

  /// Створює 10 кроків для напрямку "Знайомство"
  List<StepModel> _createZnayomstvoSteps(String goalId, String directionId) {
    final titles = [
      'Познайомитись з додатком',
      'Дізнатись як працює 100Steps',
      'Познайомитись з AI Коучем',
      'Визначити свою головну мотивацію',
      'Оцінити свої сильні сторони',
      'Записати 3 ключові навички для розвитку',
      'Переглянути свій план та 10 напрямків',
      'Обрати пріоритетний напрямок',
      'Скласти план на перший тиждень',
      'Виконати перший крок з пріоритетного напрямку',
    ];
    final descriptions = [
      'Ваш план згенеровано! Ласкаво просимо до 100Steps.',
      'Короткий огляд можливостей додатку та як ефективно працювати з планом.',
      'Напишіть перше повідомлення вашому AI помічнику — він допоможе з будь-яким кроком.',
      'Запишіть, чому ви хочете досягти цієї кар\'єрної цілі. Що вас мотивує найбільше?',
      'Складіть список із 5 своїх найсильніших професійних якостей.',
      'Визначте 3 навички, які потрібно розвинути для досягнення вашої цілі.',
      'Перегляньте всі 10 напрямків вашого плану та ознайомтесь з кроками.',
      'Оберіть напрямок, з якого хочете почати, та запишіть чому саме він.',
      'Визначте 3-5 конкретних дій на найближчий тиждень з вашого плану.',
      'Зробіть перший крок з обраного пріоритетного напрямку та позначте його виконаним.',
    ];

    return List.generate(10, (i) {
      return StepModel(
        id: _uuid.v4(),
        goalId: goalId,
        directionId: directionId,
        blockNumber: 1,
        stepNumber: i + 1,        // 1-10
        localNumber: i + 1,       // 1-10
        title: titles[i],
        description: descriptions[i],
        status: ItemStatus.pending,
        type: i < 4 ? 'quick_win' : (i < 8 ? 'main_work' : 'stretch_goal'),
        difficulty: i < 3 ? 'easy' : (i < 7 ? 'medium' : 'hard'),
        estimatedTime: i < 3 ? '5 хв' : (i < 7 ? '15-30 хв' : '30-60 хв'),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // CAREER PLAN - READ
  // ═══════════════════════════════════════════════════════════════

  Future<CareerPlanModel?> getCareerPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCareerPlan);

    if (jsonStr == null) {
      debugPrint('📭 План не знайдено локально');
      return null;
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final plan = CareerPlanModel.fromJson(json);
      debugPrint('✅ План завантажено: ${plan.directions.length} напрямків, ${plan.steps.length} кроків');
      return plan;
    } catch (e) {
      debugPrint('❌ Помилка читання плану: $e');
      return null;
    }
  }

  Future<CareerPlanModel?> getPlanForGoal(String goalId) async {
    return await _getPlanById(goalId);
  }

  Future<void> savePlanFromCloud(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));
    await prefs.setInt(_keyMatchScore, plan.matchScore);
    await prefs.setString(_keyGapAnalysis, plan.gapAnalysis);
    await _savePlanToAllPlans(plan);

    debugPrint('✅ Хмарний план збережено локально');
  }

  Future<int> getMatchScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMatchScore) ?? 0;
  }

  Future<String?> getGapAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGapAnalysis);
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Позначити крок як виконаний
  Future<void> markStepDone(String stepId) async {
    await _updateStepStatus(stepId, ItemStatus.done);

    // T7: Перевіряємо milestone для оновлення profile_summary
    _checkProfileSummaryMilestone();
  }

  /// T7: Перевірка milestone кожні 20 кроків
  Future<void> _checkProfileSummaryMilestone() async {
    try {
      final profileSummaryService = ProfileSummaryService();
      final shouldTrigger = await profileSummaryService.shouldTriggerMilestone();

      if (shouldTrigger) {
        debugPrint('🎯 Milestone досягнуто! Оновлюємо profile_summary...');
        await profileSummaryService.checkAndUpdateSummary(
          trigger: TriggerType.stepsMilestone,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Помилка перевірки milestone: $e');
    }
  }

  /// Пропустити крок
  Future<void> skipStep(String stepId) async {
    await _updateStepStatus(stepId, ItemStatus.skipped);
  }

  /// Скинути статус кроку
  Future<void> resetStep(String stepId) async {
    await _updateStepStatus(stepId, ItemStatus.pending);
  }

  /// Оновити статус кроку
  Future<void> _updateStepStatus(String stepId, ItemStatus status) async {
    final plan = await getCareerPlan();
    if (plan == null) return;

    // 🆕 Знаходимо крок щоб отримати stepNumber для синхронізації
    final step = plan.steps.firstWhere(
      (s) => s.id == stepId,
      orElse: () => plan.steps.first,
    );

    final updatedPlan = plan.updateStepStatus(stepId, status);

    // Оновлюємо статус напрямку якщо всі кроки виконані
    final updatedDirections = updatedPlan.directions.map((dir) {
      final dirSteps = updatedPlan.getStepsForDirection(dir.id);
      final allDone = dirSteps.every((s) =>
      s.status == ItemStatus.done || s.status == ItemStatus.skipped
      );

      if (allDone && dir.status != ItemStatus.done) {
        return dir.copyWith(status: ItemStatus.done);
      } else if (!allDone && dir.status == ItemStatus.done) {
        return dir.copyWith(status: ItemStatus.inProgress);
      }
      return dir;
    }).toList();

    final finalPlan = updatedPlan.copyWith(directions: updatedDirections);

    // Зберігаємо локально
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(finalPlan.toJson()));

    // Оновлюємо в allPlans
    await _savePlanToAllPlans(finalPlan);

    // Оновлюємо прогрес в списку цілей
    final goalsList = await getGoalsList();
    final updatedGoalsList = goalsList.updateGoalProgress(
      finalPlan.goal.id,
      finalPlan.overallProgress,
      finalPlan.completedStepsCount,
    );
    await _saveGoalsList(updatedGoalsList);

    debugPrint('✅ Крок $stepId (№${step.stepNumber}) оновлено: ${status.name}');

    // ═══════════════════════════════════════════════════════════════
    // 🆕 СИНХРОНІЗАЦІЯ СТАТУСУ З SUPABASE (по stepNumber)
    // ═══════════════════════════════════════════════════════════════
    if (_supabase.isAuthenticated) {
      try {
        await _supabase.updateStepStatusByNumber(
          stepNumber: step.stepNumber,
          status: status.value,
        );
        debugPrint('☁️ Статус кроку #${step.stepNumber} синхронізовано з Supabase');
      } catch (e) {
        debugPrint('⚠️ Помилка синхронізації статусу: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🗑️ Всі дані очищено');
  }

  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCareerPlan);
    await prefs.remove(_keyMatchScore);
    await prefs.remove(_keyGapAnalysis);
    await prefs.remove(_keyAssessmentComplete);
    debugPrint('🗑️ План очищено');
  }

  Future<void> clearAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGoalsList);
    await prefs.remove(_keyPrimaryGoalId);
    await prefs.remove(_keyAllPlans);
    await prefs.remove(_keyCareerPlan);
    await prefs.remove(_keyMatchScore);
    await prefs.remove(_keyGapAnalysis);
    await prefs.remove(_keyAssessmentComplete);
    await prefs.remove(_keyChatHistory);
    debugPrint('🗑️ Всі цілі та плани очищено');
  }

  // ═══════════════════════════════════════════════════════════════
  // DEBUG
  // ═══════════════════════════════════════════════════════════════

  Future<void> debugPrintPlan() async {
    final plan = await getCareerPlan();
    if (plan == null) {
      debugPrint('📭 DEBUG: План не знайдено');
      return;
    }

    debugPrint('═══════════════════════════════════════');
    debugPrint('📋 DEBUG: Збережений план');
    debugPrint('═══════════════════════════════════════');
    debugPrint('🎯 Ціль: ${plan.goal.title}');
    debugPrint('💰 Зарплата: ${plan.goal.targetSalary}');
    debugPrint('📊 Match Score: ${plan.matchScore}%');
    debugPrint('📈 Прогрес: ${plan.overallProgress.toStringAsFixed(1)}%');
    debugPrint('📂 Напрямків: ${plan.directions.length}');
    debugPrint('📝 Кроків: ${plan.steps.length}');
    debugPrint('✅ Виконано: ${plan.completedStepsCount}');
    debugPrint('⏭️ Пропущено: ${plan.skippedStepsCount}');
    debugPrint('⏳ Очікує: ${plan.pendingStepsCount}');
    debugPrint('═══════════════════════════════════════');
  }

  Future<void> debugPrintGoalsList() async {
    final goalsList = await getGoalsList();
    debugPrint('═══════════════════════════════════════');
    debugPrint('📋 DEBUG: Список цілей');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 Кількість: ${goalsList.count}/${GoalsListModel.maxGoals}');
    debugPrint('⭐ Головна: ${goalsList.primaryGoalId}');
    for (final goal in goalsList.goals) {
      debugPrint('  ${goal.isPrimary ? "⭐" : "  "} ${goal.title}');
      debugPrint('     💰 ${goal.targetSalary}');
      debugPrint('     📈 ${goal.progress.toStringAsFixed(0)}%');
    }
    debugPrint('═══════════════════════════════════════');
  }
}
