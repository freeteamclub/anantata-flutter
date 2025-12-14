/// Модель кар'єрного плану Anantata v2.1
/// 10 напрямків × 10 кроків = 100 кроків на блок
/// + Підтримка до 3 цілей
/// Версія: 2.1.0
/// Дата: 15.12.2025

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

/// Статус напрямку або кроку
enum ItemStatus {
  pending,    // ⏳ Очікує
  inProgress, // 🔄 В процесі
  done,       // ✅ Виконано
  skipped,    // ⏭️ Пропущено
}

extension ItemStatusExtension on ItemStatus {
  String get value {
    switch (this) {
      case ItemStatus.pending:
        return 'pending';
      case ItemStatus.inProgress:
        return 'in_progress';
      case ItemStatus.done:
        return 'done';
      case ItemStatus.skipped:
        return 'skipped';
    }
  }

  static ItemStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return ItemStatus.inProgress;
      case 'done':
        return ItemStatus.done;
      case 'skipped':
        return ItemStatus.skipped;
      default:
        return ItemStatus.pending;
    }
  }

  String get emoji {
    switch (this) {
      case ItemStatus.pending:
        return '🔲';
      case ItemStatus.inProgress:
        return '🔄';
      case ItemStatus.done:
        return '✅';
      case ItemStatus.skipped:
        return '⏭️';
    }
  }

  String get label {
    switch (this) {
      case ItemStatus.pending:
        return 'Очікує';
      case ItemStatus.inProgress:
        return 'В процесі';
      case ItemStatus.done:
        return 'Виконано';
      case ItemStatus.skipped:
        return 'Пропущено';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// GENERATED DATA CLASSES (результат генерації AI)
// ═══════════════════════════════════════════════════════════════

/// Згенерована ціль
class GeneratedGoal {
  final String title;
  final String targetSalary;

  GeneratedGoal({
    required this.title,
    required this.targetSalary,
  });

  factory GeneratedGoal.fromJson(Map<String, dynamic> json) {
    return GeneratedGoal(
      title: json['title'] as String,
      targetSalary: json['target_salary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'target_salary': targetSalary,
    };
  }
}

/// Згенерований напрямок (1 з 10)
class GeneratedDirection {
  final int number;       // 1-10
  final String title;     // Коротка назва
  final String description; // Опис напрямку

  GeneratedDirection({
    required this.number,
    required this.title,
    required this.description,
  });

  factory GeneratedDirection.fromJson(Map<String, dynamic> json) {
    return GeneratedDirection(
      number: json['number'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'description': description,
    };
  }
}

/// Згенерований крок (1 з 100)
class GeneratedStep {
  final int number;         // 1-100 (глобальний номер в блоці)
  final int localNumber;    // 1-10 (номер в межах напрямку)
  final String title;       // Коротка назва
  final String description; // Короткий опис
  final int directionNumber; // До якого напрямку відноситься (1-10)

  GeneratedStep({
    required this.number,
    required this.localNumber,
    required this.title,
    required this.description,
    required this.directionNumber,
  });

  factory GeneratedStep.fromJson(Map<String, dynamic> json) {
    return GeneratedStep(
      number: json['number'] as int,
      localNumber: json['local_number'] as int? ?? (((json['number'] as int) - 1) % 10) + 1,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      directionNumber: json['direction_number'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'local_number': localNumber,
      'title': title,
      'description': description,
      'direction_number': directionNumber,
    };
  }
}

/// Повний згенерований план (10 напрямків × 10 кроків = 100 кроків)
class GeneratedPlan {
  final GeneratedGoal goal;
  final int matchScore;
  final String gapAnalysis;
  final List<GeneratedDirection> directions; // 10 напрямків
  final List<GeneratedStep> steps;           // 100 кроків

  GeneratedPlan({
    required this.goal,
    required this.matchScore,
    required this.gapAnalysis,
    required this.directions,
    required this.steps,
  });

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) {
    return GeneratedPlan(
      goal: GeneratedGoal.fromJson(json['goal'] as Map<String, dynamic>),
      matchScore: json['match_score'] as int,
      gapAnalysis: json['gap_analysis'] as String,
      directions: (json['directions'] as List<dynamic>)
          .map((d) => GeneratedDirection.fromJson(d as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((s) => GeneratedStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal.toJson(),
      'match_score': matchScore,
      'gap_analysis': gapAnalysis,
      'directions': directions.map((d) => d.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  /// Отримати кроки для напрямку
  List<GeneratedStep> getStepsForDirection(int directionNumber) {
    return steps.where((s) => s.directionNumber == directionNumber).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// DATABASE MODELS (для збереження в Supabase)
// ═══════════════════════════════════════════════════════════════

/// Ціль користувача (goals table)
class GoalModel {
  final String id;
  final String userId;
  final String? assessmentId;
  final String title;
  final String targetSalary;
  final bool isPrimary;
  final String status; // active, completed, archived
  final DateTime createdAt;
  final DateTime? updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    this.assessmentId,
    required this.title,
    required this.targetSalary,
    this.isPrimary = false,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessmentId: json['assessment_id'] as String?,
      title: json['title'] as String,
      targetSalary: json['target_salary'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assessment_id': assessmentId,
      'title': title,
      'target_salary': targetSalary,
      'is_primary': isPrimary,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? assessmentId,
    String? title,
    String? targetSalary,
    bool? isPrimary,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessmentId: assessmentId ?? this.assessmentId,
      title: title ?? this.title,
      targetSalary: targetSalary ?? this.targetSalary,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Напрямок в БД (directions table)
class DirectionModel {
  final String id;
  final String goalId;
  final int directionNumber; // 1-10
  final String title;
  final String description;
  final ItemStatus status;
  final int blockNumber;     // Номер блоку (1, 2, 3...)

  DirectionModel({
    required this.id,
    required this.goalId,
    required this.directionNumber,
    required this.title,
    required this.description,
    this.status = ItemStatus.pending,
    this.blockNumber = 1,
  });

  factory DirectionModel.fromJson(Map<String, dynamic> json) {
    return DirectionModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      directionNumber: json['direction_number'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: ItemStatusExtension.fromString(json['status'] as String? ?? 'pending'),
      blockNumber: json['block_number'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'direction_number': directionNumber,
      'title': title,
      'description': description,
      'status': status.value,
      'block_number': blockNumber,
    };
  }

  DirectionModel copyWith({
    String? id,
    String? goalId,
    int? directionNumber,
    String? title,
    String? description,
    ItemStatus? status,
    int? blockNumber,
  }) {
    return DirectionModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      directionNumber: directionNumber ?? this.directionNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      blockNumber: blockNumber ?? this.blockNumber,
    );
  }

  /// Прогрес напрямку у відсотках (потрібно передати кроки)
  int calculateProgress(List<StepModel> steps) {
    final directionSteps = steps.where((s) => s.directionId == id).toList();
    if (directionSteps.isEmpty) return 0;
    final doneCount = directionSteps.where((s) => s.status == ItemStatus.done).length;
    return ((doneCount / directionSteps.length) * 100).round();
  }
}

/// Крок в БД (steps table)
class StepModel {
  final String id;
  final String goalId;
  final String directionId;
  final int blockNumber;      // Номер блоку (1, 2, 3...)
  final int stepNumber;       // Глобальний номер 1-100
  final int localNumber;      // Номер в межах напрямку 1-10
  final String title;
  final String description;   // Короткий опис
  final String? detailedDescription; // Детальний опис (генерується on-demand)
  final ItemStatus status;

  StepModel({
    required this.id,
    required this.goalId,
    required this.directionId,
    this.blockNumber = 1,
    required this.stepNumber,
    required this.localNumber,
    required this.title,
    required this.description,
    this.detailedDescription,
    this.status = ItemStatus.pending,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      directionId: json['direction_id'] as String,
      blockNumber: json['block_number'] as int? ?? 1,
      stepNumber: json['step_number'] as int,
      localNumber: json['local_number'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      detailedDescription: json['detailed_description'] as String?,
      status: ItemStatusExtension.fromString(json['status'] as String? ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'direction_id': directionId,
      'block_number': blockNumber,
      'step_number': stepNumber,
      'local_number': localNumber,
      'title': title,
      'description': description,
      'detailed_description': detailedDescription,
      'status': status.value,
    };
  }

  StepModel copyWith({
    String? id,
    String? goalId,
    String? directionId,
    int? blockNumber,
    int? stepNumber,
    int? localNumber,
    String? title,
    String? description,
    String? detailedDescription,
    ItemStatus? status,
  }) {
    return StepModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      directionId: directionId ?? this.directionId,
      blockNumber: blockNumber ?? this.blockNumber,
      stepNumber: stepNumber ?? this.stepNumber,
      localNumber: localNumber ?? this.localNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      status: status ?? this.status,
    );
  }

  /// Позначити як виконано
  StepModel markDone() => copyWith(status: ItemStatus.done);

  /// Пропустити крок
  StepModel skip() => copyWith(status: ItemStatus.skipped);

  /// Скинути статус
  StepModel reset() => copyWith(status: ItemStatus.pending);
}

// ═══════════════════════════════════════════════════════════════
// ПОВНА МОДЕЛЬ КАР'ЄРНОГО ПЛАНУ (для UI)
// ═══════════════════════════════════════════════════════════════

/// Повний кар'єрний план з усіма даними
class CareerPlanModel {
  final GoalModel goal;
  final int matchScore;
  final String gapAnalysis;
  final List<DirectionModel> directions;
  final List<StepModel> steps;
  final int currentBlock;

  CareerPlanModel({
    required this.goal,
    required this.matchScore,
    required this.gapAnalysis,
    required this.directions,
    required this.steps,
    this.currentBlock = 1,
  });

  /// Загальний прогрес блоку у відсотках
  double get overallProgress {
    if (steps.isEmpty) return 0;
    final doneCount = steps.where((s) => s.status == ItemStatus.done).length;
    return (doneCount / steps.length) * 100;
  }

  /// Кількість виконаних кроків
  int get completedStepsCount =>
      steps.where((s) => s.status == ItemStatus.done).length;

  /// Кількість пропущених кроків
  int get skippedStepsCount =>
      steps.where((s) => s.status == ItemStatus.skipped).length;

  /// Кількість кроків в очікуванні
  int get pendingStepsCount =>
      steps.where((s) => s.status == ItemStatus.pending).length;

  /// Чи блок завершено
  bool get isBlockComplete => pendingStepsCount == 0;

  /// Отримати напрямок за номером
  DirectionModel? getDirectionByNumber(int number) {
    try {
      return directions.firstWhere((d) => d.directionNumber == number);
    } catch (_) {
      return null;
    }
  }

  /// Отримати кроки для напрямку
  List<StepModel> getStepsForDirection(String directionId) {
    return steps.where((s) => s.directionId == directionId).toList()
      ..sort((a, b) => a.localNumber.compareTo(b.localNumber));
  }

  /// Отримати прогрес напрямку
  int getDirectionProgress(String directionId) {
    final directionSteps = getStepsForDirection(directionId);
    if (directionSteps.isEmpty) return 0;
    final doneCount = directionSteps.where((s) => s.status == ItemStatus.done).length;
    return ((doneCount / directionSteps.length) * 100).round();
  }

  /// Перший невиконаний крок
  StepModel? get nextStep {
    try {
      return steps.firstWhere((s) => s.status == ItemStatus.pending);
    } catch (_) {
      return null;
    }
  }

  /// Поточний напрямок (з першим невиконаним кроком)
  DirectionModel? get currentDirection {
    final next = nextStep;
    if (next == null) return null;
    try {
      return directions.firstWhere((d) => d.id == next.directionId);
    } catch (_) {
      return null;
    }
  }

  /// Статистика по напрямках
  List<DirectionStats> get directionsStats {
    return directions.map((dir) {
      final dirSteps = getStepsForDirection(dir.id);
      return DirectionStats(
        direction: dir,
        totalSteps: dirSteps.length,
        doneCount: dirSteps.where((s) => s.status == ItemStatus.done).length,
        skippedCount: dirSteps.where((s) => s.status == ItemStatus.skipped).length,
        pendingCount: dirSteps.where((s) => s.status == ItemStatus.pending).length,
      );
    }).toList();
  }

  factory CareerPlanModel.fromJson(Map<String, dynamic> json) {
    return CareerPlanModel(
      goal: GoalModel.fromJson(json['goal'] as Map<String, dynamic>),
      matchScore: json['match_score'] as int,
      gapAnalysis: json['gap_analysis'] as String,
      directions: (json['directions'] as List<dynamic>)
          .map((d) => DirectionModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((s) => StepModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      currentBlock: json['current_block'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal.toJson(),
      'match_score': matchScore,
      'gap_analysis': gapAnalysis,
      'directions': directions.map((d) => d.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'current_block': currentBlock,
    };
  }

  CareerPlanModel copyWith({
    GoalModel? goal,
    int? matchScore,
    String? gapAnalysis,
    List<DirectionModel>? directions,
    List<StepModel>? steps,
    int? currentBlock,
  }) {
    return CareerPlanModel(
      goal: goal ?? this.goal,
      matchScore: matchScore ?? this.matchScore,
      gapAnalysis: gapAnalysis ?? this.gapAnalysis,
      directions: directions ?? this.directions,
      steps: steps ?? this.steps,
      currentBlock: currentBlock ?? this.currentBlock,
    );
  }

  /// Оновити статус кроку
  CareerPlanModel updateStepStatus(String stepId, ItemStatus newStatus) {
    final updatedSteps = steps.map((s) {
      return s.id == stepId ? s.copyWith(status: newStatus) : s;
    }).toList();
    return copyWith(steps: updatedSteps);
  }

  @override
  String toString() {
    return 'CareerPlanModel(goal: ${goal.title}, directions: ${directions.length}, steps: ${steps.length}, progress: ${overallProgress.toStringAsFixed(0)}%)';
  }
}

/// Статистика напрямку
class DirectionStats {
  final DirectionModel direction;
  final int totalSteps;
  final int doneCount;
  final int skippedCount;
  final int pendingCount;

  DirectionStats({
    required this.direction,
    required this.totalSteps,
    required this.doneCount,
    required this.skippedCount,
    required this.pendingCount,
  });

  double get progressPercent =>
      totalSteps > 0 ? (doneCount / totalSteps) * 100 : 0;

  bool get isComplete => pendingCount == 0;

  String get statusEmoji {
    if (isComplete) return '✅';
    if (doneCount > 0) return '🔄';
    return '⏳';
  }
}

// ═══════════════════════════════════════════════════════════════
// 🆕 МОДЕЛЬ СПИСКУ ЦІЛЕЙ (до 3 цілей)
// ═══════════════════════════════════════════════════════════════

/// Короткий опис цілі для списку
class GoalSummary {
  final String id;
  final String title;
  final String targetSalary;
  final int matchScore;
  final String gapAnalysis;
  final bool isPrimary;
  final DateTime createdAt;
  final double progress; // 0-100
  final int completedSteps;
  final int totalSteps;

  GoalSummary({
    required this.id,
    required this.title,
    required this.targetSalary,
    required this.matchScore,
    required this.gapAnalysis,
    required this.isPrimary,
    required this.createdAt,
    required this.progress,
    required this.completedSteps,
    required this.totalSteps,
  });

  factory GoalSummary.fromCareerPlan(CareerPlanModel plan) {
    return GoalSummary(
      id: plan.goal.id,
      title: plan.goal.title,
      targetSalary: plan.goal.targetSalary,
      matchScore: plan.matchScore,
      gapAnalysis: plan.gapAnalysis,
      isPrimary: plan.goal.isPrimary,
      createdAt: plan.goal.createdAt,
      progress: plan.overallProgress,
      completedSteps: plan.completedStepsCount,
      totalSteps: plan.steps.length,
    );
  }

  factory GoalSummary.fromJson(Map<String, dynamic> json) {
    return GoalSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      targetSalary: json['target_salary'] as String,
      matchScore: json['match_score'] as int,
      gapAnalysis: json['gap_analysis'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedSteps: json['completed_steps'] as int? ?? 0,
      totalSteps: json['total_steps'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_salary': targetSalary,
      'match_score': matchScore,
      'gap_analysis': gapAnalysis,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'progress': progress,
      'completed_steps': completedSteps,
      'total_steps': totalSteps,
    };
  }

  GoalSummary copyWith({
    String? id,
    String? title,
    String? targetSalary,
    int? matchScore,
    String? gapAnalysis,
    bool? isPrimary,
    DateTime? createdAt,
    double? progress,
    int? completedSteps,
    int? totalSteps,
  }) {
    return GoalSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      targetSalary: targetSalary ?? this.targetSalary,
      matchScore: matchScore ?? this.matchScore,
      gapAnalysis: gapAnalysis ?? this.gapAnalysis,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      completedSteps: completedSteps ?? this.completedSteps,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  /// Форматована дата
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = _monthName(createdAt.month);
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня'
    ];
    return months[month - 1];
  }

  /// Колір Match Score
  String get scoreColor {
    if (matchScore >= 70) return 'green';
    if (matchScore >= 40) return 'orange';
    return 'red';
  }
}

/// Модель списку цілей (до 3 цілей)
class GoalsListModel {
  static const int maxGoals = 3;

  final List<GoalSummary> goals;
  final String? primaryGoalId;

  GoalsListModel({
    required this.goals,
    this.primaryGoalId,
  });

  /// Кількість цілей
  int get count => goals.length;

  /// Чи можна додати нову ціль
  bool get canAddNew => goals.length < maxGoals;

  /// Скільки ще можна додати
  int get availableSlots => maxGoals - goals.length;

  /// Головна ціль
  GoalSummary? get primaryGoal {
    if (primaryGoalId == null) return goals.isNotEmpty ? goals.first : null;
    try {
      return goals.firstWhere((g) => g.id == primaryGoalId);
    } catch (_) {
      return goals.isNotEmpty ? goals.first : null;
    }
  }

  /// Чи є ціль головною
  bool isPrimary(String goalId) => primaryGoalId == goalId;

  factory GoalsListModel.fromJson(Map<String, dynamic> json) {
    return GoalsListModel(
      goals: (json['goals'] as List<dynamic>)
          .map((g) => GoalSummary.fromJson(g as Map<String, dynamic>))
          .toList(),
      primaryGoalId: json['primary_goal_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals.map((g) => g.toJson()).toList(),
      'primary_goal_id': primaryGoalId,
    };
  }

  GoalsListModel copyWith({
    List<GoalSummary>? goals,
    String? primaryGoalId,
  }) {
    return GoalsListModel(
      goals: goals ?? this.goals,
      primaryGoalId: primaryGoalId ?? this.primaryGoalId,
    );
  }

  /// Додати нову ціль
  GoalsListModel addGoal(GoalSummary goal) {
    if (!canAddNew) return this;
    final newGoals = [...goals, goal];
    return copyWith(
      goals: newGoals,
      primaryGoalId: primaryGoalId ?? goal.id,
    );
  }

  /// Видалити ціль
  GoalsListModel removeGoal(String goalId) {
    final newGoals = goals.where((g) => g.id != goalId).toList();
    String? newPrimaryId = primaryGoalId;

    // Якщо видаляємо головну ціль, обираємо першу з тих що залишились
    if (primaryGoalId == goalId) {
      newPrimaryId = newGoals.isNotEmpty ? newGoals.first.id : null;
    }

    return copyWith(
      goals: newGoals,
      primaryGoalId: newPrimaryId,
    );
  }

  /// Встановити головну ціль
  GoalsListModel setPrimaryGoal(String goalId) {
    // Оновлюємо isPrimary для всіх цілей
    final newGoals = goals.map((g) {
      return g.copyWith(isPrimary: g.id == goalId);
    }).toList();

    return copyWith(
      goals: newGoals,
      primaryGoalId: goalId,
    );
  }

  /// Оновити прогрес цілі
  GoalsListModel updateGoalProgress(String goalId, double progress, int completedSteps) {
    final newGoals = goals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(
          progress: progress,
          completedSteps: completedSteps,
        );
      }
      return g;
    }).toList();

    return copyWith(goals: newGoals);
  }

  /// Порожній список
  factory GoalsListModel.empty() {
    return GoalsListModel(goals: [], primaryGoalId: null);
  }
}