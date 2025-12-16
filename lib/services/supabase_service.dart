import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anantata/models/career_plan_model.dart';

/// Сервіс для роботи з Supabase
/// Версія: 2.2.0 - Фільтрація чату по goalId
/// Дата: 15.12.2025

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
    // serverClientId = Web Client ID (для отримання idToken)
    // clientId не вказуємо для Android (використовує з google-services.json або SHA-1)
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: googleClientId, // Web Client ID
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
    // Вийти з Google
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Google Sign-Out помилка: $e');
    }

    // Вийти з Supabase
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
        // Знаходимо direction_id за номером напрямку
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

  /// Оновити статус кроку
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

  // ═══════════════════════════════════════════════════════════════
  // ПОВНА СИНХРОНІЗАЦІЯ ПЛАНУ
  // ═══════════════════════════════════════════════════════════════

  /// Зберегти повний план в Supabase
  Future<bool> saveFullPlan(CareerPlanModel plan) async {
    if (!isAuthenticated) {
      debugPrint('❌ Користувач не авторизований');
      return false;
    }

    try {
      // 1. Зберегти ціль
      final goalId = await saveGoal(
        title: plan.goal.title,
        targetSalary: plan.goal.targetSalary,
        matchScore: plan.matchScore,
        gapAnalysis: plan.gapAnalysis,
      );

      if (goalId == null) return false;

      // 2. Зберегти напрямки
      final directionIds = await saveDirections(goalId, plan.directions);

      // Створити мапу direction_number -> direction_id
      final dirIdMap = <int, String>{};
      for (int i = 0; i < plan.directions.length && i < directionIds.length; i++) {
        dirIdMap[plan.directions[i].directionNumber] = directionIds[i];
      }

      // 3. Зберегти кроки
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
  /// Якщо goalId = null, отримує загальний чат
  /// Якщо goalId вказано, отримує чат для конкретної цілі
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

      // Фільтруємо по goalId
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
}