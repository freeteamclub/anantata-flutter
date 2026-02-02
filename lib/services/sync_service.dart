import 'package:flutter/foundation.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';

/// Тип конфлікту між локальним і хмарним планами
enum SyncConflict { none, localOnly, cloudOnly, both }

/// Результат перевірки конфлікту
class SyncConflictResult {
  final SyncConflict conflict;
  final String? cloudGoalTitle;
  final CareerPlanModel? cloudPlan;
  final CareerPlanModel? localPlan;

  SyncConflictResult({
    required this.conflict,
    this.cloudGoalTitle,
    this.cloudPlan,
    this.localPlan,
  });
}

/// Сервіс синхронізації даних між локальним сховищем і Supabase
/// Версія: 2.0.0 — Додано checkConflict() та діалог конфлікту
/// Дата: 03.02.2026

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

  /// Перевірити тип конфлікту між локальним і хмарним планами
  /// Не змінює дані — лише визначає стан
  Future<SyncConflictResult> checkConflict() async {
    if (!isAuthenticated) {
      return SyncConflictResult(conflict: SyncConflict.none);
    }

    debugPrint('🔍 Перевірка конфлікту планів...');

    final localPlan = await _storage.getCareerPlan();
    final cloudPlan = await syncPlanFromCloud();

    if (cloudPlan != null && localPlan != null) {
      debugPrint('⚠️ Конфлікт: є і локальний, і хмарний плани');
      return SyncConflictResult(
        conflict: SyncConflict.both,
        cloudGoalTitle: cloudPlan.goal.title,
        cloudPlan: cloudPlan,
        localPlan: localPlan,
      );
    } else if (cloudPlan != null) {
      debugPrint('☁️ Тільки хмарний план');
      return SyncConflictResult(
        conflict: SyncConflict.cloudOnly,
        cloudGoalTitle: cloudPlan.goal.title,
        cloudPlan: cloudPlan,
      );
    } else if (localPlan != null) {
      debugPrint('📱 Тільки локальний план');
      return SyncConflictResult(
        conflict: SyncConflict.localOnly,
        localPlan: localPlan,
      );
    }

    debugPrint('📭 Планів не знайдено');
    return SyncConflictResult(conflict: SyncConflict.none);
  }

  /// Замінити локальний план на хмарний
  Future<CareerPlanModel?> applyCloudPlan(CareerPlanModel cloudPlan) async {
    debugPrint('📥 Заміна локального плану на хмарний...');
    await _storage.savePlanFromCloud(cloudPlan);
    return cloudPlan;
  }

  /// Завантажити локальний план у хмару (перезаписати хмарний)
  Future<void> applyLocalPlan(CareerPlanModel localPlan) async {
    debugPrint('📤 Завантаження локального плану в хмару...');
    await syncPlanToCloud(localPlan);
  }

  /// Повна синхронізація при вході
  /// Логіка: якщо в хмарі є план - використовуємо його
  Future<CareerPlanModel?> syncOnLogin() async {
    if (!isAuthenticated) return null;

    debugPrint('🔄 Синхронізація при вході...');

    final result = await checkConflict();

    switch (result.conflict) {
      case SyncConflict.cloudOnly:
        debugPrint('📥 Використовуємо хмарний план');
        await _storage.savePlanFromCloud(result.cloudPlan!);
        return result.cloudPlan;

      case SyncConflict.localOnly:
        debugPrint('📤 Завантажуємо локальний план в хмару');
        await syncPlanToCloud(result.localPlan!);
        return result.localPlan;

      case SyncConflict.both:
        // При конфлікті — хмарний має перевагу
        debugPrint('🔀 Є обидва плани — замінюємо локальний на хмарний');
        await _storage.savePlanFromCloud(result.cloudPlan!);
        return result.cloudPlan;

      case SyncConflict.none:
        debugPrint('📭 Планів не знайдено');
        return null;
    }
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