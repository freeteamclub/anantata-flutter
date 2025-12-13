/// Константи додатку Anantata
/// Версія: 1.0
/// Дата: 12.12.2025

class AppConstants {
  AppConstants._();

  // ============================================
  // ІНФОРМАЦІЯ ПРО ДОДАТОК
  // ============================================
  
  static const String appName = 'Anantata';
  static const String appFullName = 'Anantata Career Coach';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription = 'AI-powered career development';
  
  // ============================================
  // API КЛЮЧІ (замінити на реальні)
  // ============================================
  
  // TODO: Перенести в .env файл для безпеки
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ============================================
  // ASSESSMENT НАЛАШТУВАННЯ
  // ============================================
  
  static const int assessmentQuestionsCount = 15;
  static const int assessmentMinAnswerLength = 10;
  static const int assessmentMaxAnswerLength = 500;
  static const Duration assessmentAutoSaveDelay = Duration(seconds: 3);

  // ============================================
  // CAREER PLAN НАЛАШТУВАННЯ
  // ============================================
  
  static const int careerPlanStepsCount = 10;
  static const int careerPlanDaysDefault = 90;

  // ============================================
  // CHAT НАЛАШТУВАННЯ
  // ============================================
  
  static const int chatMaxMessageLength = 2000;
  static const int chatHistoryLimit = 50;
  static const Duration chatTypingDelay = Duration(milliseconds: 50);

  // ============================================
  // АНІМАЦІЇ
  // ============================================
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);

  // ============================================
  // STORAGE КЛЮЧІ
  // ============================================
  
  static const String storageKeyUser = 'user_data';
  static const String storageKeyAssessment = 'assessment_data';
  static const String storageKeyCareerPlan = 'career_plan_data';
  static const String storageKeyOnboardingComplete = 'onboarding_complete';
  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyLanguage = 'language';

  // ============================================
  // ROUTES (МАРШРУТИ)
  // ============================================
  
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeAssessment = '/assessment';
  static const String routeResults = '/results';
  static const String routeChat = '/chat';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';

  // ============================================
  // ASSESSMENT ПИТАННЯ
  // ============================================
  
  static const List<String> assessmentQuestions = [
    'Опишіть вашу поточну професійну ситуацію. Чим ви займаєтесь зараз?',
    'Які ваші головні професійні досягнення за останні 3 роки?',
    'Що вам найбільше подобається у вашій поточній роботі?',
    'Що вас найбільше розчаровує або дратує у вашій поточній роботі?',
    'Які навички та компетенції ви вважаєте своїми найсильнішими?',
    'Які навички ви хотіли б розвинути або покращити?',
    'Де ви бачите себе через 5 років у професійному плані?',
    'Яка ваша ідеальна робота? Опишіть детально.',
    'Що для вас важливіше: висока зарплата чи цікава робота? Поясніть.',
    'Як ви ставитесь до ризиків? Чи готові змінити сферу діяльності?',
    'Які фактори найбільше впливають на ваше рішення про зміну роботи?',
    'Опишіть ваш ідеальний робочий день.',
    'Які ваші цінності у житті та роботі?',
    'Що вас мотивує працювати краще?',
    'Які перешкоди, на вашу думку, стоять на шляху до вашої мрії?',
  ];

  // ============================================
  // ONBOARDING ТЕКСТИ
  // ============================================
  
  static const List<Map<String, String>> onboardingPages = [
    {
      'title': 'Ласкаво просимо до Anantata',
      'description': 'Ваш персональний AI-коуч для розвитку кар\'єри',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Пройдіть оцінювання',
      'description': 'Дайте відповіді на 15 питань, щоб ми краще зрозуміли ваші цілі',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Отримайте план дій',
      'description': 'AI проаналізує ваші відповіді та створить персональний план на 90 днів',
      'image': 'assets/images/onboarding_3.png',
    },
    {
      'title': 'Досягайте цілей',
      'description': 'Спілкуйтесь з AI-коучем та відстежуйте свій прогрес',
      'image': 'assets/images/onboarding_4.png',
    },
  ];

  // ============================================
  // GEMINI ПРОМПТИ
  // ============================================
  
  static const String geminiSystemPrompt = '''
Ти - Anantata, професійний AI-коуч з розвитку кар'єри. 
Твоя мета - допомагати людям визначити свої кар'єрні цілі та досягти їх.

Правила:
1. Завжди відповідай українською мовою
2. Будь підтримуючим та мотивуючим
3. Давай конкретні, практичні поради
4. Враховуй український контекст ринку праці
5. Пропонуй реалістичні кроки для досягнення цілей
''';

  static const String geminiAnalysisPrompt = '''
Проаналізуй відповіді користувача на питання кар'єрного оцінювання.
Створи детальний аналіз та план дій з 10 кроків на 90 днів.

Формат відповіді:
1. Короткий аналіз поточної ситуації
2. Сильні сторони користувача
3. Зони для розвитку
4. Рекомендована кар'єрна траєкторія
5. 10 конкретних кроків з термінами
''';
}
