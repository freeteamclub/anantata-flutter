import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервіс для роботи з Telegram інтеграцією
/// Версія: 1.0.0
/// Дата: 05.01.2026

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ім'я бота для посилань
  static const String botUsername = 'steps100bot';

  /// Генерує випадковий 6-символьний код
  String _generateLinkCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Без схожих символів (0,O,1,I)
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Перевіряє чи користувач авторизований
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Отримує ID поточного користувача
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Отримує статус прив'язки Telegram
  Future<TelegramLinkStatus> getLinkStatus() async {
    if (!isAuthenticated) {
      return TelegramLinkStatus.notAuthenticated();
    }

    try {
      final response = await _supabase
          .from('telegram_users')
          .select()
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (response == null) {
        return TelegramLinkStatus.notLinked();
      }

      final telegramId = response['telegram_id'];
      final linkedAt = response['linked_at'];

      if (telegramId != null && linkedAt != null) {
        return TelegramLinkStatus.linked(
          telegramUsername: response['telegram_username'],
          telegramFirstName: response['telegram_first_name'],
          linkedAt: DateTime.parse(linkedAt),
          notificationsEnabled: response['notifications_enabled'] ?? true,
          notificationFrequency: response['notification_frequency'] ?? 'daily',
        );
      }

      // Є запис але не прив'язано — перевіряємо код
      final linkCode = response['link_code'];
      final expiresAt = response['link_code_expires_at'];

      if (linkCode != null && expiresAt != null) {
        final expires = DateTime.parse(expiresAt);
        if (expires.isAfter(DateTime.now())) {
          return TelegramLinkStatus.pendingLink(
            linkCode: linkCode,
            expiresAt: expires,
          );
        }
      }

      return TelegramLinkStatus.notLinked();
    } catch (e) {
      print('TelegramService.getLinkStatus error: $e');
      return TelegramLinkStatus.error(e.toString());
    }
  }

  /// Генерує новий код прив'язки
  Future<TelegramLinkResult> generateLinkCode() async {
    if (!isAuthenticated) {
      return TelegramLinkResult.failure('Необхідно увійти в акаунт');
    }

    try {
      final linkCode = _generateLinkCode();
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      // Перевіряємо чи є існуючий запис
      final existing = await _supabase
          .from('telegram_users')
          .select('id')
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existing != null) {
        // Оновлюємо існуючий запис
        await _supabase
            .from('telegram_users')
            .update({
              'link_code': linkCode,
              'link_code_expires_at': expiresAt.toIso8601String(),
            })
            .eq('user_id', currentUserId!);
      } else {
        // Створюємо новий запис
        await _supabase.from('telegram_users').insert({
          'user_id': currentUserId,
          'link_code': linkCode,
          'link_code_expires_at': expiresAt.toIso8601String(),
        });
      }

      return TelegramLinkResult.success(
        linkCode: linkCode,
        expiresAt: expiresAt,
      );
    } catch (e) {
      print('TelegramService.generateLinkCode error: $e');
      return TelegramLinkResult.failure('Помилка генерації коду: $e');
    }
  }

  /// Відв'язує Telegram від акаунту
  Future<bool> unlinkTelegram() async {
    if (!isAuthenticated) return false;

    try {
      await _supabase
          .from('telegram_users')
          .delete()
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      print('TelegramService.unlinkTelegram error: $e');
      return false;
    }
  }

  /// Оновлює налаштування сповіщень
  Future<bool> updateNotificationSettings({
    bool? enabled,
    String? frequency,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final updates = <String, dynamic>{};
      if (enabled != null) updates['notifications_enabled'] = enabled;
      if (frequency != null) updates['notification_frequency'] = frequency;

      if (updates.isEmpty) return true;

      await _supabase
          .from('telegram_users')
          .update(updates)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      print('TelegramService.updateNotificationSettings error: $e');
      return false;
    }
  }

  /// Повертає посилання на бота з кодом
  String getBotLinkWithCode(String code) {
    return 'https://t.me/$botUsername?start=$code';
  }

  /// Повертає посилання на бота
  String get botLink => 'https://t.me/$botUsername';
}

/// Статус прив'язки Telegram
class TelegramLinkStatus {
  final TelegramLinkState state;
  final String? telegramUsername;
  final String? telegramFirstName;
  final DateTime? linkedAt;
  final String? linkCode;
  final DateTime? expiresAt;
  final bool notificationsEnabled;
  final String notificationFrequency;
  final String? errorMessage;

  TelegramLinkStatus._({
    required this.state,
    this.telegramUsername,
    this.telegramFirstName,
    this.linkedAt,
    this.linkCode,
    this.expiresAt,
    this.notificationsEnabled = true,
    this.notificationFrequency = 'daily',
    this.errorMessage,
  });

  factory TelegramLinkStatus.notAuthenticated() =>
      TelegramLinkStatus._(state: TelegramLinkState.notAuthenticated);

  factory TelegramLinkStatus.notLinked() =>
      TelegramLinkStatus._(state: TelegramLinkState.notLinked);

  factory TelegramLinkStatus.pendingLink({
    required String linkCode,
    required DateTime expiresAt,
  }) =>
      TelegramLinkStatus._(
        state: TelegramLinkState.pendingLink,
        linkCode: linkCode,
        expiresAt: expiresAt,
      );

  factory TelegramLinkStatus.linked({
    String? telegramUsername,
    String? telegramFirstName,
    required DateTime linkedAt,
    bool notificationsEnabled = true,
    String notificationFrequency = 'daily',
  }) =>
      TelegramLinkStatus._(
        state: TelegramLinkState.linked,
        telegramUsername: telegramUsername,
        telegramFirstName: telegramFirstName,
        linkedAt: linkedAt,
        notificationsEnabled: notificationsEnabled,
        notificationFrequency: notificationFrequency,
      );

  factory TelegramLinkStatus.error(String message) =>
      TelegramLinkStatus._(
        state: TelegramLinkState.error,
        errorMessage: message,
      );

  bool get isLinked => state == TelegramLinkState.linked;
  bool get isPending => state == TelegramLinkState.pendingLink;
  bool get isNotLinked => state == TelegramLinkState.notLinked;
}

enum TelegramLinkState {
  notAuthenticated,
  notLinked,
  pendingLink,
  linked,
  error,
}

/// Результат операції прив'язки
class TelegramLinkResult {
  final bool success;
  final String? linkCode;
  final DateTime? expiresAt;
  final String? errorMessage;

  TelegramLinkResult._({
    required this.success,
    this.linkCode,
    this.expiresAt,
    this.errorMessage,
  });

  factory TelegramLinkResult.success({
    required String linkCode,
    required DateTime expiresAt,
  }) =>
      TelegramLinkResult._(
        success: true,
        linkCode: linkCode,
        expiresAt: expiresAt,
      );

  factory TelegramLinkResult.failure(String message) =>
      TelegramLinkResult._(
        success: false,
        errorMessage: message,
      );
}
