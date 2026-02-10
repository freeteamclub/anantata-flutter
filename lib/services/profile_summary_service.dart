import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/services/supabase_service.dart';

/// Сервіс для генерації та оновлення Profile Summary
/// Версія: 1.0.0
/// Тікет: T7
/// Дата: 09.02.2026
///
/// Логіка:
/// - CREATE: Після assessment створюється перший summary
/// - APPEND: При змінах профілю або кожні 20 кроків summary ДОПОВНЮЄТЬСЯ
/// - Сирі дані зберігаються окремо, summary тільки розширюється

class ProfileSummaryService {
  static ProfileSummaryService? _instance;
  final SupabaseService _supabase = SupabaseService();
  late GenerativeModel _model;
  bool _isInitialized = false;

  // Локальне збереження для гостей
  static const String _localKey = 'profile_summary';

  // Singleton
  factory ProfileSummaryService() {
    _instance ??= ProfileSummaryService._internal();
    return _instance!;
  }

  ProfileSummaryService._internal() {
    _initialize();
  }

  void _initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ GEMINI_API_KEY не знайдено');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 1024,
      ),
    );

    _isInitialized = true;
    debugPrint('✅ ProfileSummaryService ініціалізовано');
  }

  /// Тригер: Перевірка чи потрібно оновити summary
  /// [goalTitle] та [targetSalary] — опційні, передаються напряму коли
  /// дані ще не встигли синхронізуватись з Supabase (наприклад, одразу після assessment)
  Future<void> checkAndUpdateSummary({
    required TriggerType trigger,
    Map<String, dynamic>? newData,
    String? goalTitle,
    String? targetSalary,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ ProfileSummaryService не ініціалізовано');
      return;
    }

    final existingSummary = await getSummary();

    if (existingSummary == null || existingSummary.isEmpty) {
      // Перше створення
      if (trigger == TriggerType.assessmentCompleted) {
        await _createInitialSummary(
          goalTitle: goalTitle,
          targetSalary: targetSalary,
        );
      }
    } else {
      // Доповнення існуючого
      if (trigger == TriggerType.stepsMilestone) {
        await _appendToSummary(
          existingSummary: existingSummary,
          trigger: trigger,
          newData: newData,
        );
      } else if (trigger == TriggerType.profileChanged) {
        await _appendToSummary(
          existingSummary: existingSummary,
          trigger: trigger,
          newData: newData,
        );
      }
    }
  }

  /// Перевірка milestone (кожні 20 кроків)
  Future<bool> shouldTriggerMilestone() async {
    final completedCount = await _supabase.getCompletedStepsCount();
    // Тригер на 20, 40, 60, 80, 100 кроків
    return completedCount > 0 && completedCount % 20 == 0;
  }

  /// CREATE: Перше створення summary після assessment
  /// [goalTitle] та [targetSalary] — передаються напряму щоб уникнути race condition з Supabase
  Future<void> _createInitialSummary({
    String? goalTitle,
    String? targetSalary,
  }) async {
    debugPrint('📝 Створення першого profile_summary...');

    try {
      // Збираємо дані
      final profile = await _supabase.getProfile();
      final assessmentAnswers = await _supabase.getAssessmentAnswers();

      // Використовуємо передані дані або шукаємо в Supabase як fallback
      String resolvedGoalTitle = goalTitle ?? '';
      String resolvedTargetSalary = targetSalary ?? '';

      if (resolvedGoalTitle.isEmpty) {
        final goal = await _supabase.getActiveGoal();
        if (goal == null) {
          debugPrint('❌ Немає активної цілі');
          return;
        }
        resolvedGoalTitle = goal['title'] ?? '';
        resolvedTargetSalary = goal['target_salary'] ?? '';
      }

      debugPrint('🎯 Ціль для summary: $resolvedGoalTitle');

      final prompt = _buildCreatePrompt(
        name: profile?['name'] ?? _supabase.userName ?? 'Користувач',
        goal: resolvedGoalTitle,
        targetSalary: resolvedTargetSalary,
        assessmentAnswers: assessmentAnswers,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final summary = response.text;

      if (summary != null && summary.isNotEmpty) {
        await _saveSummary(summary);
        debugPrint('✅ Перший profile_summary створено');
      }
    } catch (e) {
      debugPrint('❌ Помилка створення summary: $e');
    }
  }

  /// APPEND: Доповнення існуючого summary
  Future<void> _appendToSummary({
    required String existingSummary,
    required TriggerType trigger,
    Map<String, dynamic>? newData,
  }) async {
    debugPrint('📝 Доповнення profile_summary (trigger: ${trigger.name})...');

    try {
      // Збираємо нові дані
      final recentSteps = await _supabase.getRecentCompletedSteps(limit: 10);
      final completedCount = await _supabase.getCompletedStepsCount();
      final goal = await _supabase.getActiveGoal();

      final prompt = _buildAppendPrompt(
        existingSummary: existingSummary,
        trigger: trigger,
        recentSteps: recentSteps,
        completedCount: completedCount,
        goal: goal,
        newData: newData,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final appendedSummary = response.text;

      if (appendedSummary != null && appendedSummary.isNotEmpty) {
        await _saveSummary(appendedSummary);
        debugPrint('✅ Profile_summary доповнено');
      }
    } catch (e) {
      debugPrint('❌ Помилка доповнення summary: $e');
    }
  }

  /// Промпт для СТВОРЕННЯ першого summary
  String _buildCreatePrompt({
    required String name,
    required String goal,
    required String targetSalary,
    Map<String, dynamic>? assessmentAnswers,
  }) {
    final answersText = assessmentAnswers != null
        ? assessmentAnswers.entries.map((e) => '${e.key}: ${e.value}').join('\n')
        : 'Немає даних';

    return '''
На основі даних користувача створи стислий професійний профіль (200-300 слів).

ІМ'Я: $name
ЦІЛЬ: $goal
ЦІЛЬОВА ЗАРПЛАТА: $targetSalary

ВІДПОВІДІ ASSESSMENT:
$answersText

ФОРМАТ ВІДПОВІДІ:
Напиши текст від третьої особи, що описує:
1. Поточний кар'єрний стан користувача
2. Ключові сильні сторони
3. Зони для розвитку
4. Основні характеристики та мотивацію

ВАЖЛИВО:
- Пиши українською
- Тон: професійний але дружній
- Не використовуй заголовки та форматування
- Просто суцільний текст 200-300 слів
- Це буде використовуватись як контекст для AI-помічника
''';
  }

  /// Промпт для ДОПОВНЕННЯ summary
  String _buildAppendPrompt({
    required String existingSummary,
    required TriggerType trigger,
    required List<Map<String, dynamic>> recentSteps,
    required int completedCount,
    Map<String, dynamic>? goal,
    Map<String, dynamic>? newData,
  }) {
    final stepsText = recentSteps.isNotEmpty
        ? recentSteps.map((s) => '- ${s['title']}').join('\n')
        : 'Немає нових кроків';

    String triggerContext = '';
    switch (trigger) {
      case TriggerType.stepsMilestone:
        triggerContext = 'Користувач досяг milestone: $completedCount виконаних кроків!';
        break;
      case TriggerType.profileChanged:
        triggerContext = 'Користувач оновив свій профіль.';
        if (newData != null) {
          triggerContext += '\nНові дані: ${newData.toString()}';
        }
        break;
      default:
        triggerContext = 'Регулярне оновлення профілю.';
    }

    return '''
Ось поточний профіль користувача:
---
$existingSummary
---

НОВІ ДАНІ ДЛЯ ДОПОВНЕННЯ:

$triggerContext

ОСТАННІ ВИКОНАНІ КРОКИ:
$stepsText

ЗАГАЛЬНИЙ ПРОГРЕС: $completedCount/100 кроків

ЗАВДАННЯ:
Доповни профіль новою інформацією.

ПРАВИЛА:
1. ЗБЕРЕЖИ всі попередні дані та факти
2. ДОДАЙ нові досягнення, навички та інсайти
3. НЕ видаляй та не переписуй існуючу інформацію
4. Результат має бути розширеною версією (максимум 400 слів)
5. Пиши українською, від третьої особи
6. Без заголовків, просто суцільний текст

Якщо нових суттєвих даних немає — поверни оригінальний текст без змін.
''';
  }

  /// Зберегти summary (Supabase + локально)
  Future<void> _saveSummary(String summary) async {
    // Завжди зберігаємо локально
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, summary);
    debugPrint('💾 Profile summary збережено локально');

    // Якщо авторизований — також в Supabase
    if (_supabase.isAuthenticated) {
      await _supabase.saveProfileSummary(summary);
      debugPrint('☁️ Profile summary збережено в Supabase');
    }
  }

  /// Отримати поточний summary (Supabase або локально)
  Future<String?> getSummary() async {
    // Спочатку пробуємо Supabase
    if (_supabase.isAuthenticated) {
      final cloudSummary = await _supabase.getProfileSummary();
      if (cloudSummary != null && cloudSummary.isNotEmpty) {
        return cloudSummary;
      }
    }

    // Fallback — локальне сховище
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localKey);
  }

  /// Примусове оновлення summary (для тестування)
  Future<void> forceRefresh() async {
    final existingSummary = await getSummary();
    if (existingSummary == null || existingSummary.isEmpty) {
      await _createInitialSummary();
    } else {
      await _appendToSummary(
        existingSummary: existingSummary,
        trigger: TriggerType.stepsMilestone,
      );
    }
  }
}

/// Типи тригерів для оновлення profile summary
enum TriggerType {
  /// Після завершення assessment
  assessmentCompleted,

  /// Після зміни профілю
  profileChanged,

  /// Кожні 20 виконаних кроків
  stepsMilestone,
}
