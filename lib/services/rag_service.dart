// RAG Service — семантична пам'ять для AI-коуча
// Колекція 100steps_users на Hetzner (ізольована від персональної пам'яті)
// Версія: 1.0.0
// Тікет: Sprint 4 (T13, T15)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Результат RAG пошуку
class RAGResult {
  final String text;
  final String role;
  final String source;
  final double score;
  final String? timestamp;
  final int? stepNumber;

  RAGResult({
    required this.text,
    required this.role,
    required this.source,
    required this.score,
    this.timestamp,
    this.stepNumber,
  });

  factory RAGResult.fromJson(Map<String, dynamic> json) {
    return RAGResult(
      text: json['text'] ?? '',
      role: json['role'] ?? '',
      source: json['source'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      timestamp: json['timestamp'],
      stepNumber: json['step_number'],
    );
  }
}

/// RAG Service — HTTP клієнт до RAG API на Hetzner
class RAGService {
  static RAGService? _instance;
  factory RAGService() {
    _instance ??= RAGService._internal();
    return _instance!;
  }
  RAGService._internal();

  static const String _baseUrl = 'http://46.62.204.28:8100/100steps';
  static const Duration _timeout = Duration(seconds: 10);

  /// Семантичний пошук по пам'яті користувача
  Future<List<RAGResult>> search(
    String query,
    String userId, {
    int limit = 3,
    String? source,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'user_id': userId,
          'limit': limit,
          if (source != null) 'source': source,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List)
            .map((r) => RAGResult.fromJson(r))
            .toList();
        debugPrint('🔍 RAG: ${results.length} results for "$query"');
        return results;
      } else {
        debugPrint('❌ RAG search error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ RAG search failed: $e');
      return [];
    }
  }

  /// Додати повідомлення в RAG пам'ять
  Future<void> addMessage({
    required String text,
    required String userId,
    String role = 'user',
    String source = 'chat',
    String? goalId,
    int? stepNumber,
    String? conversationId,
  }) async {
    // Не індексуємо короткі повідомлення
    if (text.length < 10) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'user_id': userId,
          'role': role,
          'source': source,
          if (goalId != null) 'goal_id': goalId,
          if (stepNumber != null) 'step_number': stepNumber,
          if (conversationId != null) 'conversation_id': conversationId,
        }),
      ).timeout(_timeout);

      debugPrint('📝 RAG: Added $role msg (${text.length} chars)');
    } catch (e) {
      // Не блокуємо UX якщо RAG недоступний
      debugPrint('⚠️ RAG add failed (non-blocking): $e');
    }
  }

  /// Batch додавання (для assessment, міграції)
  Future<int> addBatch(String userId, List<Map<String, dynamic>> documents) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'documents': documents,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final added = data['added'] ?? 0;
        debugPrint('📦 RAG batch: Added $added docs');
        return added;
      }
      return 0;
    } catch (e) {
      debugPrint('⚠️ RAG batch failed: $e');
      return 0;
    }
  }

  /// Форматує RAG результати для промпту Gemini
  static String formatForPrompt(List<RAGResult> results) {
    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('РЕЛЕВАНТНИЙ КОНТЕКСТ З ПОПЕРЕДНІХ РОЗМОВ:');
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      final roleLabel = r.role == 'user' ? 'Користувач' : 'Коуч';
      buffer.writeln('${i + 1}. [$roleLabel]: ${r.text}');
    }
    return buffer.toString();
  }
}
