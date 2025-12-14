import 'package:flutter/foundation.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';

/// Сервіс синхронізації даних між локальним сховищем і Supabase
/// Версія: 1.0.0
/// Дата: 14.12.2025

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();

  bool _isSyncing = false;

  /// Чи авторизований користувач
  bool get isAuthenticated => _supabase.isAuthenticated;

  // ═══════════════════════════════════════════════════════════════
  // СИНХРОНІЗАЦІЯ ПЛАНУ
  // ═══════════════════════════════════════════════════════════════

  /// Синхронізувати план після генерації (локально → хмара)
  Future<bool> syncPlanToCloud(CareerPlanModel plan) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Користувач не авторизований - план збережено тільки локально');
      return false;
    }

    if (_isSyncing) {
      debugPrint('⚠️ Синхронізація вже виконується');
      return false;
    }

    _isSyncing = true;
    debugPrint('☁️ Синхронізація плану в хмару...');

    try {
      final success = await _supabase.saveFullPlan(plan);

      if (success) {
        debugPrint('✅ План синхронізовано в хмару');
      } else {
        debugPrint('❌ Помилка синхронізації плану');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Помилка синхронізації: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Завантажити план з хмари (хмара → локально)
  Future<CareerPlanModel?> syncPlanFromCloud() async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Користувач не авторизований');
      return null;
    }

    debugPrint('☁️ Завантаження плану з хмари...');

    try {
      final cloudPlan = await _supabase.loadPlanFromCloud();

      if (cloudPlan != null) {
        debugPrint('✅ План завантажено з хмари: ${cloudPlan.steps.length} кроків');
        return cloudPlan;
      } else {
        debugPrint('📭 План не знайдено в хмарі');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Помилка завантаження з хмари: $e');
      return null;
    }
  }

  /// Повна синхронізація при вході
  /// Логіка: якщо в хмарі є план - використовуємо його
  Future<CareerPlanModel?> syncOnLogin() async {
    if (!isAuthenticated) return null;

    debugPrint('🔄 Синхронізація при вході...');

    // 1. Отримуємо локальний план
    final localPlan = await _storage.getCareerPlan();

    // 2. Отримуємо хмарний план
    final cloudPlan = await syncPlanFromCloud();

    // 3. Визначаємо який план використовувати
    if (cloudPlan != null && localPlan == null) {
      // Є хмарний, немає локального → зберігаємо хмарний локально
      debugPrint('📥 Використовуємо хмарний план');
      // TODO: Зберегти cloudPlan локально
      return cloudPlan;
    } else if (cloudPlan == null && localPlan != null) {
      // Є локальний, немає хмарного → завантажуємо локальний в хмару
      debugPrint('📤 Завантажуємо локальний план в хмару');
      await syncPlanToCloud(localPlan);
      return localPlan;
    } else if (cloudPlan != null && localPlan != null) {
      // Є обидва → порівнюємо за датою (поки просто беремо хмарний)
      debugPrint('🔀 Є обидва плани - використовуємо хмарний');
      return cloudPlan;
    }

    // Немає жодного плану
    debugPrint('📭 Планів не знайдено');
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // СИНХРОНІЗАЦІЯ СТАТУСУ КРОКІВ
  // ═══════════════════════════════════════════════════════════════

  /// Синхронізувати статус кроку
  Future<void> syncStepStatus(String stepId, String status) async {
    if (!isAuthenticated) return;

    try {
      await _supabase.updateStepStatus(stepId, status);
      debugPrint('✅ Статус кроку синхронізовано: $stepId → $status');
    } catch (e) {
      debugPrint('❌ Помилка синхронізації статусу: $e');
    }
  }

  /// Синхронізувати статус напрямку
  Future<void> syncDirectionStatus(String directionId, String status) async {
    if (!isAuthenticated) return;

    try {
      await _supabase.updateDirectionStatus(directionId, status);
      debugPrint('✅ Статус напрямку синхронізовано: $directionId → $status');
    } catch (e) {
      debugPrint('❌ Помилка синхронізації статусу напрямку: $e');
    }
  }
}