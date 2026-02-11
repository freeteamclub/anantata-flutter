import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Сервіс для роботи з Gemini AI
/// Синхронізовано з Kotlin версією
/// Версія: 2.5.0 - Ребрендинг на 100StepsCareer
/// Дата: 11.01.2026
///
/// Допрацювання:
/// - #17 - Оновлено модель з gemini-2.0-flash на gemini-3-flash-preview

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _chatModel;
  late GenerativeModel _assessmentModel;
  bool _isInitialized = false;

  // Допрацювання #17: Оновлена назва моделі
  static const String _modelName = 'gemini-3-flash-preview';

  // Singleton
  factory GeminiService() {
    _instance ??= GeminiService._internal();
    return _instance!;
  }

  GeminiService._internal() {
    _initialize();
  }

  void _initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ GEMINI_API_KEY не знайдено в .env');
      return;
    }

    // Модель для чату (більш креативна)
    // Допрацювання #17: Оновлено на gemini-3-flash-preview
    _chatModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );

    // Модель для оцінювання (більш детермінована)
    // Допрацювання #17: Оновлено на gemini-3-flash-preview
    _assessmentModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 16384,
      ),
    );

    _isInitialized = true;
    print('✅ GeminiService ініціалізовано (модель: $_modelName)');
  }

  /// Генерація кар'єрного плану на основі відповідей
  Future<GeneratedPlan> generateCareerPlan(Map<int, String> answers) async {
    if (!_isInitialized) {
      print('❌ GeminiService не ініціалізовано');
      return _getFallbackPlan();
    }

    final prompt = _buildAssessmentPrompt(answers);

    try {
      print('📤 Відправляємо запит до Gemini ($_modelName)...');
      final content = [Content.text(prompt)];
      final response = await _assessmentModel.generateContent(content);

      final text = response.text;
      if (text == null || text.isEmpty) {
        print('❌ Порожня відповідь від Gemini');
        return _getFallbackPlan();
      }

      print('📥 Отримано відповідь, парсимо JSON...');
      return _parseGeneratedPlan(text);
    } catch (e) {
      print('❌ Помилка генерації плану: $e');
      return _getFallbackPlan();
    }
  }

  /// Покращений парсинг JSON з обробкою помилок
  GeneratedPlan _parseGeneratedPlan(String text) {
    try {
      // Крок 1: Видаляємо markdown блоки
      String cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Крок 2: Знаходимо JSON об'єкт
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        print('❌ JSON не знайдено у відповіді');
        print('📄 Текст: ${cleaned.substring(0, cleaned.length.clamp(0, 500))}...');
        return _getFallbackPlan();
      }

      String jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);

      // Крок 3: Виправляємо проблемні символи в рядках JSON
      jsonStr = _fixJsonString(jsonStr);

      // Крок 4: Парсимо JSON
      final Map<String, dynamic> json = jsonDecode(jsonStr);

      print('✅ JSON успішно розпарсено');
      print('🎯 Ціль: ${json['goal']?['title']}');
      print('📊 Match Score: ${json['match_score']}');

      // Конвертуємо в правильний формат
      return _convertToGeneratedPlan(json);
    } catch (e) {
      print('❌ Помилка парсингу JSON: $e');

      // Спробуємо витягти хоча б базову інформацію
      try {
        return _extractBasicInfo(text);
      } catch (e2) {
        print('❌ Не вдалося витягти базову інформацію: $e2');
        return _getFallbackPlan();
      }
    }
  }

  /// Конвертація JSON в GeneratedPlan з правильними параметрами
  GeneratedPlan _convertToGeneratedPlan(Map<String, dynamic> json) {
    // Парсимо goal
    final goalJson = json['goal'] as Map<String, dynamic>? ?? {};
    final goal = GeneratedGoal(
      title: goalJson['title'] as String? ?? 'Кар\'єрний розвиток',
      targetSalary: goalJson['target_salary'] as String? ?? '\$3,000-5,000',
    );

    // Парсимо directions
    final directionsJson = json['directions'] as List<dynamic>? ?? [];
    final List<GeneratedDirection> directions = [];
    final List<GeneratedStep> allSteps = [];

    for (final dirJson in directionsJson) {
      final dirMap = dirJson as Map<String, dynamic>;
      final dirNumber = dirMap['direction_number'] as int? ?? dirMap['number'] as int? ?? 0;

      directions.add(GeneratedDirection(
        number: dirNumber,
        title: dirMap['title'] as String? ?? 'Напрямок $dirNumber',
        description: dirMap['description'] as String? ?? '',
      ));

      // Парсимо кроки для цього напрямку
      final stepsJson = dirMap['steps'] as List<dynamic>? ?? [];
      for (final stepJson in stepsJson) {
        final stepMap = stepJson as Map<String, dynamic>;
        final stepNumber = stepMap['step_number'] as int? ?? stepMap['number'] as int? ?? 0;
        final localNumber = stepMap['local_number'] as int? ?? ((stepNumber - 1) % 10) + 1;

        allSteps.add(GeneratedStep(
          number: stepNumber,
          localNumber: localNumber,
          title: stepMap['title'] as String? ?? 'Крок $stepNumber',
          description: stepMap['description'] as String? ?? '',
          directionNumber: dirNumber,
          type: stepMap['type'] as String?,
          difficulty: stepMap['difficulty'] as String?,
          estimatedTime: stepMap['estimated_time'] as String?,
          expectedOutcome: stepMap['expected_outcome'] as String?,
        ));
      }
    }

    // Якщо кроки не в directions, можливо вони окремо
    if (allSteps.isEmpty && json.containsKey('steps')) {
      final stepsJson = json['steps'] as List<dynamic>? ?? [];
      for (final stepJson in stepsJson) {
        final stepMap = stepJson as Map<String, dynamic>;
        final stepNumber = stepMap['step_number'] as int? ?? stepMap['number'] as int? ?? 0;
        final localNumber = stepMap['local_number'] as int? ?? ((stepNumber - 1) % 10) + 1;
        final dirNumber = stepMap['direction_number'] as int? ?? ((stepNumber - 1) ~/ 10) + 1;

        allSteps.add(GeneratedStep(
          number: stepNumber,
          localNumber: localNumber,
          title: stepMap['title'] as String? ?? 'Крок $stepNumber',
          description: stepMap['description'] as String? ?? '',
          directionNumber: dirNumber,
          type: stepMap['type'] as String?,
          difficulty: stepMap['difficulty'] as String?,
          estimatedTime: stepMap['estimated_time'] as String?,
          expectedOutcome: stepMap['expected_outcome'] as String?,
        ));
      }
    }

    // Сортуємо кроки за номером
    allSteps.sort((a, b) => a.number.compareTo(b.number));

    // Очищаємо gapAnalysis від проблемних символів
    String gapAnalysis = json['gap_analysis'] as String? ?? 'Аналіз недоступний';
    gapAnalysis = gapAnalysis.replaceAll(RegExp(r'[\n\r\t]+'), ' ').trim();

    return GeneratedPlan(
      goal: goal,
      matchScore: json['match_score'] as int? ?? 50,
      gapAnalysis: gapAnalysis,
      directions: directions,
      steps: allSteps,
    );
  }

  /// Виправлення проблемних символів у JSON рядках
  String _fixJsonString(String jsonStr) {
    StringBuffer result = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < jsonStr.length; i++) {
      final char = jsonStr[i];

      if (escaped) {
        result.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        result.write(char);
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        result.write(char);
        continue;
      }

      if (inString) {
        // Всередині рядка замінюємо проблемні символи
        if (char == '\n') {
          result.write(' ');
        } else if (char == '\r') {
          // Пропускаємо
        } else if (char == '\t') {
          result.write(' ');
        } else {
          result.write(char);
        }
      } else {
        result.write(char);
      }
    }

    return result.toString();
  }

  /// Спроба витягти базову інформацію з тексту якщо JSON не парситься
  GeneratedPlan _extractBasicInfo(String text) {
    print('🔍 Спроба витягти базову інформацію...');

    // Шукаємо match_score
    int matchScore = 50;
    final scoreMatch = RegExp(r'"match_score"\s*:\s*(\d+)').firstMatch(text);
    if (scoreMatch != null) {
      matchScore = int.tryParse(scoreMatch.group(1) ?? '50') ?? 50;
      print('📊 Знайдено match_score: $matchScore');
    }

    // Шукаємо goal title
    String goalTitle = 'Кар\'єрний розвиток';
    final goalMatch = RegExp(r'"goal"\s*:\s*\{\s*"title"\s*:\s*"([^"]+)"').firstMatch(text);
    if (goalMatch != null) {
      goalTitle = goalMatch.group(1) ?? goalTitle;
      print('🎯 Знайдено goal: $goalTitle');
    }

    // Шукаємо target_salary
    String targetSalary = '\$3,000-5,000';
    final salaryMatch = RegExp(r'"target_salary"\s*:\s*"([^"]+)"').firstMatch(text);
    if (salaryMatch != null) {
      targetSalary = salaryMatch.group(1) ?? targetSalary;
    }

    // Шукаємо gap_analysis
    String gapAnalysis = 'На основі вашого профілю створено персональний план розвитку.';
    final gapMatch = RegExp(r'"gap_analysis"\s*:\s*"([^"]{10,500})').firstMatch(text);
    if (gapMatch != null) {
      gapAnalysis = gapMatch.group(1) ?? gapAnalysis;
      gapAnalysis = gapAnalysis.replaceAll(RegExp(r'[\n\r\t]'), ' ').trim();
      if (!gapAnalysis.endsWith('.')) {
        gapAnalysis += '...';
      }
      print('📝 Знайдено gap_analysis');
    }

    // Шукаємо directions
    List<GeneratedDirection> directions = [];
    final dirTitles = RegExp(r'"direction_number"\s*:\s*(\d+)[^}]*"title"\s*:\s*"([^"]+)"')
        .allMatches(text);

    for (final match in dirTitles) {
      final num = int.tryParse(match.group(1) ?? '0') ?? 0;
      final title = match.group(2) ?? 'Напрямок $num';

      if (num > 0 && num <= 10) {
        directions.add(GeneratedDirection(
          number: num,
          title: title,
          description: 'Розвиток у напрямку "$title"',
        ));
      }
    }
    print('📂 Знайдено ${directions.length} напрямків');

    // Якщо напрямки не знайдені, створюємо дефолтні
    if (directions.isEmpty) {
      directions = _getDefaultDirections();
    }

    // Генеруємо дефолтні кроки
    final steps = _generateDefaultSteps(directions);

    return GeneratedPlan(
      goal: GeneratedGoal(title: goalTitle, targetSalary: targetSalary),
      matchScore: matchScore,
      gapAnalysis: gapAnalysis,
      directions: directions,
      steps: steps,
    );
  }

  /// Генерація дефолтних кроків для всіх напрямків
  List<GeneratedStep> _generateDefaultSteps(List<GeneratedDirection> directions) {
    List<GeneratedStep> steps = [];

    final defaultTasks = [
      'Провести самоаналіз',
      'Визначити цілі',
      'Скласти план дій',
      'Знайти ресурси',
      'Почати навчання',
      'Практикувати навички',
      'Отримати зворотній зв\'язок',
      'Вдосконалити підхід',
      'Закріпити результат',
      'Перейти на новий рівень',
    ];

    // Градація складності по номеру кроку
    String typeForLocal(int local) {
      if (local <= 4) return 'quick_win';
      if (local <= 8) return 'main_work';
      return 'stretch_goal';
    }
    String difficultyForLocal(int local) {
      if (local <= 2) return 'easy';
      if (local <= 6) return 'medium';
      return 'hard';
    }

    for (final dir in directions) {
      final baseStepNum = (dir.number - 1) * 10 + 1;

      for (int i = 0; i < 10; i++) {
        final local = i + 1;
        steps.add(GeneratedStep(
          number: baseStepNum + i,
          localNumber: local,
          title: '${defaultTasks[i]} у "${dir.title}"',
          description: 'Крок $local для розвитку напрямку "${dir.title}". Виконайте цю задачу для просування до мети.',
          directionNumber: dir.number,
          type: typeForLocal(local),
          difficulty: difficultyForLocal(local),
        ));
      }
    }

    return steps;
  }

  /// Дефолтні напрямки (9 штук, номери 2-10; напрямок 1 "Знайомство" додається в storage)
  List<GeneratedDirection> _getDefaultDirections() {
    final defaultDirs = [
      'Самоаналіз та цілі',
      'Професійні навички',
      'Soft skills',
      'Англійська мова',
      'Нетворкінг',
      'Портфоліо',
      'Фінансова грамотність',
      'Навчання',
      'AI-інструменти',
    ];

    return List.generate(9, (i) {
      return GeneratedDirection(
        number: i + 2,  // 2-10
        title: defaultDirs[i],
        description: 'Напрямок розвитку: ${defaultDirs[i]}',
      );
    });
  }

  /// Промпт для оцінювання
  String _buildAssessmentPrompt(Map<int, String> answers) {
    final formattedAnswers = answers.entries
        .map((e) => 'Питання ${e.key}: ${e.value}')
        .join('\n');

    return '''
Ти — професійний кар'єрний консультант. На основі відповідей користувача створи детальний план розвитку.

ВІДПОВІДІ КОРИСТУВАЧА:
$formattedAnswers

ЗАВДАННЯ:
1. Проаналізуй відповіді та визнач поточний стан користувача
2. Розрахуй match_score (0-100) за формулою:
   - Розрив зарплати (поточна vs бажана): 0-20 балів
   - Розрив посади (поточна vs бажана): 0-20 балів
   - Досвід роботи: 0-20 балів
   - Освіта: 0-20 балів
   - Навички та досягнення: 0-20 балів
3. Створи gap_analysis - короткий текст (2-3 речення) про розрив між поточним станом та метою
4. Створи 9 напрямків розвитку, кожен з 10 кроками (всього 90 кроків)
   ВАЖЛИВО: Генеруй саме 9 напрямків (номери 2-10). Напрямок 1 "Знайомство" додається автоматично додатком.

НАПРЯМКИ — ОБОВ'ЯЗКОВА СТРУКТУРА:
- Напрямки 2-8: кар'єрні (адаптуй під профіль користувача, 7 напрямків)
- Напрямок 9: ОБОВ'ЯЗКОВО "Навчання" (курси, книги, сертифікації)
- Напрямок 10: ОБОВ'ЯЗКОВО "AI-інструменти" (ChatGPT, Copilot, автоматизація)

ГРАДАЦІЯ СКЛАДНОСТІ КРОКІВ (для КОЖНОГО напрямку):
- Крок 1: ознайомчий (quick_win, easy, 30 хв) — перше знайомство з темою
- Кроки 2-4: quick_win (easy/medium, 1-3 дні) — швидкі перемоги
- Кроки 5-8: main_work (medium/hard, 1-4 тижні) — основна робота
- Кроки 9-10: stretch_goal (hard, 1-3 місяці) — амбітні цілі

ВИМОГИ ДО КРОКІВ:
- Назва кроку ПОЧИНАЄТЬСЯ З ДІЄСЛОВА (Створити, Пройти, Написати, Вивчити, тощо)
- Кроки пронумеровані глобально (1-100) та локально (1-10 в межах напрямку)
- Кожен крок має: title, description, type, difficulty, estimated_time, expected_outcome

ВАЖЛИВО: Відповідь ТІЛЬКИ у форматі JSON. Без markdown, без пояснень, тільки чистий JSON.
НЕ використовуй символи нового рядка всередині текстових значень - пиши все в один рядок.

{
  "goal": {
    "title": "Назва кар'єрної цілі",
    "target_salary": "\$X,XXX-X,XXX"
  },
  "match_score": 65,
  "gap_analysis": "Короткий аналіз розриву між поточним станом та метою. Все в один рядок без переносів.",
  "directions": [
    {
      "direction_number": 2,
      "title": "Назва напрямку",
      "description": "Опис напрямку в один рядок",
      "steps": [
        {
          "step_number": 11,
          "local_number": 1,
          "title": "Визначити поточний рівень у ...",
          "description": "Детальний опис кроку в один рядок без переносів",
          "type": "quick_win",
          "difficulty": "easy",
          "estimated_time": "30 хв",
          "expected_outcome": "Чітке розуміння свого поточного рівня"
        }
      ]
    }
  ]
}

Мова відповіді: українська.
''';
  }

  /// Fallback план якщо генерація не вдалась
  GeneratedPlan _getFallbackPlan() {
    final directions = _getDefaultDirections();
    final steps = _generateDefaultSteps(directions);

    return GeneratedPlan(
      goal: GeneratedGoal(
        title: 'Кар\'єрний розвиток',
        targetSalary: '\$3,000-5,000',
      ),
      matchScore: 50,
      gapAnalysis: 'На основі вашого профілю створено базовий план розвитку. Рекомендуємо пройти оцінку ще раз для більш точного аналізу.',
      directions: directions,
      steps: steps,
    );
  }

  /// Генерація наступного блоку кроків
  Future<GeneratedPlan> generateNextBlock({
    required GeneratedPlan previousPlan,
    required int currentBlock,
    required List<String> completedStepIds,
    required List<String> skippedStepIds,
  }) async {
    if (!_isInitialized) {
      return _getFallbackPlan();
    }

    final prompt = '''
Ти — професійний кар'єрний консультант. Користувач завершив блок $currentBlock свого плану.

ПОПЕРЕДНЯ ЦІЛЬ: ${previousPlan.goal.title}
ЦІЛЬОВА ЗАРПЛАТА: ${previousPlan.goal.targetSalary}

СТАТИСТИКА ПОПЕРЕДНЬОГО БЛОКУ:
- Виконано кроків: ${completedStepIds.length}
- Пропущено кроків: ${skippedStepIds.length}

Створи НАСТУПНИЙ блок з 100 новими кроками (10 напрямків × 10 кроків).
Кроки мають бути складнішими та просунутішими ніж у попередньому блоці.

ВАЖЛИВО: Відповідь ТІЛЬКИ у форматі JSON без markdown.
НЕ використовуй символи нового рядка всередині текстових значень.

Формат такий самий як для першого блоку.
Мова: українська.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _assessmentModel.generateContent(content);

      final text = response.text;
      if (text == null) return _getFallbackPlan();

      return _parseGeneratedPlan(text);
    } catch (e) {
      print('❌ Помилка генерації наступного блоку: $e');
      return _getFallbackPlan();
    }
  }

  /// Генерація детального опису кроку
  Future<String> generateStepDetails({
    required String stepTitle,
    required String stepDescription,
    required String directionTitle,
    required String goal,
  }) async {
    if (!_isInitialized) {
      return stepDescription;
    }

    final prompt = '''
Ти — кар'єрний коуч. Дай детальні інструкції для виконання цього кроку.

ЦІЛЬ КОРИСТУВАЧА: $goal
НАПРЯМОК: $directionTitle
КРОК: $stepTitle
КОРОТКИЙ ОПИС: $stepDescription

Напиши детальну інструкцію (200-400 слів):
1. Що конкретно потрібно зробити
2. Які ресурси використати
3. Як перевірити результат
4. Поради для ефективного виконання

Мова: українська.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return response.text ?? stepDescription;
    } catch (e) {
      print('❌ Помилка генерації деталей: $e');
      return stepDescription;
    }
  }

  /// Побудова контексту для AI чату
  /// T7: Додано підтримку profile_summary для персоналізації
  String buildAIContext({
    required CareerPlanModel plan,
    required List<Map<String, String>> chatHistory,
    String? profileSummary,
    int? streakDays,
  }) {
    final directions = plan.directions
        .map((d) => '${d.directionNumber}. ${d.title} (${plan.getDirectionProgress(d.id)}%)')
        .join('\n');

    // Останні 5 виконаних кроків для контексту
    final completedSteps = plan.steps
        .where((s) => s.status == ItemStatus.done)
        .toList();
    final last5Completed = completedSteps.length > 5
        ? completedSteps.sublist(completedSteps.length - 5)
        : completedSteps;
    final completedStepsText = last5Completed.isEmpty
        ? 'Ще немає виконаних кроків'
        : last5Completed.map((s) => '✅ ${s.title}').join('\n');

    // Наступний рекомендований крок
    final nextStep = plan.nextStep;
    final nextStepText = nextStep != null
        ? '${nextStep.stepNumber}. ${nextStep.title}'
        : 'Всі кроки виконано!';

    final history = chatHistory
        .take(10)
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');

    // T7: Profile summary блок
    final profileBlock = (profileSummary != null && profileSummary.isNotEmpty)
        ? '''
ПРОФІЛЬ КОРИСТУВАЧА:
$profileSummary
'''
        : '';

    // Streak info
    final streakText = (streakDays != null && streakDays > 0)
        ? 'СЕРІЯ: $streakDays днів поспіль 🔥'
        : '';

    return '''
Ти — Коуч, персональний AI-помічник в додатку 100Steps Career.
$profileBlock
ПОТОЧНА ЦІЛЬ: ${plan.goal.title}
ЦІЛЬОВА ЗАРПЛАТА: ${plan.goal.targetSalary}

ПРОГРЕС:
- Виконано: ${completedSteps.length}/${plan.steps.length} кроків (${plan.overallProgress.toStringAsFixed(0)}%)
${streakText.isNotEmpty ? '- $streakText' : ''}
- Поточний блок: ${plan.currentBlock}

НАПРЯМКИ:
$directions

ОСТАННІ ВИКОНАНІ КРОКИ:
$completedStepsText

НАСТУПНИЙ РЕКОМЕНДОВАНИЙ КРОК:
$nextStepText

ІСТОРІЯ ЧАТУ:
$history

ПРИ ПЕРШОМУ ПОВІДОМЛЕННІ В СЕСІЇ:
Привітайся, покажи короткий аналіз прогресу, дай конкретну рекомендацію на сьогодні та запропонуй варіанти дій.

РОЛЬ:
- Проактивний стратег (сам пропонує, не чекає)
- Кар'єрний коуч (мотивує, дає feedback)
- Аналітик (бачить прогрес, знаходить патерни)

ПРАВИЛА:
- Завжди конкретні поради під цього користувача
- Зв'язуй кроки між собою
- Пропонуй варіанти дій
- Тон: дружній професіонал
- Мова: українська

ФОРМАТ ВИБОРУ (ОБОВ'ЯЗКОВО):
Коли пропонуєш варіанти дій, оберни їх у спеціальний блок:
[CHOICES]
Варіант 1
Варіант 2
Варіант 3
[/CHOICES]
Використовуй це в кінці повідомлення коли є 2-4 варіанти дій для користувача.
''';
  }

  /// Чат з контекстом
  Future<String> sendMessageWithContext({
    required String message,
    required String context,
  }) async {
    if (!_isInitialized) {
      return 'Вибачте, сервіс тимчасово недоступний.';
    }

    final prompt = '''
$context

ПОВІДОМЛЕННЯ КОРИСТУВАЧА:
$message

Дай корисну відповідь як кар'єрний коуч:
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return response.text ?? 'Не вдалося отримати відповідь.';
    } catch (e) {
      print('❌ Помилка чату: $e');
      return 'Виникла помилка. Спробуйте ще раз.';
    }
  }

  /// Простий чат без контексту
  Future<String> chat(String message) async {
    if (!_isInitialized) {
      return 'Сервіс недоступний.';
    }

    try {
      final content = [Content.text(message)];
      final response = await _chatModel.generateContent(content);
      return response.text ?? 'Немає відповіді.';
    } catch (e) {
      print('❌ Помилка чату: $e');
      return 'Виникла помилка. Спробуйте ще раз.';
    }
  }

  /// Генерація поради на основі відповідей
  Future<String> generateAdvice(String question, Map<int, String> answers) async {
    if (!_isInitialized) {
      return 'Продовжуйте працювати над своїми цілями!';
    }

    final formattedAnswers = answers.entries
        .take(5)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    final prompt = '''
На основі профілю користувача ($formattedAnswers), 
дай коротку пораду (2-4 речення) щодо: $question
Мова: українська.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return response.text ?? 'Вірте в себе та дійте!';
    } catch (e) {
      return 'Кожен крок наближає вас до мети!';
    }
  }
}