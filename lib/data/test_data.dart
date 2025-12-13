/// Тестові дані для перевірки UI
/// 10 напрямків × 10 кроків = 100 кроків
/// Версія: 1.0
/// Дата: 12.12.2025

import 'package:anantata/models/career_plan_model.dart';

// ═══════════════════════════════════════════════════════════════
// ТЕСТОВІ ДАНІ
// ═══════════════════════════════════════════════════════════════

class TestData {
  // ID для тестових даних
  static const String testGoalId = 'test-goal-001';
  static const String testUserId = 'test-user-001';

  /// Отримати тестовий CareerPlanModel
  static CareerPlanModel getTestCareerPlan() {
    final goal = _createTestGoal();
    final directions = _createTestDirections();
    final steps = _createTestSteps(directions);

    return CareerPlanModel(
      goal: goal,
      matchScore: 72,
      gapAnalysis: 'Вам потрібно покращити навички Flutter та Dart. '
          'Рекомендуємо пройти курси з State Management та архітектури додатків. '
          'Ваш досвід у веб-розробці буде корисним при вивченні Flutter.',
      directions: directions,
      steps: steps,
      currentBlock: 1,
    );
  }

  /// Створити тестову ціль
  static GoalModel _createTestGoal() {
    return GoalModel(
      id: testGoalId,
      userId: testUserId,
      title: 'Стати Senior Flutter Developer',
      targetSalary: '\$5,000/міс',
      isPrimary: true,
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Створити 10 тестових напрямків
  static List<DirectionModel> _createTestDirections() {
    final directionsData = [
      {
        'number': 1,
        'title': 'Основи Dart',
        'description': 'Синтаксис мови, типи даних, ООП, async/await',
      },
      {
        'number': 2,
        'title': 'Flutter Widgets',
        'description': 'Базові та кастомні віджети, композиція, lifecycle',
      },
      {
        'number': 3,
        'title': 'State Management',
        'description': 'Provider, Riverpod, BLoC, GetX',
      },
      {
        'number': 4,
        'title': 'Робота з API',
        'description': 'REST API, HTTP, Dio, JSON serialization',
      },
      {
        'number': 5,
        'title': 'Локальне сховище',
        'description': 'SharedPreferences, SQLite, Hive, Isar',
      },
      {
        'number': 6,
        'title': 'UI/UX та анімації',
        'description': 'Material Design, анімації, responsive design',
      },
      {
        'number': 7,
        'title': 'Тестування',
        'description': 'Unit tests, Widget tests, Integration tests',
      },
      {
        'number': 8,
        'title': 'Архітектура',
        'description': 'Clean Architecture, MVVM, Repository pattern',
      },
      {
        'number': 9,
        'title': 'CI/CD та DevOps',
        'description': 'GitHub Actions, Fastlane, Firebase App Distribution',
      },
      {
        'number': 10,
        'title': 'Soft Skills',
        'description': 'Code review, комунікація, робота в команді',
      },
    ];

    return directionsData.map((data) {
      return DirectionModel(
        id: 'dir-${data['number']}',
        goalId: testGoalId,
        directionNumber: data['number'] as int,
        title: data['title'] as String,
        description: data['description'] as String,
        status: ItemStatus.pending,
        blockNumber: 1,
      );
    }).toList();
  }

  /// Створити 100 тестових кроків (10 на кожен напрямок)
  static List<StepModel> _createTestSteps(List<DirectionModel> directions) {
    final List<StepModel> allSteps = [];

    // Кроки для кожного напрямку
    final stepsData = {
      1: [
        'Встановити Flutter SDK та налаштувати IDE',
        'Вивчити базові типи даних Dart',
        'Освоїти колекції (List, Map, Set)',
        'Вивчити функції та замикання',
        'Освоїти ООП: класи та об\'єкти',
        'Вивчити наслідування та поліморфізм',
        'Освоїти async/await та Future',
        'Вивчити Stream та StreamController',
        'Освоїти Null Safety',
        'Вивчити Generics та Extensions',
      ],
      2: [
        'Вивчити StatelessWidget та StatefulWidget',
        'Освоїти базові віджети (Container, Row, Column)',
        'Вивчити Text, Image, Icon віджети',
        'Освоїти Button віджети та GestureDetector',
        'Вивчити ListView та GridView',
        'Освоїти Stack та Positioned',
        'Створити кастомний віджет',
        'Вивчити Theme та styling',
        'Освоїти MediaQuery та LayoutBuilder',
        'Вивчити Keys та коли їх використовувати',
      ],
      3: [
        'Зрозуміти setState та його обмеження',
        'Вивчити InheritedWidget',
        'Освоїти Provider package',
        'Вивчити ChangeNotifier та ValueNotifier',
        'Освоїти Riverpod basics',
        'Вивчити BLoC pattern',
        'Освоїти flutter_bloc package',
        'Порівняти різні підходи до state management',
        'Реалізувати проект з Provider',
        'Реалізувати проект з BLoC',
      ],
      4: [
        'Вивчити HTTP basics та REST API',
        'Освоїти http package',
        'Вивчити Dio package та interceptors',
        'Освоїти JSON serialization вручну',
        'Вивчити json_serializable package',
        'Освоїти Freezed для моделей',
        'Вивчити обробку помилок API',
        'Освоїти Retrofit package',
        'Реалізувати Repository pattern для API',
        'Вивчити WebSocket та real-time комунікацію',
      ],
      5: [
        'Вивчити SharedPreferences',
        'Освоїти збереження простих даних',
        'Вивчити SQLite та sqflite package',
        'Освоїти CRUD операції з SQLite',
        'Вивчити Hive database',
        'Освоїти TypeAdapters в Hive',
        'Вивчити Isar database',
        'Порівняти різні бази даних',
        'Реалізувати offline-first архітектуру',
        'Вивчити синхронізацію даних',
      ],
      6: [
        'Вивчити Material Design 3 principles',
        'Освоїти кастомні теми',
        'Вивчити implicit animations',
        'Освоїти AnimationController',
        'Вивчити Tween та CurvedAnimation',
        'Освоїти Hero animations',
        'Вивчити CustomPainter',
        'Освоїти responsive design patterns',
        'Вивчити adaptive layouts',
        'Створити анімовану splash screen',
      ],
      7: [
        'Вивчити основи тестування',
        'Освоїти unit tests',
        'Вивчити Mockito для mocking',
        'Освоїти Widget tests',
        'Вивчити flutter_test package',
        'Освоїти Integration tests',
        'Вивчити Golden tests',
        'Освоїти Test Coverage',
        'Вивчити BDD підхід до тестування',
        'Налаштувати CI для автоматичних тестів',
      ],
      8: [
        'Вивчити SOLID principles',
        'Освоїти Clean Architecture layers',
        'Вивчити Repository pattern',
        'Освоїти Use Cases / Interactors',
        'Вивчити Dependency Injection',
        'Освоїти GetIt та Injectable',
        'Вивчити MVVM pattern',
        'Освоїти Feature-first структуру проекту',
        'Вивчити Modular architecture',
        'Реалізувати проект з Clean Architecture',
      ],
      9: [
        'Вивчити Git workflows',
        'Освоїти GitHub Actions basics',
        'Налаштувати CI pipeline для Flutter',
        'Вивчити Fastlane для автоматизації',
        'Освоїти Firebase App Distribution',
        'Налаштувати автоматичний deploy',
        'Вивчити semantic versioning',
        'Освоїти Codemagic або Bitrise',
        'Налаштувати автоматичні тести в CI',
        'Вивчити моніторинг та analytics',
      ],
      10: [
        'Вивчити ефективну комунікацію в команді',
        'Освоїти Code Review best practices',
        'Вивчити написання технічної документації',
        'Освоїти Agile/Scrum методології',
        'Вивчити оцінку задач та планування',
        'Освоїти менторинг junior розробників',
        'Вивчити presentation skills',
        'Освоїти time management',
        'Вивчити conflict resolution',
        'Розвинути leadership skills',
      ],
    };

    int globalStepNumber = 1;

    for (final direction in directions) {
      final directionSteps = stepsData[direction.directionNumber] ?? [];

      for (int localNum = 1; localNum <= directionSteps.length; localNum++) {
        allSteps.add(StepModel(
          id: 'step-${direction.directionNumber}-$localNum',
          goalId: testGoalId,
          directionId: direction.id,
          blockNumber: 1,
          stepNumber: globalStepNumber,
          localNumber: localNum,
          title: directionSteps[localNum - 1],
          description: 'Детальний опис для кроку ${direction.directionNumber}.$localNum',
          status: ItemStatus.pending,
        ));
        globalStepNumber++;
      }
    }

    return allSteps;
  }

  /// Отримати тестовий план з частково виконаними кроками
  /// (для демонстрації прогресу)
  static CareerPlanModel getTestCareerPlanWithProgress() {
    final plan = getTestCareerPlan();

    // Позначаємо перші 23 кроки як виконані (для демо)
    final updatedSteps = plan.steps.map((step) {
      if (step.stepNumber <= 7) {
        // Напрямок 1: 7 з 10 виконано
        return step.copyWith(status: ItemStatus.done);
      } else if (step.stepNumber <= 12) {
        // Напрямок 2: 5 з 10 виконано
        return step.copyWith(status: ItemStatus.done);
      } else if (step.stepNumber <= 15) {
        // Напрямок 2: 3 пропущено
        return step.copyWith(status: ItemStatus.skipped);
      } else if (step.stepNumber <= 18) {
        // Напрямок 2: решта pending
        return step;
      } else if (step.stepNumber <= 23) {
        // Напрямок 3: частково виконано
        return step.copyWith(status: ItemStatus.done);
      }
      return step;
    }).toList();

    return plan.copyWith(steps: updatedSteps);
  }

  /// Отримати порожній план (тільки структура, без прогресу)
  static CareerPlanModel getEmptyTestCareerPlan() {
    return getTestCareerPlan();
  }

  /// Отримати повністю виконаний план
  static CareerPlanModel getCompletedTestCareerPlan() {
    final plan = getTestCareerPlan();

    final updatedSteps = plan.steps.map((step) {
      return step.copyWith(status: ItemStatus.done);
    }).toList();

    return plan.copyWith(steps: updatedSteps);
  }
}