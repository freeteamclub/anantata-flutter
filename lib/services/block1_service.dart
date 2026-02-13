import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Сервіс для Блоку 1 "Знайомство"
/// 3 статичні кроки + перший крок кожного з 10 напрямків = 13 кроків
/// Block 1 — це гейт на основному плані, а не окремий екран
/// Версія: 2.0.0
/// Дата: 11.02.2026

enum Block1Action {
  autoDone,      // Крок 1 — СТАРТ (авто-done)
  tutorial,      // Крок 2 — НАВЧАННЯ
  openChat,      // Крок 3 — ДЖАРВІС (відкриває чат)
}

class Block1Step {
  final int number;           // 1-3
  final String title;
  final String description;
  final Block1Action action;
  final bool isDone;

  Block1Step({
    required this.number,
    required this.title,
    required this.description,
    required this.action,
    required this.isDone,
  });
}

class Block1Service {
  static const String _keyBlock1Completed = 'block1_completed';
  static const String _keyBlock1Step1Done = 'block1_step1_done';
  static const String _keyBlock1Step2Done = 'block1_step2_done';
  static const String _keyBlock1Step3Done = 'block1_step3_done';

  Future<bool> isBlock1Completed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBlock1Completed) ?? false;
  }

  Future<void> completeBlock1() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBlock1Completed, true);
  }

  Future<void> initializeBlock1() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBlock1Step1Done, true);
  }

  Future<bool> isStaticStepDone(int stepNumber) async {
    final prefs = await SharedPreferences.getInstance();
    switch (stepNumber) {
      case 1: return prefs.getBool(_keyBlock1Step1Done) ?? false;
      case 2: return prefs.getBool(_keyBlock1Step2Done) ?? false;
      case 3: return prefs.getBool(_keyBlock1Step3Done) ?? false;
      default: return false;
    }
  }

  Future<void> markStaticStepDone(int stepNumber) async {
    final prefs = await SharedPreferences.getInstance();
    switch (stepNumber) {
      case 1: await prefs.setBool(_keyBlock1Step1Done, true); break;
      case 2: await prefs.setBool(_keyBlock1Step2Done, true); break;
      case 3: await prefs.setBool(_keyBlock1Step3Done, true); break;
    }
  }

  /// Отримати 3 статичні кроки
  Future<List<Block1Step>> getStaticSteps() async {
    return [
      Block1Step(
        number: 1,
        title: 'Познайомитись з додатком',
        description: 'Ваш план згенеровано! Ласкаво просимо до 100StepsCareer.',
        action: Block1Action.autoDone,
        isDone: await isStaticStepDone(1),
      ),
      Block1Step(
        number: 2,
        title: 'Дізнатись як працює 100StepsCareer',
        description: 'Короткий огляд можливостей додатку.',
        action: Block1Action.tutorial,
        isDone: await isStaticStepDone(2),
      ),
      Block1Step(
        number: 3,
        title: 'Познайомитись з AI Коучем',
        description: 'Напишіть перше повідомлення вашому AI помічнику.',
        action: Block1Action.openChat,
        isDone: await isStaticStepDone(3),
      ),
    ];
  }

  /// Кількість виконаних кроків Block 1 (статичні + перші кроки напрямків)
  Future<int> getDoneCount(CareerPlanModel plan) async {
    int count = 0;
    for (int i = 1; i <= 3; i++) {
      if (await isStaticStepDone(i)) count++;
    }
    // Перший крок кожного напрямку
    for (final dir in plan.directions) {
      final steps = plan.getStepsForDirection(dir.id);
      if (steps.isNotEmpty && steps.first.status == ItemStatus.done) {
        count++;
      }
    }
    return count;
  }

  /// Загальна кількість кроків Block 1
  int getTotalCount(CareerPlanModel plan) {
    return 3 + plan.directions.length; // 3 статичні + 10 перших кроків = 13
  }

  /// Перевірити чи Block 1 повністю завершений
  /// 3 статичні кроки done + перший крок кожного напрямку done
  Future<bool> isBlock1Complete(CareerPlanModel plan) async {
    // Перевіряємо статичні
    for (int i = 1; i <= 3; i++) {
      if (!(await isStaticStepDone(i))) return false;
    }
    // Перевіряємо перші кроки напрямків
    for (final dir in plan.directions) {
      final steps = plan.getStepsForDirection(dir.id);
      if (steps.isEmpty || steps.first.status != ItemStatus.done) return false;
    }
    return true;
  }

  /// Чи є крок розблокованим під час Block 1
  /// Розблоковані: localNumber == 1 (перший крок кожного напрямку)
  bool isStepUnlocked(StepModel step) {
    return step.localNumber == 1;
  }
}
