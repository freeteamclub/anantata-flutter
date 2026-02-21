import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';

/// Централізований сервіс аналітики
/// Підтримує Firebase Analytics + Amplitude
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _firebase = FirebaseAnalytics.instance;
  late final Amplitude _amplitude;
  bool _amplitudeInitialized = false;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _firebase);

  /// Ініціалізація Amplitude (викликати в main.dart)
  Future<void> initialize() async {
    if (_amplitudeInitialized) return;

    _amplitude = Amplitude(Configuration(
      apiKey: '9e72d816e2bfac6a016e651a640e8834',
    ));

    _amplitudeInitialized = true;
  }

  /// Безпечний виклик Firebase — не крешить додаток при помилках
  Future<void> _safeFirebase(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Analytics error: $e');
    }
  }

  // ==================== User Properties ====================

  Future<void> setUserId(String? userId) async {
    await _safeFirebase(() => _firebase.setUserId(id: userId));
    if (_amplitudeInitialized) {
      if (userId != null) {
        _amplitude.setUserId(userId);
      } else {
        _amplitude.reset();
      }
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    await _safeFirebase(() => _firebase.setUserProperty(name: name, value: value));
  }

  // ==================== Screen Tracking ====================

  Future<void> logScreenView(String screenName) async {
    await _safeFirebase(() => _firebase.logScreenView(screenName: screenName));
    _trackAmplitude('screen_view', {'screen_name': screenName});
  }

  // ==================== Auth Events ====================

  Future<void> logLogin(String method) async {
    await _safeFirebase(() => _firebase.logLogin(loginMethod: method));
    _trackAmplitude('login', {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await _safeFirebase(() => _firebase.logSignUp(signUpMethod: method));
    _trackAmplitude('sign_up', {'method': method});
  }

  Future<void> logLogout() async {
    await _safeFirebase(() => _firebase.logEvent(name: 'logout'));
    _trackAmplitude('logout', {});
  }

  // ==================== Assessment Events ====================

  Future<void> logAssessmentStarted() async {
    await _safeFirebase(() => _firebase.logEvent(name: 'assessment_started'));
    _trackAmplitude('assessment_started', {});
  }

  Future<void> logAssessmentQuestionAnswered({
    required int questionNumber,
    required int totalQuestions,
  }) async {
    final params = {
      'question_number': questionNumber,
      'total_questions': totalQuestions,
      'progress_percent': ((questionNumber / totalQuestions) * 100).round(),
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'assessment_question_answered', parameters: params));
    _trackAmplitude('assessment_question_answered', params);
  }

  Future<void> logAssessmentCompleted({
    required int questionsAnswered,
    required int durationSeconds,
  }) async {
    final params = {
      'questions_answered': questionsAnswered,
      'duration_seconds': durationSeconds,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'assessment_completed', parameters: params));
    _trackAmplitude('assessment_completed', params);
  }

  Future<void> logAssessmentAbandoned({
    required int questionsAnswered,
  }) async {
    final params = {'questions_answered': questionsAnswered};
    await _safeFirebase(() => _firebase.logEvent(name: 'assessment_abandoned', parameters: params));
    _trackAmplitude('assessment_abandoned', params);
  }

  // ==================== Goal Events ====================

  Future<void> logGoalCreated({
    required String goalId,
    required String goalTitle,
  }) async {
    final params = {
      'goal_id': goalId,
      'goal_title': goalTitle.length > 100 ? goalTitle.substring(0, 100) : goalTitle,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'goal_created', parameters: params));
    _trackAmplitude('goal_created', params);
  }

  Future<void> logGoalDeleted({required String goalId}) async {
    final params = {'goal_id': goalId};
    await _safeFirebase(() => _firebase.logEvent(name: 'goal_deleted', parameters: params));
    _trackAmplitude('goal_deleted', params);
  }

  // ==================== Step Events ====================

  Future<void> logStepCompleted({
    required String stepId,
    required int stepNumber,
    required int phaseNumber,
  }) async {
    final params = {
      'step_id': stepId,
      'step_number': stepNumber,
      'phase_number': phaseNumber,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'step_completed', parameters: params));
    _trackAmplitude('step_completed', params);
  }

  Future<void> logStepSkipped({
    required String stepId,
    required int stepNumber,
    required int phaseNumber,
  }) async {
    final params = {
      'step_id': stepId,
      'step_number': stepNumber,
      'phase_number': phaseNumber,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'step_skipped', parameters: params));
    _trackAmplitude('step_skipped', params);
  }

  Future<void> logStepReset({
    required String stepId,
    required int stepNumber,
  }) async {
    final params = {
      'step_id': stepId,
      'step_number': stepNumber,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'step_reset', parameters: params));
    _trackAmplitude('step_reset', params);
  }

  // ==================== Chat Events ====================

  Future<void> logChatSessionStarted({
    required String chatType, // 'general' or 'step'
    String? stepId,
  }) async {
    final params = <String, Object>{
      'chat_type': chatType,
      if (stepId != null) 'step_id': stepId,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'chat_session_started', parameters: params));
    _trackAmplitude('chat_session_started', params);
  }

  Future<void> logChatSessionEnded({
    required String chatType,
    required int messagesCount,
    required int durationSeconds,
  }) async {
    final params = {
      'chat_type': chatType,
      'messages_count': messagesCount,
      'duration_seconds': durationSeconds,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'chat_session_ended', parameters: params));
    _trackAmplitude('chat_session_ended', params);
  }

  Future<void> logChatMessageSent({
    required int messageLength,
    required String chatType, // 'general' or 'step'
  }) async {
    final params = {
      'message_length': messageLength,
      'chat_type': chatType,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'chat_message_sent', parameters: params));
    _trackAmplitude('chat_message_sent', params);
  }

  Future<void> logChatResponseReceived({
    required int responseLength,
    required int responseTimeMs,
    required String chatType,
  }) async {
    final params = {
      'response_length': responseLength,
      'response_time_ms': responseTimeMs,
      'chat_type': chatType,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'chat_response_received', parameters: params));
    _trackAmplitude('chat_response_received', params);
  }

  // ==================== Telegram Events ====================

  Future<void> logTelegramLinkStarted() async {
    await _safeFirebase(() => _firebase.logEvent(name: 'telegram_link_started'));
    _trackAmplitude('telegram_link_started', {});
  }

  Future<void> logTelegramLinked() async {
    await _safeFirebase(() => _firebase.logEvent(name: 'telegram_linked'));
    _trackAmplitude('telegram_linked', {});
  }

  Future<void> logTelegramUnlinked() async {
    await _safeFirebase(() => _firebase.logEvent(name: 'telegram_unlinked'));
    _trackAmplitude('telegram_unlinked', {});
  }

  // ==================== Notification Events ====================

  Future<void> logNotificationSettingsChanged({
    required String channel,
    required String frequency,
    required String time,
  }) async {
    final params = {
      'channel': channel,
      'frequency': frequency,
      'time': time,
    };
    await _safeFirebase(() => _firebase.logEvent(name: 'notification_settings_changed', parameters: params));
    _trackAmplitude('notification_settings_changed', params);
  }

  // ==================== Share Events ====================

  Future<void> logShare({
    required String contentType,
    required String itemId,
  }) async {
    await _safeFirebase(() => _firebase.logShare(contentType: contentType, itemId: itemId, method: 'app'));
    _trackAmplitude('share', {'content_type': contentType, 'item_id': itemId});
  }

  // ==================== Sync Events ====================

  Future<void> logSyncConflict({
    required String resolution,
  }) async {
    final params = {'resolution': resolution};
    await _safeFirebase(() => _firebase.logEvent(name: 'sync_conflict', parameters: params));
    _trackAmplitude('sync_conflict', params);
  }

  // ==================== Generic Event ====================

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await _safeFirebase(() => _firebase.logEvent(name: name, parameters: parameters));
    _trackAmplitude(name, parameters ?? {});
  }

  // ==================== Amplitude Helper ====================

  void _trackAmplitude(String eventName, Map<String, Object> properties) {
    if (_amplitudeInitialized) {
      _amplitude.track(BaseEvent(
        eventName,
        eventProperties: properties,
      ));
    }
  }
}
