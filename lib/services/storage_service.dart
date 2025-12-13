import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:uuid/uuid.dart';

/// Сервіс для локального збереження даних
/// Версія: 2.0.0 - Повна підтримка CareerPlanModel
/// Дата: 13.12.2025

class StorageService {
  static const String _keyUserName = 'user_name';
  static const String _keyAssessmentComplete = 'assessment_complete';
  static const String _keyAssessmentAnswers = 'assessment_answers';
  static const String _keyCareerPlan = 'career_plan';
  static const String _keyMatchScore = 'match_score';
  static const String _keyGapAnalysis = 'gap_analysis';

  final Uuid _uuid = const Uuid();

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
  }

  Future<Map<int, String>?> getAssessmentAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAssessmentAnswers);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      return jsonMap.map((key, value) => MapEntry(int.parse(key), value as String));
    } catch (e) {
      print('❌ Помилка читання відповідей: $e');
      return null;
    }
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

    // Створюємо GoalModel
    final goalId = _uuid.v4();
    final goal = GoalModel(
      id: goalId,
      userId: 'local_user',
      title: generated.goal.title,
      targetSalary: generated.goal.targetSalary,
      isPrimary: true,
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

    // Зберігаємо в SharedPreferences
    await prefs.setString(_keyCareerPlan, jsonEncode(plan.toJson()));

    print('✅ План збережено: ${directions.length} напрямків, ${steps.length} кроків');
    return plan;
  }

  // ═══════════════════════════════════════════════════════════════
  // CAREER PLAN - READ
  // ═══════════════════════════════════════════════════════════════

  /// Отримати збережений план
  Future<CareerPlanModel?> getCareerPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCareerPlan);

    if (jsonStr == null) {
      print('📭 План не знайдено');
      return null;
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final plan = CareerPlanModel.fromJson(json);
      print('✅ План завантажено: ${plan.directions.length} напрямків, ${plan.steps.length} кроків');
      return plan;
    } catch (e) {
      print('❌ Помилка читання плану: $e');
      return null;
    }
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

    // Зберігаємо
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCareerPlan, jsonEncode(finalPlan.toJson()));

    print('✅ Крок $stepId оновлено: ${status.name}');
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR DATA
  // ═══════════════════════════════════════════════════════════════

  /// Очистити всі дані
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🗑️ Всі дані очищено');
  }

  /// Очистити тільки план
  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCareerPlan);
    await prefs.remove(_keyMatchScore);
    await prefs.remove(_keyGapAnalysis);
    await prefs.remove(_keyAssessmentComplete);
    print('🗑️ План очищено');
  }

  // ═══════════════════════════════════════════════════════════════
  // DEBUG
  // ═══════════════════════════════════════════════════════════════

  /// Вивести інформацію про збережені дані
  Future<void> debugPrint() async {
    final plan = await getCareerPlan();
    if (plan == null) {
      print('📭 DEBUG: План не знайдено');
      return;
    }

    print('═══════════════════════════════════════');
    print('📋 DEBUG: Збережений план');
    print('═══════════════════════════════════════');
    print('🎯 Ціль: ${plan.goal.title}');
    print('💰 Зарплата: ${plan.goal.targetSalary}');
    print('📊 Match Score: ${plan.matchScore}%');
    print('📈 Прогрес: ${plan.overallProgress.toStringAsFixed(1)}%');
    print('📂 Напрямків: ${plan.directions.length}');
    print('📝 Кроків: ${plan.steps.length}');
    print('✅ Виконано: ${plan.completedStepsCount}');
    print('⏭️ Пропущено: ${plan.skippedStepsCount}');
    print('⏳ Очікує: ${plan.pendingStepsCount}');
    print('═══════════════════════════════════════');
  }
}