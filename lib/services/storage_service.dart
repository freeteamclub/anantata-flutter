import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Сервіс для локального збереження даних
/// Версія: 4.0.0 - Підтримка до 3 цілей
/// Дата: 15.12.2025

class StorageService {
  static const String _keyUserName = 'user_name';
  static const String _keyAssessmentComplete = 'assessment_complete';
  static const String _keyAssessmentAnswers = 'assessment_answers';
  static const String _keyCareerPlan = 'career_plan';
  static const String _keyMatchScore = 'match_score';
  static const String _keyGapAnalysis = 'gap_analysis';

  // 🆕 Ключі для списку цілей
  static const String _keyGoalsList = 'goals_list';
  static const String _keyPrimaryGoalId = 'primary_goal_id';
  static const String _keyAllPlans = 'all_plans'; // Зберігає всі плани

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

    // Синхронізуємо з Supabase
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
  // 🆕 GOALS LIST (до 3 цілей)
  // ═══════════════════════════════════════════════════════════════

  /// Отримати список всіх цілей
  Future<GoalsListModel> getGoalsList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyGoalsList);

    if (jsonStr == null) {
      // Якщо немає списку, перевіряємо чи є старий план
      final oldPlan = await getCareerPlan();
      if (oldPlan != null) {
        // Мігруємо старий план в новий формат
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

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GoalsListModel.fromJson(json);
    } catch (e) {
      debugPrint('❌ Помилка читання списку цілей: $e');
      return GoalsListModel.empty();
    }
  }

  /// Зберегти список цілей
  Future<void> _saveGoalsList(GoalsListModel goalsList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoalsList, jsonEncode(goalsList.toJson()));
    if (goalsList.primaryGoalId != null) {
      await prefs.setString(_keyPrimaryGoalId, goalsList.primaryGoalId!);
    }
    debugPrint('✅ Список цілей збережено: ${goalsList.count}/${GoalsListModel.maxGoals}');
  }

  /// Чи можна додати нову ціль
  Future<bool> canAddNewGoal() async {
    final goalsList = await getGoalsList();
    return goalsList.canAddNew;
  }

  /// Кількість доступних слотів для цілей
  Future<int> getAvailableGoalSlots() async {
    final goalsList = await getGoalsList();
    return goalsList.availableSlots;
  }

  /// Встановити головну ціль
  Future<void> setPrimaryGoal(String goalId) async {
    final goalsList = await getGoalsList();
    final updatedList = goalsList.setPrimaryGoal(goalId);
    await _saveGoalsList(updatedList);

    // Завантажуємо план цієї цілі як поточний
    final plan = await _getPlanById(goalId);
    if (plan != null) {
      await _saveCurrentPlan(plan);
    }

    debugPrint('⭐ Головна ціль: $goalId');
  }

  /// Видалити ціль
  Future<void> deleteGoal(String goalId) async {
    final goalsList = await getGoalsList();
    final updatedList = goalsList.removeGoal(goalId);
    await _saveGoalsList(updatedList);

    // Видаляємо план
    await _deletePlanById(goalId);

    // Якщо це була поточна ціль, завантажуємо нову головну
    if (updatedList.primaryGoal != null) {
      final newPrimaryPlan = await _getPlanById(updatedList.primaryGoal!.id);
      if (newPrimaryPlan != null) {
        await _saveCurrentPlan(newPrimaryPlan);
      }
    } else {
      // Очищаємо поточний план якщо цілей не залишилось
      await clearPlan();
    }

    debugPrint('🗑️ Ціль видалено: $goalId');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆕 ALL PLANS STORAGE (зберігання всіх планів)
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти план в загальне сховище
  Future<void> _savePlanToAllPlans(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();

    // Отримуємо всі плани
    Map<String, dynamic> allPlans = {};
    final allPlansJson = prefs.getString(_keyAllPlans);
    if (allPlansJson != null) {
      allPlans = jsonDecode(allPlansJson) as Map<String, dynamic>;
    }

    // Додаємо/оновлюємо план
    allPlans[plan.goal.id] = plan.toJson();

    // Зберігаємо
    await prefs.setString(_keyAllPlans, jsonEncode(allPlans));
    debugPrint('💾 План збережено в allPlans: ${plan.goal.id}');
  }

  /// Отримати план за ID
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

  /// Видалити план за ID
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

  /// Зберегти як поточний план
  Future<void> _saveCurrentPlan(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));
    await prefs.setInt(_keyMatchScore, plan.matchScore);
    await prefs.setString(_keyGapAnalysis, plan.gapAnalysis);
  }

  // ═══════════════════════════════════════════════════════════════
  // CAREER PLAN - SAVE
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти згенерований план та конвертувати в CareerPlanModel
  Future<CareerPlanModel> saveGeneratedPlan(GeneratedPlan generated) async {
    final prefs = await SharedPreferences.getInstance();

    // Зберігаємо match score та gap analysis окремо для швидкого доступу
    await prefs.setInt(_keyMatchScore, generated.matchScore);
    await prefs.setString(_keyGapAnalysis, generated.gapAnalysis);

    // Перевіряємо чи можна додати нову ціль
    final goalsList = await getGoalsList();
    final isFirstGoal = goalsList.count == 0;

    // Створюємо GoalModel
    final goalId = _uuid.v4();
    final goal = GoalModel(
      id: goalId,
      userId: _supabase.userId ?? 'local_user',
      title: generated.goal.title,
      targetSalary: generated.goal.targetSalary,
      isPrimary: isFirstGoal, // Перша ціль автоматично стає головною
      status: 'active',
      createdAt: DateTime.now(),
    );

    // Створюємо DirectionModels
    final List<DirectionModel> directions = [];
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

    // Створюємо StepModels
    final List<StepModel> steps = [];
    for (final genStep in generated.steps) {
      // Знаходимо відповідний напрямок
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
      ));
    }

    // Сортуємо кроки
    steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    // Створюємо повну модель
    final plan = CareerPlanModel(
      goal: goal,
      matchScore: generated.matchScore,
      gapAnalysis: generated.gapAnalysis,
      directions: directions,
      steps: steps,
      currentBlock: 1,
    );

    // Зберігаємо в SharedPreferences (поточний план)
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));

    // 🆕 Зберігаємо в загальне сховище планів
    await _savePlanToAllPlans(plan);

    // 🆕 Додаємо до списку цілей
    final summary = GoalSummary.fromCareerPlan(plan);
    final updatedGoalsList = goalsList.addGoal(summary.copyWith(isPrimary: isFirstGoal));
    await _saveGoalsList(updatedGoalsList);

    debugPrint('✅ План збережено локально: ${directions.length} напрямків, ${steps.length} кроків');
    debugPrint('📋 Цілей: ${updatedGoalsList.count}/${GoalsListModel.maxGoals}');

    // ═══════════════════════════════════════════════════════════════
    // СИНХРОНІЗАЦІЯ З SUPABASE
    // ═══════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════
  // CAREER PLAN - READ
  // ═══════════════════════════════════════════════════════════════

  /// Отримати збережений план (поточний/головний)
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

  /// Отримати план для конкретної цілі
  Future<CareerPlanModel?> getPlanForGoal(String goalId) async {
    return await _getPlanById(goalId);
  }

  /// Зберегти план з хмари локально
  Future<void> savePlanFromCloud(CareerPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));
    await prefs.setInt(_keyMatchScore, plan.matchScore);
    await prefs.setString(_keyGapAnalysis, plan.gapAnalysis);

    // Також зберігаємо в allPlans
    await _savePlanToAllPlans(plan);

    debugPrint('✅ Хмарний план збережено локально');
  }

  /// Отримати match score
  Future<int> getMatchScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMatchScore) ?? 0;
  }

  /// Отримати gap analysis
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

    // 🆕 Оновлюємо в allPlans
    await _savePlanToAllPlans(finalPlan);

    // 🆕 Оновлюємо прогрес в списку цілей
    final goalsList = await getGoalsList();
    final updatedGoalsList = goalsList.updateGoalProgress(
      finalPlan.goal.id,
      finalPlan.overallProgress,
      finalPlan.completedStepsCount,
    );
    await _saveGoalsList(updatedGoalsList);

    debugPrint('✅ Крок $stepId оновлено: ${status.name}');

    // ═══════════════════════════════════════════════════════════════
    // СИНХРОНІЗАЦІЯ СТАТУСУ З SUPABASE
    // ═══════════════════════════════════════════════════════════════
    if (_supabase.isAuthenticated) {
      try {
        await _supabase.updateStepStatus(stepId, status.value);
        debugPrint('☁️ Статус синхронізовано з Supabase');
      } catch (e) {
        debugPrint('⚠️ Помилка синхронізації статусу: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR DATA
  // ═══════════════════════════════════════════════════════════════

  /// Очистити всі дані
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🗑️ Всі дані очищено');
  }

  /// Очистити тільки поточний план
  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCareerPlan);
    await prefs.remove(_keyMatchScore);
    await prefs.remove(_keyGapAnalysis);
    await prefs.remove(_keyAssessmentComplete);
    debugPrint('🗑️ План очищено');
  }

  /// Очистити всі цілі та плани
  Future<void> clearAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGoalsList);
    await prefs.remove(_keyPrimaryGoalId);
    await prefs.remove(_keyAllPlans);
    await prefs.remove(_keyCareerPlan);
    await prefs.remove(_keyMatchScore);
    await prefs.remove(_keyGapAnalysis);
    await prefs.remove(_keyAssessmentComplete);
    debugPrint('🗑️ Всі цілі та плани очищено');
  }

  // ═══════════════════════════════════════════════════════════════
  // DEBUG
  // ═══════════════════════════════════════════════════════════════

  /// Вивести інформацію про збережені дані
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

  /// Вивести інформацію про всі цілі
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