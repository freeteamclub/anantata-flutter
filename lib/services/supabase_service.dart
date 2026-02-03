import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Сервіс для роботи з Supabase
/// Версія: 2.6.0 - Баг #9 і #13: видалення цілі + сортування напрямків
/// Дата: 18.01.2026

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;
  bool _isInitialized = false;

  // Singleton
  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseService._internal();

  /// Supabase клієнт
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService не ініціалізовано. Викличте initialize() спочатку.');
    }
    return _client!;
  }

  /// Чи ініціалізовано
  bool get isInitialized => _isInitialized;

  /// Поточний користувач
  User? get currentUser => _client?.auth.currentUser;

  /// Чи авторизований
  bool get isAuthenticated => currentUser != null;

  /// ID користувача
  String? get userId => currentUser?.id;

  /// Email користувача
  String? get userEmail => currentUser?.email;

  /// Ім'я користувача
  String? get userName => currentUser?.userMetadata?['full_name'] as String? ??
      currentUser?.userMetadata?['name'] as String?;

  /// Аватар користувача
  String? get userAvatar => currentUser?.userMetadata?['avatar_url'] as String? ??
      currentUser?.userMetadata?['picture'] as String?;

  // ═══════════════════════════════════════════════════════════════
  // ІНІЦІАЛІЗАЦІЯ
  // ═══════════════════════════════════════════════════════════════

  /// Ініціалізація Supabase
  static Future<void> initialize() async {
    if (_instance?._isInitialized == true) {
      debugPrint('✅ SupabaseService вже ініціалізовано');
      return;
    }

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      debugPrint('❌ SUPABASE_URL не знайдено в .env');
      return;
    }

    if (anonKey == null || anonKey.isEmpty) {
      debugPrint('❌ SUPABASE_ANON_KEY не знайдено в .env');
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _client = Supabase.instance.client;
    _instance ??= SupabaseService._internal();
    _instance!._isInitialized = true;

    debugPrint('✅ SupabaseService ініціалізовано');
    debugPrint('📧 Поточний користувач: ${_instance!.userEmail ?? "не авторизований"}');
  }

  // ═══════════════════════════════════════════════════════════════
  // АВТОРИЗАЦІЯ - GOOGLE
  // ═══════════════════════════════════════════════════════════════

  /// Вхід через Google
  Future<User?> signInWithGoogle() async {
    final googleClientId = dotenv.env['GOOGLE_CLIENT_ID'];

    if (googleClientId == null) {
      throw Exception('GOOGLE_CLIENT_ID не знайдено в .env');
    }

    // Web платформа
    if (kIsWeb) {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null,
      );
      // Для web повертаємо null, бо редірект
      return null;
    }

    // Mobile платформа (Android/iOS)
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: googleClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In скасовано користувачем');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Не вдалося отримати токени від Google');
    }

    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    debugPrint('✅ Google Sign-In успішний: ${response.user?.email}');
    return response.user;
  }

  /// Вихід
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Google Sign-Out помилка: $e');
    }

    await client.auth.signOut();
    debugPrint('✅ Вихід виконано');
  }

  /// Слухач змін авторизації
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ═══════════════════════════════════════════════════════════════
  // ПРОФІЛЬ
  // ═══════════════════════════════════════════════════════════════

  /// Отримати профіль
  Future<Map<String, dynamic>?> getProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId!)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Помилка отримання профілю: $e');
      return null;
    }
  }

  /// Оновити профіль
  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    if (!isAuthenticated) return;

    try {
      await client.from('profiles').update({
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId!);

      debugPrint('✅ Профіль оновлено');
    } catch (e) {
      debugPrint('❌ Помилка оновлення профілю: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GOALS (ЦІЛІ)
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти ціль
  Future<String?> saveGoal({
    required String title,
    required String targetSalary,
    required int matchScore,
    required String gapAnalysis,
  }) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return null;
    }

    try {
      final response = await client.from('goals').insert({
        'user_id': userId,
        'title': title,
        'target_salary': targetSalary,
        'match_score': matchScore,
        'gap_analysis': gapAnalysis,
        'is_active': true,
        'status': 'active',
      }).select('id').single();

      final goalId = response['id'] as String;
      debugPrint('✅ Ціль збережено: $goalId');
      return goalId;
    } catch (e) {
      debugPrint('❌ Помилка збереження цілі: $e');
      return null;
    }
  }

  /// Отримати активну ціль
  Future<Map<String, dynamic>?> getActiveGoal() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('goals')
          .select()
          .eq('user_id', userId!)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Помилка отримання цілі: $e');
      return null;
    }
  }

  /// 🆕 Отримати ВСІ цілі користувача з Supabase
  Future<List<Map<String, dynamic>>> getAllGoals() async {
    if (!isAuthenticated) return [];

    try {
      final response = await client
          .from('goals')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false);

      debugPrint('☁️ Завантажено ${response.length} цілей з Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Помилка отримання всіх цілей: $e');
      return [];
    }
  }

  /// Отримати останню ціль користувача
  Future<Map<String, dynamic>?> getLatestGoal() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('goals')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Помилка отримання цілі: $e');
      return null;
    }
  }

  /// Оновити ціль
  Future<void> updateGoal(String goalId, Map<String, dynamic> data) async {
    try {
      await client.from('goals').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', goalId);

      debugPrint('✅ Ціль оновлено');
    } catch (e) {
      debugPrint('❌ Помилка оновлення цілі: $e');
    }
  }

  /// 🆕 Видалити ціль та всі пов'язані дані (Баг #9)
  Future<bool> deleteGoal(String goalId) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return false;
    }

    try {
      // 1. Видалити кроки
      await client.from('steps').delete().eq('goal_id', goalId);
      debugPrint('🗑️ Кроки видалено');

      // 2. Видалити напрямки
      await client.from('directions').delete().eq('goal_id', goalId);
      debugPrint('🗑️ Напрямки видалено');

      // 3. Видалити повідомлення чату
      await client.from('chat_messages').delete().eq('goal_id', goalId);
      debugPrint('🗑️ Повідомлення чату видалено');

      // 4. Видалити відповіді оцінювання
      await client.from('assessment_answers').delete().eq('goal_id', goalId);
      debugPrint('🗑️ Відповіді оцінювання видалено');

      // 5. Видалити саму ціль
      await client.from('goals').delete().eq('id', goalId);
      debugPrint('✅ Ціль $goalId видалено з Supabase');

      return true;
    } catch (e) {
      debugPrint('❌ Помилка видалення цілі: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DIRECTIONS (НАПРЯМКИ)
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти напрямки
  Future<List<String>> saveDirections(String goalId, List<DirectionModel> directions) async {
    if (!isAuthenticated) return [];

    try {
      final data = directions.map((d) => {
        'goal_id': goalId,
        'direction_number': d.directionNumber,
        'title': d.title,
        'description': d.description,
        'status': d.status.value,
        'block_number': d.blockNumber,
      }).toList();

      final response = await client
          .from('directions')
          .insert(data)
          .select('id, direction_number');

      final ids = (response as List).map((r) => r['id'] as String).toList();
      debugPrint('✅ Збережено ${ids.length} напрямків');
      return ids;
    } catch (e) {
      debugPrint('❌ Помилка збереження напрямків: $e');
      return [];
    }
  }

  /// Отримати напрямки для цілі
  Future<List<Map<String, dynamic>>> getDirections(String goalId) async {
    try {
      final response = await client
          .from('directions')
          .select()
          .eq('goal_id', goalId)
          .order('direction_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Помилка отримання напрямків: $e');
      return [];
    }
  }

  /// Оновити статус напрямку
  Future<void> updateDirectionStatus(String directionId, String status) async {
    try {
      await client.from('directions').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', directionId);
    } catch (e) {
      debugPrint('❌ Помилка оновлення напрямку: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STEPS (КРОКИ)
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти кроки
  Future<void> saveSteps(String goalId, Map<int, String> directionIds, List<StepModel> steps) async {
    if (!isAuthenticated) return;

    try {
      final data = steps.map((s) {
        final dirNumber = ((s.stepNumber - 1) ~/ 10) + 1;
        final directionId = directionIds[dirNumber];

        return {
          'goal_id': goalId,
          'direction_id': directionId,
          'step_number': s.stepNumber,
          'local_number': s.localNumber,
          'title': s.title,
          'description': s.description,
          'status': s.status.value,
          'block_number': s.blockNumber,
        };
      }).toList();

      await client.from('steps').insert(data);
      debugPrint('✅ Збережено ${steps.length} кроків');
    } catch (e) {
      debugPrint('❌ Помилка збереження кроків: $e');
    }
  }

  /// Отримати кроки для цілі
  Future<List<Map<String, dynamic>>> getSteps(String goalId) async {
    try {
      final response = await client
          .from('steps')
          .select()
          .eq('goal_id', goalId)
          .order('step_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Помилка отримання кроків: $e');
      return [];
    }
  }

  /// Оновити статус кроку (СТАРИЙ метод - залишаємо для сумісності)
  Future<void> updateStepStatus(String stepId, String status) async {
    try {
      await client.from('steps').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'done') 'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', stepId);

      debugPrint('✅ Крок оновлено: $status');
    } catch (e) {
      debugPrint('❌ Помилка оновлення кроку: $e');
    }
  }

  /// 🆕 Оновити статус кроку по stepNumber (НОВИЙ метод)
  Future<void> updateStepStatusByNumber({
    required int stepNumber,
    required String status,
  }) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return;
    }

    try {
      // Спочатку знаходимо останню ціль користувача
      final goal = await getLatestGoal();
      if (goal == null) {
        debugPrint('❌ Ціль не знайдена');
        return;
      }

      final goalId = goal['id'] as String;

      // Оновлюємо крок по goal_id + step_number
      await client.from('steps').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'done') 'completed_at': DateTime.now().toIso8601String(),
        if (status != 'done') 'completed_at': null,
      }).eq('goal_id', goalId).eq('step_number', stepNumber);

      debugPrint('✅ Крок #$stepNumber оновлено в Supabase: $status');
    } catch (e) {
      debugPrint('❌ Помилка оновлення кроку: $e');
    }
  }

  /// 🆕 Оновити статус кроку по goalId + stepNumber
  Future<void> updateStepStatusByGoalAndNumber({
    required String goalId,
    required int stepNumber,
    required String status,
  }) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return;
    }

    try {
      await client.from('steps').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'done') 'completed_at': DateTime.now().toIso8601String(),
        if (status != 'done') 'completed_at': null,
      }).eq('goal_id', goalId).eq('step_number', stepNumber);

      debugPrint('✅ Крок #$stepNumber (goal: $goalId) оновлено: $status');
    } catch (e) {
      debugPrint('❌ Помилка оновлення кроку: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ПОВНА СИНХРОНІЗАЦІЯ ПЛАНУ
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти повний план в Supabase (з upsert для цілі та очисткою дублікатів)
  Future<bool> saveFullPlan(CareerPlanModel plan) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return false;
    }

    try {
      // 1. Перевіряємо чи ціль вже існує (за title + user_id)
      String? goalId;
      final existingGoals = await client
          .from('goals')
          .select('id')
          .eq('user_id', userId!)
          .eq('title', plan.goal.title)
          .limit(1);

      if (existingGoals.isNotEmpty) {
        // Ціль вже існує — оновлюємо
        goalId = existingGoals.first['id'] as String;
        await client.from('goals').update({
          'target_salary': plan.goal.targetSalary,
          'match_score': plan.matchScore,
          'gap_analysis': plan.gapAnalysis,
          'is_active': true,
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', goalId);
        debugPrint('✅ Ціль оновлено: $goalId');
      } else {
        // Нова ціль — створюємо
        goalId = await saveGoal(
          title: plan.goal.title,
          targetSalary: plan.goal.targetSalary,
          matchScore: plan.matchScore,
          gapAnalysis: plan.gapAnalysis,
        );
        if (goalId == null) return false;
      }

      // 2. Видалити старі кроки та напрямки для цієї цілі
      await client.from('steps').delete().eq('goal_id', goalId);
      await client.from('directions').delete().eq('goal_id', goalId);
      debugPrint('🗑️ Старі напрямки та кроки видалено для цілі $goalId');

      // 3. Зберегти нові напрямки
      final directionIds = await saveDirections(goalId, plan.directions);

      // Створити мапу direction_number -> direction_id
      final dirIdMap = <int, String>{};
      for (int i = 0; i < plan.directions.length && i < directionIds.length; i++) {
        dirIdMap[plan.directions[i].directionNumber] = directionIds[i];
      }

      // 4. Зберегти нові кроки
      await saveSteps(goalId, dirIdMap, plan.steps);

      debugPrint('✅ Повний план синхронізовано з Supabase');
      return true;
    } catch (e) {
      debugPrint('❌ Помилка синхронізації плану: $e');
      return false;
    }
  }

  /// Завантажити план з Supabase
  Future<CareerPlanModel?> loadPlanFromCloud() async {
    if (!isAuthenticated) return null;

    try {
      // 1. Отримати активну ціль
      final goalData = await getActiveGoal();
      if (goalData == null) {
        debugPrint('📭 Активна ціль не знайдена в хмарі');
        return null;
      }

      final goalId = goalData['id'] as String;

      // 2. Отримати напрямки
      final directionsData = await getDirections(goalId);

      // 3. Отримати кроки
      final stepsData = await getSteps(goalId);

      // 4. Конвертувати в моделі
      final goal = GoalModel(
        id: goalId,
        userId: userId!,
        title: goalData['title'] as String,
        targetSalary: goalData['target_salary'] as String? ?? '',
        isPrimary: true,
        status: goalData['status'] as String? ?? 'active',
        createdAt: DateTime.parse(goalData['created_at'] as String),
      );

      final directions = directionsData.map((d) => DirectionModel(
        id: d['id'] as String,
        goalId: goalId,
        directionNumber: d['direction_number'] as int,
        title: d['title'] as String,
        description: d['description'] as String? ?? '',
        status: ItemStatusExtension.fromString(d['status'] as String? ?? 'pending'),
        blockNumber: d['block_number'] as int? ?? 1,
      )).toList();

      // Сортування напрямків по directionNumber
      directions.sort((a, b) => a.directionNumber.compareTo(b.directionNumber));

      // Дедуплікація напрямків по directionNumber (залишаємо перший)
      final seenDirNumbers = <int>{};
      directions.retainWhere((d) => seenDirNumbers.add(d.directionNumber));

      final steps = stepsData.map((s) => StepModel(
        id: s['id'] as String,
        goalId: goalId,
        directionId: s['direction_id'] as String,
        stepNumber: s['step_number'] as int,
        localNumber: s['local_number'] as int,
        title: s['title'] as String,
        description: s['description'] as String? ?? '',
        status: ItemStatusExtension.fromString(s['status'] as String? ?? 'pending'),
        blockNumber: s['block_number'] as int? ?? 1,
      )).toList();

      // Дедуплікація кроків по stepNumber (залишаємо перший)
      final seenStepNumbers = <int>{};
      steps.retainWhere((s) => seenStepNumbers.add(s.stepNumber));

      // Сортування кроків
      steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

      final plan = CareerPlanModel(
        goal: goal,
        matchScore: goalData['match_score'] as int? ?? 0,
        gapAnalysis: goalData['gap_analysis'] as String? ?? '',
        directions: directions,
        steps: steps,
        currentBlock: goalData['current_block'] as int? ?? 1,
      );

      debugPrint('✅ План завантажено з хмари: ${steps.length} кроків');
      return plan;
    } catch (e) {
      debugPrint('❌ Помилка завантаження плану: $e');
      return null;
    }
  }

  /// Завантажити план для конкретної цілі (за goalId та goalData)
  Future<CareerPlanModel?> loadPlanForGoal(String goalId, Map<String, dynamic> goalData) async {
    if (!isAuthenticated) return null;

    try {
      // 1. Отримати напрямки
      final directionsData = await getDirections(goalId);

      // 2. Отримати кроки
      final stepsData = await getSteps(goalId);

      // 3. Конвертувати в моделі
      final goal = GoalModel(
        id: goalId,
        userId: userId!,
        title: goalData['title'] as String,
        targetSalary: goalData['target_salary'] as String? ?? '',
        isPrimary: true,
        status: goalData['status'] as String? ?? 'active',
        createdAt: DateTime.parse(goalData['created_at'] as String),
      );

      final directions = directionsData.map((d) => DirectionModel(
        id: d['id'] as String,
        goalId: goalId,
        directionNumber: d['direction_number'] as int,
        title: d['title'] as String,
        description: d['description'] as String? ?? '',
        status: ItemStatusExtension.fromString(d['status'] as String? ?? 'pending'),
        blockNumber: d['block_number'] as int? ?? 1,
      )).toList();

      // Сортування напрямків по directionNumber
      directions.sort((a, b) => a.directionNumber.compareTo(b.directionNumber));

      // Дедуплікація напрямків по directionNumber (залишаємо перший)
      final seenDirNumbers = <int>{};
      directions.retainWhere((d) => seenDirNumbers.add(d.directionNumber));

      final steps = stepsData.map((s) => StepModel(
        id: s['id'] as String,
        goalId: goalId,
        directionId: s['direction_id'] as String,
        stepNumber: s['step_number'] as int,
        localNumber: s['local_number'] as int,
        title: s['title'] as String,
        description: s['description'] as String? ?? '',
        status: ItemStatusExtension.fromString(s['status'] as String? ?? 'pending'),
        blockNumber: s['block_number'] as int? ?? 1,
      )).toList();

      // Дедуплікація кроків по stepNumber (залишаємо перший)
      final seenStepNumbers = <int>{};
      steps.retainWhere((s) => seenStepNumbers.add(s.stepNumber));

      // Сортування кроків
      steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

      final plan = CareerPlanModel(
        goal: goal,
        matchScore: goalData['match_score'] as int? ?? 0,
        gapAnalysis: goalData['gap_analysis'] as String? ?? '',
        directions: directions,
        steps: steps,
        currentBlock: goalData['current_block'] as int? ?? 1,
      );

      debugPrint('✅ План для цілі $goalId завантажено: ${directions.length} напрямків, ${steps.length} кроків');
      return plan;
    } catch (e) {
      debugPrint('❌ Помилка завантаження плану для цілі $goalId: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CHAT MESSAGES
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти повідомлення чату
  Future<void> saveChatMessage({
    required String text,
    required bool isUser,
    String? goalId,
  }) async {
    if (!isAuthenticated) return;

    try {
      await client.from('chat_messages').insert({
        'user_id': userId,
        'goal_id': goalId,
        'text': text,
        'is_user': isUser,
      });
    } catch (e) {
      debugPrint('❌ Помилка збереження повідомлення: $e');
    }
  }

  /// Отримати історію чату
  Future<List<Map<String, dynamic>>> getChatHistory({
    int limit = 50,
    String? goalId,
  }) async {
    if (!isAuthenticated) return [];

    try {
      var query = client
          .from('chat_messages')
          .select()
          .eq('user_id', userId!);

      if (goalId != null) {
        query = query.eq('goal_id', goalId);
      } else {
        query = query.isFilter('goal_id', null);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response.reversed);
    } catch (e) {
      debugPrint('❌ Помилка отримання чату: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSESSMENT ANSWERS
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти відповіді оцінювання
  Future<void> saveAssessmentAnswers(Map<int, String> answers, {String? goalId}) async {
    if (!isAuthenticated) return;

    try {
      await client.from('assessment_answers').insert({
        'user_id': userId,
        'goal_id': goalId,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      });

      debugPrint('✅ Відповіді оцінювання збережено');
    } catch (e) {
      debugPrint('❌ Помилка збереження відповідей: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FCM TOKENS (PUSH NOTIFICATIONS)
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти FCM токен
  Future<void> saveFcmToken({
    required String token,
    required String deviceType,
    String? deviceName,
  }) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return;
    }

    try {
      // Upsert - оновити якщо існує, створити якщо ні
      await client.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'device_name': deviceName,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      debugPrint('✅ FCM токен збережено');
    } catch (e) {
      debugPrint('❌ Помилка збереження FCM токена: $e');
    }
  }

  /// Деактивувати FCM токен (при виході)
  Future<void> deactivateFcmToken(String token) async {
    if (!isAuthenticated) return;

    try {
      await client.from('user_fcm_tokens').update({
        'is_active': false,
      }).eq('user_id', userId!).eq('token', token);

      debugPrint('✅ FCM токен деактивовано');
    } catch (e) {
      debugPrint('❌ Помилка деактивації FCM токена: $e');
    }
  }

  /// Видалити всі FCM токени користувача
  Future<void> deleteAllFcmTokens() async {
    if (!isAuthenticated) return;

    try {
      await client.from('user_fcm_tokens').delete().eq('user_id', userId!);
      debugPrint('✅ Всі FCM токени видалено');
    } catch (e) {
      debugPrint('❌ Помилка видалення FCM токенів: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION SETTINGS
  // ═══════════════════════════════════════════════════════════════

  /// Отримати налаштування сповіщень
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('notification_settings')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Помилка отримання налаштувань сповіщень: $e');
      return null;
    }
  }

  /// Створити або оновити налаштування сповіщень
  Future<void> saveNotificationSettings({
    bool? pushEnabled,
    bool? telegramEnabled,
    String? reminderTime,
    String? frequency,
    bool? motivational,
    bool? stepReminders,
    bool? achievements,
    bool? weeklyStats,
  }) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return;
    }

    try {
      // Перевіряємо чи існують налаштування
      final existing = await getNotificationSettings();

      final data = {
        'user_id': userId,
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (telegramEnabled != null) 'telegram_enabled': telegramEnabled,
        if (reminderTime != null) 'reminder_time': reminderTime,
        if (frequency != null) 'frequency': frequency,
        if (motivational != null) 'motivational': motivational,
        if (stepReminders != null) 'step_reminders': stepReminders,
        if (achievements != null) 'achievements': achievements,
        if (weeklyStats != null) 'weekly_stats': weeklyStats,
      };

      if (existing == null) {
        // Створюємо нові
        await client.from('notification_settings').insert(data);
        debugPrint('✅ Налаштування сповіщень створено');
      } else {
        // Оновлюємо існуючі
        await client
            .from('notification_settings')
            .update(data)
            .eq('user_id', userId!);
        debugPrint('✅ Налаштування сповіщень оновлено');
      }
    } catch (e) {
      debugPrint('❌ Помилка збереження налаштувань сповіщень: $e');
    }
  }

  /// Ініціалізувати налаштування сповіщень за замовчуванням
  Future<void> initNotificationSettings() async {
    if (!isAuthenticated) return;

    try {
      final existing = await getNotificationSettings();
      if (existing == null) {
        await client.from('notification_settings').insert({
          'user_id': userId,
          'push_enabled': true,
          'telegram_enabled': true,
          'reminder_time': '09:00',
          'frequency': 'daily',
          'motivational': true,
          'step_reminders': true,
          'achievements': true,
          'weekly_stats': false,
        });
        debugPrint('✅ Налаштування сповіщень ініціалізовано');
      }
    } catch (e) {
      debugPrint('❌ Помилка ініціалізації налаштувань: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR ALL USER DATA
  // ═══════════════════════════════════════════════════════════════

  /// Видалити всі дані користувача з хмари
  /// Використовується при "Очистити дані" в профілі
  Future<void> clearAllUserData() async {
    if (!isAuthenticated) return;

    try {
      // 1. Видаляємо історію чату
      await client
          .from('chat_messages')
          .delete()
          .eq('user_id', userId!);
      debugPrint('✅ Історію чату видалено');

      // 2. Видаляємо прив'язку Telegram
      await client
          .from('telegram_users')
          .delete()
          .eq('user_id', userId!);
      debugPrint('✅ Прив\'язку Telegram видалено');

      // 3. Видаляємо всі цілі, напрямки, кроки (каскадно)
      await client
          .from('goals')
          .delete()
          .eq('user_id', userId!);
      debugPrint('✅ Цілі та плани видалено');

      // 4. Видаляємо відповіді оцінювання
      await client
          .from('assessment_answers')
          .delete()
          .eq('user_id', userId!);
      debugPrint('✅ Відповіді оцінювання видалено');

      // 5. Скидаємо налаштування сповіщень до дефолтних
      await client
          .from('notification_settings')
          .update({
            'push_enabled': false,
            'telegram_enabled': false,
            'frequency': 'daily',
            'reminder_time': '09:00',
          })
          .eq('user_id', userId!);
      debugPrint('✅ Налаштування сповіщень скинуто');

      debugPrint('🗑️ Всі дані користувача видалено з хмари');
    } catch (e) {
      debugPrint('❌ Помилка очищення даних: $e');
    }
  }
}
