/// Модель оцінювання (Assessment) Anantata
/// Версія: 1.0
/// Дата: 12.12.2025

/// Статус оцінювання
enum AssessmentStatus {
  notStarted,
  inProgress,
  completed,
  analyzed,
}

/// Одна відповідь на питання
class AssessmentAnswer {
  final int questionIndex;
  final String question;
  final String answer;
  final DateTime answeredAt;

  AssessmentAnswer({
    required this.questionIndex,
    required this.question,
    required this.answer,
    required this.answeredAt,
  });

  factory AssessmentAnswer.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswer(
      questionIndex: json['question_index'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_index': questionIndex,
      'question': question,
      'answer': answer,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  AssessmentAnswer copyWith({
    int? questionIndex,
    String? question,
    String? answer,
    DateTime? answeredAt,
  }) {
    return AssessmentAnswer(
      questionIndex: questionIndex ?? this.questionIndex,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}

/// Повна модель оцінювання
class AssessmentModel {
  final String id;
  final String userId;
  final AssessmentStatus status;
  final List<AssessmentAnswer> answers;
  final int currentQuestionIndex;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? analysisResult;
  final String? careerPlanId;

  AssessmentModel({
    required this.id,
    required this.userId,
    this.status = AssessmentStatus.notStarted,
    this.answers = const [],
    this.currentQuestionIndex = 0,
    required this.startedAt,
    this.completedAt,
    this.analysisResult,
    this.careerPlanId,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: AssessmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssessmentStatus.notStarted,
      ),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => AssessmentAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      analysisResult: json['analysis_result'] as String?,
      careerPlanId: json['career_plan_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status.name,
      'answers': answers.map((a) => a.toJson()).toList(),
      'current_question_index': currentQuestionIndex,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'analysis_result': analysisResult,
      'career_plan_id': careerPlanId,
    };
  }

  AssessmentModel copyWith({
    String? id,
    String? userId,
    AssessmentStatus? status,
    List<AssessmentAnswer>? answers,
    int? currentQuestionIndex,
    DateTime? startedAt,
    DateTime? completedAt,
    String? analysisResult,
    String? careerPlanId,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      analysisResult: analysisResult ?? this.analysisResult,
      careerPlanId: careerPlanId ?? this.careerPlanId,
    );
  }

  /// Створення нового assessment
  factory AssessmentModel.create({
    required String id,
    required String userId,
  }) {
    return AssessmentModel(
      id: id,
      userId: userId,
      status: AssessmentStatus.notStarted,
      answers: [],
      currentQuestionIndex: 0,
      startedAt: DateTime.now(),
    );
  }

  /// Прогрес у відсотках
  double get progressPercent {
    if (answers.isEmpty) return 0;
    return (answers.length / 15) * 100;
  }

  /// Кількість відповіданих питань
  int get answeredCount => answers.length;

  /// Чи всі питання відповідані
  bool get isComplete => answers.length >= 15;

  /// Чи можна перейти до наступного питання
  bool get canProceed => currentQuestionIndex < 14;

  /// Чи можна повернутись до попереднього
  bool get canGoBack => currentQuestionIndex > 0;

  /// Отримати відповідь за індексом
  AssessmentAnswer? getAnswerByIndex(int index) {
    try {
      return answers.firstWhere((a) => a.questionIndex == index);
    } catch (_) {
      return null;
    }
  }

  /// Додати або оновити відповідь
  AssessmentModel addOrUpdateAnswer(AssessmentAnswer answer) {
    final updatedAnswers = List<AssessmentAnswer>.from(answers);
    final existingIndex = updatedAnswers.indexWhere(
      (a) => a.questionIndex == answer.questionIndex,
    );

    if (existingIndex != -1) {
      updatedAnswers[existingIndex] = answer;
    } else {
      updatedAnswers.add(answer);
    }

    return copyWith(
      answers: updatedAnswers,
      status: AssessmentStatus.inProgress,
    );
  }

  /// Перейти до наступного питання
  AssessmentModel goToNext() {
    if (!canProceed) return this;
    return copyWith(currentQuestionIndex: currentQuestionIndex + 1);
  }

  /// Повернутись до попереднього питання
  AssessmentModel goToPrevious() {
    if (!canGoBack) return this;
    return copyWith(currentQuestionIndex: currentQuestionIndex - 1);
  }

  /// Завершити оцінювання
  AssessmentModel complete() {
    return copyWith(
      status: AssessmentStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Отримати всі відповіді як текст для AI
  String getAllAnswersAsText() {
    final buffer = StringBuffer();
    for (var i = 0; i < answers.length; i++) {
      final answer = answers[i];
      buffer.writeln('Питання ${answer.questionIndex + 1}: ${answer.question}');
      buffer.writeln('Відповідь: ${answer.answer}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'AssessmentModel(id: $id, status: $status, progress: ${progressPercent.toStringAsFixed(0)}%)';
  }
}
