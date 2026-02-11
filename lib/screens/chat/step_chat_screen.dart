import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/gemini_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/analytics_service.dart';
import 'package:anantata/services/profile_summary_service.dart';  // T7
import 'package:anantata/services/rag_service.dart';  // Sprint 4
import 'package:anantata/screens/chat/chat_choices_parser.dart';  // T11

/// Екран чату для допомоги по конкретному кроку
/// Версія: 1.5.0 - Виправлено URL
/// Дата: 18.01.2026
///
/// Зміни v1.3.0:
/// - AppBar тепер показує "Головна / Крок N" (глобальний номер)
/// - Використовується stepNumber замість localNumber
///
/// Функціонал:
/// - Контекстний чат для роботи над конкретним кроком
/// - AI починає з уточнюючих питань (по одному)
/// - Теплий, дружній тон спілкування
/// - Збереження: Supabase (залогінений) / SharedPreferences (локально)

class StepChatScreen extends StatefulWidget {
  final StepModel step;
  final String goalTitle;
  final String goalId;
  final String? targetSalary;
  final String? directionTitle;  // T5: Назва напрямку для промпту

  const StepChatScreen({
    super.key,
    required this.step,
    required this.goalTitle,
    required this.goalId,
    this.targetSalary,
    this.directionTitle,
  });

  @override
  State<StepChatScreen> createState() => _StepChatScreenState();
}

class _StepChatScreenState extends State<StepChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final SupabaseService _supabase = SupabaseService();
  final ProfileSummaryService _profileSummaryService = ProfileSummaryService();  // T7
  final RAGService _ragService = RAGService();  // Sprint 4

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  String? _profileSummary;  // T7: Profile Summary для персоналізації
  String? _assessmentContext;  // Sprint 4: Assessment контекст
  String _ragContext = '';  // Sprint 4: RAG контекст

  // Analytics: session tracking
  DateTime? _sessionStartTime;
  int _sessionMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    // Analytics: step chat session started
    _sessionStartTime = DateTime.now();
    AnalyticsService().logChatSessionStarted(chatType: 'step', stepId: widget.step.id);
  }

  @override
  void dispose() {
    // Analytics: step chat session ended
    if (_sessionStartTime != null && _sessionMessagesCount > 0) {
      final durationSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      AnalyticsService().logChatSessionEnded(
        chatType: 'step',
        messagesCount: _sessionMessagesCount,
        durationSeconds: durationSeconds,
      );
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _localStorageKey => 'step_chat_${widget.goalId}_${widget.step.id}';

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);

    debugPrint('📥 Завантаження чату для кроку: ${widget.step.id}');

    // T7: Завантажуємо profile_summary для персоналізації
    try {
      _profileSummary = await _profileSummaryService.getSummary();
      debugPrint('📝 Profile summary: ${_profileSummary != null ? "${_profileSummary!.length} символів" : "немає"}');
    } catch (e) {
      debugPrint('⚠️ Помилка завантаження profile_summary: $e');
    }

    // Sprint 4: Завантажуємо assessment контекст
    try {
      final answers = await _supabase.getAssessmentAnswers();
      if (answers != null && answers.isNotEmpty) {
        _assessmentContext = answers.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      }
    } catch (e) {
      debugPrint('⚠️ Assessment context: $e');
    }

    // Sprint 4: RAG контекст по темі кроку
    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.client.auth.currentUser?.id;
        if (userId != null) {
          final ragResults = await _ragService.search(
            widget.step.title,
            userId,
            limit: 3,
          );
          _ragContext = RAGService.formatForPrompt(ragResults);
        }
      }
    } catch (e) {
      debugPrint('⚠️ RAG context: $e');
    }

    try {
      if (_supabase.isAuthenticated) {
        await _loadFromSupabase();
      } else {
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint('❌ Помилка завантаження чату: $e');
    }

    if (_messages.isEmpty) {
      _addInitialMessage();
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _supabase.client.auth.currentUser?.id;
    debugPrint('🔑 User ID: $userId');
    
    if (userId != null) {
      final response = await _supabase.client
          .from('step_chats')
          .select('messages')
          .eq('user_id', userId)
          .eq('step_id', widget.step.id)
          .eq('goal_id', widget.goalId)
          .maybeSingle();

      debugPrint('📦 Відповідь Supabase: $response');

      if (response != null && response['messages'] != null) {
        _parseMessages(response['messages']);
        debugPrint('✅ Завантажено ${_messages.length} повідомлень з Supabase');
      }
    }
  }

  Future<void> _loadFromLocal() async {
    debugPrint('📱 Завантаження локально...');
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_localStorageKey);
    
    if (jsonString != null) {
      final List<dynamic> messagesJson = jsonDecode(jsonString);
      _parseMessages(messagesJson);
      debugPrint('✅ Завантажено ${_messages.length} повідомлень локально');
    }
  }

  void _parseMessages(List<dynamic> messagesJson) {
    setState(() {
      _messages.clear();
      for (final msg in messagesJson) {
        _messages.add(_ChatMessage(
          text: msg['text'] ?? '',
          isUser: msg['isUser'] ?? false,
          timestamp: DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
        ));
      }
    });
  }

  Future<void> _saveChatHistory() async {
    debugPrint('📤 Спроба збереження чату...');
    
    final messagesJson = _messages.map((m) => {
      'text': m.text,
      'isUser': m.isUser,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();

    try {
      if (_supabase.isAuthenticated) {
        await _saveToSupabase(messagesJson);
      } else {
        await _saveToLocal(messagesJson);
      }
    } catch (e) {
      debugPrint('❌ Помилка збереження чату: $e');
    }
  }

  Future<void> _saveToSupabase(List<Map<String, dynamic>> messagesJson) async {
    final userId = _supabase.client.auth.currentUser?.id;
    if (userId == null) return;

    debugPrint('☁️ Зберігаємо ${messagesJson.length} повідомлень в Supabase');

    await _supabase.client.from('step_chats').upsert({
      'user_id': userId,
      'step_id': widget.step.id,
      'goal_id': widget.goalId,
      'messages': messagesJson,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,step_id,goal_id');

    debugPrint('✅ Чат збережено в Supabase!');
  }

  Future<void> _saveToLocal(List<Map<String, dynamic>> messagesJson) async {
    debugPrint('📱 Зберігаємо ${messagesJson.length} повідомлень локально');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localStorageKey, jsonEncode(messagesJson));
    
    debugPrint('✅ Чат збережено локально!');
  }

  void _addInitialMessage() {
    final greeting = _buildGreetingMessage();
    
    setState(() {
      _messages.add(_ChatMessage(
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _saveChatHistory();
  }

  String _buildGreetingMessage() {
    final stepTitle = widget.step.title;
    final directionName = widget.directionTitle ?? '';
    final description = widget.step.description;

    String greeting = 'Привіт! 👋 Я — твій Коуч.\n\n';
    greeting += '📋 **$stepTitle**\n';
    if (directionName.isNotEmpty) {
      greeting += '📂 Напрямок: $directionName\n';
    }
    greeting += '\n**Що зробити:** $description\n\n';
    greeting += '**Як я можу допомогти:**\n';
    greeting += '• Пояснити крок детальніше\n';
    greeting += '• Підібрати ресурси та курси\n';
    greeting += '• Допомогти з конкретним завданням\n';
    greeting += '• Перевірити твій результат\n\n';
    greeting += 'Готовий починати? 💪';

    return greeting;
  }

  String _buildSystemContext() {
    // T7: profile_summary для персоналізації
    final profileBlock = (_profileSummary != null && _profileSummary!.isNotEmpty)
        ? '\nПРОФІЛЬ КОРИСТУВАЧА:\n$_profileSummary\n'
        : '';

    // Sprint 4: Assessment контекст
    final assessmentBlock = (_assessmentContext != null && _assessmentContext!.isNotEmpty)
        ? '\nПОЧАТКОВЕ ОЦІНЮВАННЯ:\n$_assessmentContext\n'
        : '';

    // Sprint 4: RAG контекст
    final ragBlock = _ragContext.isNotEmpty ? '\n$_ragContext' : '';

    // T5: Назва напрямку
    final directionName = widget.directionTitle ?? '';
    final directionBlock = directionName.isNotEmpty
        ? 'НАПРЯМОК: $directionName'
        : '';

    // Sprint 4: Деталі кроку
    final step = widget.step;
    final stepDetails = <String>[];
    if (step.type != null) stepDetails.add('Тип: ${step.type}');
    if (step.difficulty != null) stepDetails.add('Складність: ${step.difficulty}');
    if (step.estimatedTime != null) stepDetails.add('Час: ${step.estimatedTime}');
    if (step.expectedOutcome != null) stepDetails.add('Очікуваний результат: ${step.expectedOutcome}');
    final stepDetailsText = stepDetails.isNotEmpty
        ? stepDetails.join('\n')
        : '';

    return '''
Ти — Коуч, персональний AI-помічник в додатку 100Steps Career.
Користувач відкрив конкретний крок свого кар'єрного плану.
$profileBlock$assessmentBlock
ЦІЛЬ: ${widget.goalTitle}
${widget.targetSalary != null ? 'БАЖАНИЙ ДОХІД: ${widget.targetSalary}' : ''}
$directionBlock
КРОК ${step.stepNumber}/100: ${step.title}
ОПИС КРОКУ: ${step.description}
${stepDetailsText.isNotEmpty ? stepDetailsText : ''}
$ragBlock
ПРИ ПЕРШОМУ ПОВІДОМЛЕННІ користувача — покажи картку кроку у форматі:
📋 **${step.title}**
${directionName.isNotEmpty ? '📂 Напрямок: $directionName' : ''}

**Що зробити:** ${step.description}

**Як я можу допомогти:**
• Пояснити крок детальніше
• Підібрати ресурси та курси
• Допомогти з конкретним завданням
• Перевірити твій результат

ПРАВИЛА:
- Конкретні поради під цього користувача (використовуй профіль та оцінювання)
- Реальні ресурси з посиланнями (курси, статті, інструменти)
- Давай feedback на результати користувача
- Коли крок виконаний → запропонуй наступний
- ЗАДАВАЙ ТІЛЬКИ ОДНЕ ПИТАННЯ за раз
- Спілкуйся на "ти", дружньо, але професійно
- НЕ вітайся після першого повідомлення (привітання вже було)
- Відповідай українською
- Тримай відповіді стислими, але змістовними
- Використовуй **жирний** для акцентів

ФОРМАТ ВИБОРУ (ОБОВ'ЯЗКОВО):
Коли пропонуєш варіанти дій, оберни їх у спеціальний блок:
[CHOICES]
Варіант 1
Варіант 2
Варіант 3
[/CHOICES]
Використовуй це в кінці повідомлення коли є 2-4 варіанти дій для користувача.
''';
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _saveChatHistory();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _saveChatHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickAction]) async {
    final text = quickAction ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (quickAction == null) {
      _messageController.clear();
    }

    _addUserMessage(text);

    // Analytics: chat message sent
    _sessionMessagesCount++;
    AnalyticsService().logChatMessageSent(messageLength: text.length, chatType: 'step');
    final requestStartTime = DateTime.now();

    setState(() {
      _isTyping = true;
    });

    try {
      final response = await _gemini.sendMessageWithContext(
        message: text,
        context: _buildSystemContext(),
      );

      // Sprint 4: Індексуємо повідомлення в RAG (fire & forget)
      if (_supabase.isAuthenticated) {
        final userId = _supabase.client.auth.currentUser?.id;
        if (userId != null) {
          _ragService.addMessage(
            text: text,
            userId: userId,
            role: 'user',
            source: 'step_chat',
            goalId: widget.goalId,
            stepNumber: widget.step.stepNumber,
          );
          _ragService.addMessage(
            text: response,
            userId: userId,
            role: 'assistant',
            source: 'step_chat',
            goalId: widget.goalId,
            stepNumber: widget.step.stepNumber,
          );
        }
      }

      // Analytics: chat response received
      final responseTimeMs = DateTime.now().difference(requestStartTime).inMilliseconds;
      AnalyticsService().logChatResponseReceived(
        responseLength: response.length,
        responseTimeMs: responseTimeMs,
        chatType: 'step',
      );

      setState(() {
        _isTyping = false;
      });

      _addBotMessage(response);
    } catch (e) {
      setState(() {
        _isTyping = false;
      });

      _addBotMessage('⚠️ Виникла помилка. Перевір, будь ласка, інтернет-з\'єднання та спробуй ще раз.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                if (!_supabase.isAuthenticated) _buildLocalStorageBanner(),
                _buildStepInfo(),
                Expanded(
                  child: _buildMessagesList(),
                ),
                if (_isTyping) _buildTypingIndicator(),
                _buildInputArea(),
              ],
            ),
    );
  }

  // 🆕 Оновлений AppBar з "Головна / Крок N" по центру
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Головна / Крок ${widget.step.stepNumber}',
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _saveChatToClipboard,
          icon: const Icon(Icons.save_outlined, color: Colors.white),
          tooltip: 'Зберегти чат',
        ),
        IconButton(
          onPressed: _showClearChatDialog,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: 'Очистити чат',
        ),
      ],
    );
  }

  Widget _buildLocalStorageBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Чат зберігається тільки на цьому пристрої.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.orange[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _signInWithGoogle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 16,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.login,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Увійти',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _supabase.signInWithGoogle();
      if (user != null && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ви увійшли! Чат буде синхронізуватися.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadChatHistory();
      }
    } catch (e) {
      debugPrint('❌ Помилка входу: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка входу: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveChatToClipboard() {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Чат порожній'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('💬 Допомога по кроку ${widget.step.stepNumber}: ${widget.step.title}');
    buffer.writeln('=' * 30);
    buffer.writeln();

    for (final msg in _messages) {
      final sender = msg.isUser ? '👤 Ви' : '🤖 AI Коуч';
      final time = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('[$time] $sender:');
      buffer.writeln(msg.text);
      buffer.writeln();
    }

    buffer.writeln('=' * 30);
    buffer.writeln('🚀 career.100steps.ai');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Чат скопійовано в буфер обміну'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('Очистити чат?'),
        content: const Text(
          'Вся історія повідомлень буде видалена.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
    });

    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.client.auth.currentUser?.id;
        if (userId != null) {
          await _supabase.client
              .from('step_chats')
              .delete()
              .eq('user_id', userId)
              .eq('step_id', widget.step.id)
              .eq('goal_id', widget.goalId);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localStorageKey);
      }
    } catch (e) {
      debugPrint('❌ Помилка видалення чату: $e');
    }

    _addInitialMessage();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Чат очищено'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 🆕 Оновлено: показуємо глобальний номер кроку
  Widget _buildStepInfo() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${widget.step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.goalTitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    // T11: Перевіряємо чи є choices в повідомленні бота
    if (!isUser && ChatChoicesParser.hasChoices(message.text)) {
      return _buildMessageWithChoices(message);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildFormattedText(
          message.text,
          isUser ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }

  // T11: Повідомлення з Choice Chips
  Widget _buildMessageWithChoices(_ChatMessage message) {
    final parsed = ChatChoicesParser.parse(message.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текст до choices
        if (parsed.textBefore.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormattedText(parsed.textBefore, AppTheme.textPrimary),
            ),
          ),

        // Choice Chips
        if (parsed.choices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: parsed.choices.map((choice) => _buildChoiceChip(choice)).toList(),
            ),
          ),

        // Текст після choices
        if (parsed.textAfter.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormattedText(parsed.textAfter, AppTheme.textPrimary),
            ),
          ),
      ],
    );
  }

  // T11: Choice Chip
  Widget _buildChoiceChip(String text) {
    return Material(
      color: AppTheme.primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, Color baseColor) {
    final List<InlineSpan> spans = [];
    final RegExp pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|([^*]+)');
    
    for (final match in pattern.allMatches(text)) {
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: baseColor,
            fontSize: 14,
            height: 1.4,
          ),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor,
            fontSize: 14,
            height: 1.4,
          ),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            color: baseColor,
            fontSize: 14,
            height: 1.4,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Roboto',
          color: baseColor,
          fontSize: 14,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Напишіть повідомлення...',
                  hintStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _sendMessage(),
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
