// lib/data/assessment_questions.dart
// Anantata Career Coach - Assessment Questions Data
// 15 питань для кар'єрної оцінки

/// Модель питання
class AssessmentQuestion {
  final int id;
  final String text;
  final String category;
  final String inputType; // 'select' або 'select_or_custom'
  final List<String> options;

  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.inputType,
    required this.options,
  });

  bool get hasCustomOption => inputType == 'select_or_custom';
}

/// 15 питань Career Assessment
final List<AssessmentQuestion> assessmentQuestions = [
  // ═══════════════════════════════════════════════════════════════
  // БЛОК 1: ПОТОЧНИЙ СТАН (питання 1-7)
  // ═══════════════════════════════════════════════════════════════

  AssessmentQuestion(
    id: 1,
    text: 'Скільки вам років?',
    category: 'current_state',
    inputType: 'select',
    options: [
      'До 25',
      '26-35',
      '36-45',
      'Більше 45',
    ],
  ),

  AssessmentQuestion(
    id: 2,
    text: 'Яка у вас освіта?',
    category: 'current_state',
    inputType: 'select',
    options: [
      'Вища (Бакалавр/Магістр)',
      'Неповна вища (студент)',
      'Середня спеціальна',
      'Середня/без освіти',
    ],
  ),

  AssessmentQuestion(
    id: 3,
    text: 'Яка ваша поточна посада?',
    category: 'current_state',
    inputType: 'select',
    options: [
      'Не працюю/студент/стажер',
      'Виконавець/спеціаліст',
      'Керівник/менеджер',
      'Власний бізнес',
    ],
  ),

  AssessmentQuestion(
    id: 4,
    text: 'Скільки років досвіду роботи?',
    category: 'current_state',
    inputType: 'select',
    options: [
      'Без досвіду/до 1 року',
      '1-5 років',
      '5-10 років',
      'Більше 10 років',
    ],
  ),

  AssessmentQuestion(
    id: 5,
    text: 'Яка ваша поточна зарплата? (\$/міс)',
    category: 'current_state',
    inputType: 'select',
    options: [
      'Не працюю/до \$500',
      '\$500-1,000',
      '\$1,000-2,500',
      'Більше \$2,500',
    ],
  ),

  AssessmentQuestion(
    id: 6,
    text: 'Ваші ключові навички?',
    category: 'current_state',
    inputType: 'select_or_custom',
    options: [
      'Комунікація та робота з людьми',
      'Аналітика та технічні навички',
      'Лідерство та управління',
      'Креативність та творчість',
      '💡 Ваш варіант',
    ],
  ),

  AssessmentQuestion(
    id: 7,
    text: 'Ваші головні досягнення?',
    category: 'current_state',
    inputType: 'select_or_custom',
    options: [
      'Ще немає значних досягнень',
      'Успішно виконав складні проекти',
      'Отримав підвищення/визнання',
      'Побудував команду/покращив процеси',
      '💡 Ваш варіант',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════
  // БЛОК 2: БАЖАНИЙ СТАН (питання 8-10)
  // ═══════════════════════════════════════════════════════════════

  AssessmentQuestion(
    id: 8,
    text: 'Який ваш кар\'єрний напрямок?',
    category: 'desired_state',
    inputType: 'select_or_custom',
    options: [
      'Розвиток в поточній компанії',
      'Зміна компанії (та сама сфера)',
      'Зміна сфери діяльності',
      'Стати фрілансером',
      'Відкрити власний бізнес',
      '💡 Ваш варіант',
    ],
  ),

  AssessmentQuestion(
    id: 9,
    text: 'Яку зарплату ви хочете отримувати? (\$/міс)',
    category: 'desired_state',
    inputType: 'select',
    options: [
      '\$1,000-2,000',
      '\$2,000-3,500',
      '\$3,500-5,000',
      'Більше \$5,000',
    ],
  ),

  AssessmentQuestion(
    id: 10,
    text: 'Який ваш рівень англійської мови?',
    category: 'desired_state',
    inputType: 'select',
    options: [
      'Початковий (A1-A2)',
      'Середній (B1-B2)',
      'Вільний (C1-C2)',
      'Носій / білінгв',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════
  // БЛОК 3: БАР'ЄРИ ТА ПРІОРИТЕТИ (питання 11-13)
  // ═══════════════════════════════════════════════════════════════

  AssessmentQuestion(
    id: 11,
    text: 'Що найбільше заважає вам досягти кар\'єрної мети?',
    category: 'barriers',
    inputType: 'select_or_custom',
    options: [
      'Брак знань/навичок',
      'Брак досвіду',
      'Брак часу',
      'Брак впевненості',
      '💡 Ваш варіант',
    ],
  ),

  AssessmentQuestion(
    id: 12,
    text: 'Що для вас найважливіше в роботі?',
    category: 'desired_state',
    inputType: 'select',
    options: [
      'Висока зарплата',
      'Розвиток та навчання',
      'Баланс роботи та життя',
      'Цікаві задачі та команда',
    ],
  ),

  AssessmentQuestion(
    id: 13,
    text: 'Який формат роботи вам підходить?',
    category: 'desired_state',
    inputType: 'select',
    options: [
      'Тільки офіс',
      'Тільки віддалено',
      'Гібрид (офіс + віддалено)',
      'Готовий до релокації',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════
  // БЛОК 4: ДОДАТКОВА ІНФОРМАЦІЯ (питання 14-15)
  // ═══════════════════════════════════════════════════════════════

  AssessmentQuestion(
    id: 14,
    text: 'В якій сфері хочете розвиватись?',
    category: 'additional',
    inputType: 'select_or_custom',
    options: [
      'IT та технології',
      'Маркетинг та продажі',
      'Фінанси та бухгалтерія',
      'Освіта та консалтинг',
      'Виробництво та логістика',
      '💡 Ваш варіант',
    ],
  ),

  AssessmentQuestion(
    id: 15,
    text: 'Що вас найбільше мотивує в кар\'єрі?',
    category: 'additional',
    inputType: 'select',
    options: [
      'Фінансова незалежність',
      'Професійне визнання',
      'Допомога людям/суспільству',
      'Свобода та гнучкість',
    ],
  ),
];