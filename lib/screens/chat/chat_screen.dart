import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/gemini_service.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/analytics_service.dart';
import 'package:anantata/services/profile_summary_service.dart';  // T7
import 'package:anantata/screens/chat/chat_choices_parser.dart';  // T11

/// Екран AI чату з кар'єрним коучем
/// Версія: 2.6.0 - Баг #7: генерація продовжується при виході з екрана
/// Дата: 03.02.2026
///
/// Виправлено:
/// - Баг #7 - Генерація AI продовжується при виході з екрана (pending request)
/// - P1 #8 - Збереження історії чату для гостя (локально)
/// - P2 #40 - Іконка очищення чату → смітничок (delete_outline)
/// - P3 #30 - "Швидкі дії" вирівняно з повідомленнями чату
/// - Баг #3 - Офлайн помилка до оцінювання тепер показує user-friendly текст
/// - Баг #5 - Кнопка "Назад" перевіряє canPop, не показує чорний екран
/// - Баг #4 - Кнопка "Назад" завжди показується
/// - Баг #9 - Можливість виділити та скопіювати текст
/// - Баг #12b - Коректна помилка при офлайн режимі
/// - Допрацювання #14 - Форматування відповідей AI (жирний, курсив, списки)

/// Глобальний стан для pending запиту (зберігається при виході з екрана)
class _PendingChatRequest {
  static bool isProcessing = false;
  static String? userMessage;
  static String? response;
  static String? error;
  static String? chatKey;

  static void clear() {
    isProcessing = false;
    userMessage = null;
    response = null;
    error = null;
    chatKey = null;
  }
}

class ChatScreen extends StatefulWidget {
  final String? goalId;
  final String? goalTitle;
  final bool embedded; // 🆕 Якщо true - не показувати AppBar (вбудовано в HomeScreen)

  const ChatScreen({
    super.key,
    this.goalId,
    this.goalTitle,
    this.embedded = false,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();

  final List<ChatMessage> _messages = [];
  CareerPlanModel? _plan;
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isQuickActionsExpanded = true;

  // T7: Profile Summary для персоналізації
  String? _profileSummary;
  final ProfileSummaryService _profileSummaryService = ProfileSummaryService();

  // Analytics: session tracking
  DateTime? _sessionStartTime;
  int _sessionMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _checkPendingRequest();

    // Analytics: chat session started
    _sessionStartTime = DateTime.now();
    AnalyticsService().logChatSessionStarted(chatType: 'general');
  }

  /// Перевіряємо чи є незавершений запит (Баг #7)
  void _checkPendingRequest() {
    final chatKey = widget.goalId ?? 'general_chat';

    // Якщо є відповідь для цього чату — додаємо її
    if (_PendingChatRequest.chatKey == chatKey && _PendingChatRequest.response != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addBotMessage(_PendingChatRequest.response!);
          _PendingChatRequest.clear();
        }
      });
    }
    // Якщо є помилка — показуємо її
    else if (_PendingChatRequest.chatKey == chatKey && _PendingChatRequest.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addBotMessage(_PendingChatRequest.error!);
          _PendingChatRequest.clear();
        }
      });
    }
    // Якщо запит ще обробляється — показуємо typing
    else if (_PendingChatRequest.chatKey == chatKey && _PendingChatRequest.isProcessing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isTyping = true);
        }
      });
    }
  }

  @override
  void dispose() {
    // Analytics: chat session ended
    if (_sessionStartTime != null && _sessionMessagesCount > 0) {
      final durationSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      AnalyticsService().logChatSessionEnded(
        chatType: 'general',
        messagesCount: _sessionMessagesCount,
        durationSeconds: durationSeconds,
      );
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // v2.1: Публічний метод - отримати чат як текст
  String getChatAsText() {
    if (_messages.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('💬 Чат з AI Коучем 100StepsCareer');
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
    
    return buffer.toString();
  }

  // v2.5: Публічний метод - очистити чат БЕЗ діалогу (для зовнішнього виклику)
  // Баг #4: Виправлено подвійний попап - тепер викликає _performClearChat() напряму
  void clearChatMessages() {
    _performClearChat();
  }

  /// Баг #4: Реальна очистка чату БЕЗ діалогу підтвердження
  Future<void> _performClearChat() async {
    final chatKey = widget.goalId ?? 'general_chat';

    if (_supabase.isAuthenticated) {
      try {
        var query = _supabase.client
            .from('chat_messages')
            .delete()
            .eq('user_id', _supabase.userId!);
        if (widget.goalId != null) {
          query = query.eq('goal_id', widget.goalId!);
        } else {
          query = query.isFilter('goal_id', null);
        }
        await query;
        debugPrint('✅ Чат очищено в Supabase');
      } catch (e) {
        debugPrint('❌ Помилка очищення в Supabase: $e');
      }
    } else {
      try {
        await _storage.clearLocalChatHistory(chatKey);
        debugPrint('✅ Чат очищено локально (гість)');
      } catch (e) {
        debugPrint('❌ Помилка локального очищення: $e');
      }
    }

    setState(() {
      _messages.clear();
    });
    _addBotMessage(_getGreetingMessage(), saveToCloud: false);
  }

  // Баг #5: Безпечний вихід з екрану
  void _safeNavigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Якщо немає куди повертатись - нічого не робимо
      debugPrint('⚠️ ChatScreen: Немає куди повертатись (canPop = false)');
    }
  }

  Future<void> _loadChatHistory() async {
    CareerPlanModel? plan;
    if (widget.goalId != null) {
      plan = await _storage.getPlanForGoal(widget.goalId!);
    }
    plan ??= await _storage.getCareerPlan();

    // T7: Завантажуємо profile_summary для персоналізації
    String? summary;
    try {
      summary = await _profileSummaryService.getSummary();
      debugPrint('📝 Profile summary завантажено: ${summary != null ? "${summary.length} символів" : "немає"}');
    } catch (e) {
      debugPrint('⚠️ Помилка завантаження profile_summary: $e');
    }

    setState(() {
      _plan = plan;
      _profileSummary = summary;
    });

    // Визначаємо ключ для завантаження
    final chatKey = widget.goalId ?? 'general_chat';

    if (_supabase.isAuthenticated) {
      // Авторизований - завантажуємо з Supabase
      try {
        final history = await _supabase.getChatHistory(
          limit: 50,
          goalId: widget.goalId,
        );
        if (history.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(history.map((msg) => ChatMessage(
              text: msg['text'] as String,
              isUser: msg['is_user'] as bool,
              timestamp: DateTime.parse(msg['created_at'] as String),
            )));
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        debugPrint('❌ Помилка завантаження історії з Supabase: $e');
      }
    } else {
      // 🆕 Баг #8: Гість - завантажуємо локально
      try {
        final localHistory = await _storage.getLocalChatHistory(chatKey);
        if (localHistory.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(localHistory.map((msg) => ChatMessage(
              text: msg['text'] as String,
              isUser: msg['is_user'] as bool,
              timestamp: DateTime.parse(msg['created_at'] as String),
            )));
          });
          _scrollToBottom();
          debugPrint('✅ Завантажено ${localHistory.length} повідомлень локально (гість)');
          return;
        }
      } catch (e) {
        debugPrint('❌ Помилка локального завантаження: $e');
      }
    }

    // Якщо історії немає - показуємо привітання
    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage(_getGreetingMessage(), saveToCloud: false);
  }

  /// 🆕 Баг #8: Зберегти повідомлення (в хмару або локально)
  Future<void> _saveMessage(String text, bool isUser) async {
    // Визначаємо ключ для зберігання
    final chatKey = widget.goalId ?? 'general_chat';

    if (_supabase.isAuthenticated) {
      // Авторизований - зберігаємо в Supabase
      try {
        await _supabase.saveChatMessage(
          text: text,
          isUser: isUser,
          goalId: widget.goalId,
        );
      } catch (e) {
        debugPrint('❌ Помилка збереження в Supabase: $e');
      }
    } else {
      // 🆕 Баг #8: Гість - зберігаємо локально
      try {
        await _storage.saveLocalChatMessage(
          goalId: chatKey,
          text: text,
          isUser: isUser,
        );
        debugPrint('💾 Повідомлення збережено локально (гість)');
      } catch (e) {
        debugPrint('❌ Помилка локального збереження: $e');
      }
    }
  }

  String _getGreetingMessage() {
    if (widget.goalId != null && _plan != null) {
      final progress = _plan!.overallProgress.toStringAsFixed(0);
      final goal = _plan!.goal.title;
      final nextStep = _plan!.nextStep;

      String greeting = 'Привіт! 👋 Давайте обговоримо вашу ціль.\n\n';
      greeting += '🎯 **Ціль:** $goal\n';
      greeting += '📊 **Прогрес:** $progress%\n';

      if (nextStep != null) {
        greeting += '📌 **Наступний крок:** ${nextStep.title}\n';
      }

      greeting += '\nЗапитуйте будь-що!';
      return greeting;
    }

    if (_plan == null) {
      return 'Привіт! 👋 Я ваш **AI кар\'єрний коуч**.\n\n'
          'Схоже, у вас ще немає плану розвитку. '
          'Пройдіть оцінювання, щоб я міг надавати *персоналізовані* поради!\n\n'
          'Чим можу допомогти?';
    }

    final progress = _plan!.overallProgress.toStringAsFixed(0);
    final goal = _plan!.goal.title;
    final nextStep = _plan!.nextStep;

    String greeting = 'Привіт! 👋 Я ваш **AI кар\'єрний коуч**.\n\n';
    greeting += '🎯 **Ваша ціль:** $goal\n';
    greeting += '📊 **Прогрес:** $progress%\n';

    if (nextStep != null) {
      greeting += '📌 **Наступний крок:** ${nextStep.title}\n';
    }

    greeting += '\nЧим можу допомогти сьогодні?';

    return greeting;
  }

  void _addBotMessage(String text, {bool saveToCloud = true}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    if (saveToCloud) {
      _saveMessage(text, false);
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    _saveMessage(text, true);
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

  // Баг #3: Розширена перевірка мережевих помилок
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Список патернів мережевих помилок
    final networkPatterns = [
      'socketexception',
      'clientexception',
      'failed host lookup',
      'no address associated',
      'network is unreachable',
      'connection refused',
      'connection timed out',
      'no internet',
      'errno = 7',           // Android: No address associated with hostname
      'errno = 101',         // Network is unreachable
      'errno = 110',         // Connection timed out
      'errno = 111',         // Connection refused
      'handshakeexception',  // SSL/TLS помилки
      'certificateexception',
      'os error',
      'failed to connect',
      'unable to resolve host',
      'unknownhostexception',
      'econnrefused',
      'etimedout',
      'enetunreach',
      'ehostunreach',
      'connection reset',
      'broken pipe',
      'connection closed',
      'generativelanguage.googleapis.com', // Специфічна для Gemini
    ];

    for (final pattern in networkPatterns) {
      if (errorString.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  // Баг #3: Отримати user-friendly повідомлення про помилку
  String _getErrorMessage(dynamic error) {
    if (_isNetworkError(error)) {
      return '📵 **Немає з\'єднання з інтернетом.**\n\n'
          'Перевірте підключення до мережі та спробуйте ще раз.';
    }

    // Перевіряємо специфічні помилки API
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('quota') || errorString.contains('rate limit')) {
      return '⏳ **Перевищено ліміт запитів.**\n\n'
          'Зачекайте хвилину та спробуйте ще раз.';
    }

    if (errorString.contains('invalid') || errorString.contains('unauthorized')) {
      return '🔑 **Помилка авторизації.**\n\n'
          'Спробуйте перезапустити додаток.';
    }

    // Загальна помилка
    return '⚠️ Виникла помилка. Спробуйте ще раз. 🙏';
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
    AnalyticsService().logChatMessageSent(messageLength: text.length, chatType: 'general');
    final requestStartTime = DateTime.now();

    setState(() {
      _isTyping = true;
    });

    // Баг #7: Зберігаємо стан pending запиту
    final chatKey = widget.goalId ?? 'general_chat';
    _PendingChatRequest.isProcessing = true;
    _PendingChatRequest.userMessage = text;
    _PendingChatRequest.chatKey = chatKey;
    _PendingChatRequest.response = null;
    _PendingChatRequest.error = null;

    // Баг #3: Обгортаємо весь блок у try-catch для надійності
    try {
      String response;

      // Баг #3: Окремий try-catch для API запиту
      try {
        if (_plan != null) {
          // T7: Передаємо profile_summary для персоналізації
          final context = _gemini.buildAIContext(
            plan: _plan!,
            chatHistory: _messages
                .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
                .toList(),
            profileSummary: _profileSummary,
          );

          response = await _gemini.sendMessageWithContext(
            message: text,
            context: context,
          );
        } else {
          // Баг #3: До оцінювання - використовуємо простий chat
          response = await _gemini.chat(text);
        }
      } catch (apiError) {
        // Баг #3: Логуємо для дебагу
        debugPrint('❌ API помилка: $apiError');

        // Баг #7: Зберігаємо помилку для відображення при поверненні
        _PendingChatRequest.isProcessing = false;
        _PendingChatRequest.error = _getErrorMessage(apiError);

        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          _addBotMessage(_PendingChatRequest.error!);
          _PendingChatRequest.clear();
        }
        return;
      }

      // Баг #7: Зберігаємо відповідь
      _PendingChatRequest.isProcessing = false;
      _PendingChatRequest.response = response;

      // Analytics: chat response received
      final responseTimeMs = DateTime.now().difference(requestStartTime).inMilliseconds;
      AnalyticsService().logChatResponseReceived(
        responseLength: response.length,
        responseTimeMs: responseTimeMs,
        chatType: 'general',
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addBotMessage(response);
        _PendingChatRequest.clear();
      }
      // Якщо екран закрито — відповідь залишається в _PendingChatRequest
      // і буде показана при поверненні в чат

    } catch (e) {
      // Баг #3: Загальний catch для будь-яких інших помилок
      debugPrint('❌ Загальна помилка в _sendMessage: $e');

      _PendingChatRequest.isProcessing = false;
      _PendingChatRequest.error = _getErrorMessage(e);

      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addBotMessage(_PendingChatRequest.error!);
        _PendingChatRequest.clear();
      }
    }
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Текст скопійовано'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.embedded ? null : _buildAppBar(), // 🆕 Не показувати AppBar якщо embedded
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final hasGoalContext = widget.goalId != null;

    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      // Баг #5: Використовуємо безпечний метод виходу
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _safeNavigateBack,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Коуч',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasGoalContext ? 'Обговорення цілі' : 'Онлайн',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // P2 #40: Змінено іконку на смітничок
        IconButton(
          onPressed: _clearChat,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: 'Очистити чат',
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    // T11: Перевіряємо чи є choices в повідомленні бота
    if (!isUser && ChatChoicesParser.hasChoices(message.text)) {
      return _buildMessageWithChoices(message);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: EdgeInsets.only(
            bottom: 12,
            left: isUser ? 40 : 0,
            right: isUser ? 0 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Допрацювання #14: Форматований текст для AI, простий для користувача
              isUser
                  ? SelectableText(
                message.text,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.4,
                ),
              )
                  : _buildFormattedText(message.text),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: isUser ? Colors.white60 : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // T11: Повідомлення з Choice Chips
  Widget _buildMessageWithChoices(ChatMessage message) {
    final parsed = ChatChoicesParser.parse(message.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текст до choices
        if (parsed.textBefore.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                margin: const EdgeInsets.only(bottom: 8, right: 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedText(parsed.textBefore),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Choice Chips
        if (parsed.choices.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(right: 40),
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
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              margin: const EdgeInsets.only(bottom: 12, right: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormattedText(parsed.textAfter),
            ),
          ),
      ],
    );
  }

  // T11: Choice Chip
  Widget _buildChoiceChip(String text) {
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
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

  // Допрацювання #14: Побудова форматованого тексту
  Widget _buildFormattedText(String text) {
    final spans = FormattedTextParser.parse(text, AppTheme.textPrimary);

    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          color: AppTheme.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryColor),
              title: const Text('Копіювати текст'),
              onTap: () {
                Navigator.pop(context);
                _copyMessageText(message.text);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: Colors.grey[600]),
              title: const Text('Скасувати'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // P3 #30: Вирівняно з повідомленнями чату (padding 16)
  Widget _buildQuickActions() {
    final quickActionsRow1 = [
      QuickAction(icon: Icons.arrow_forward, text: 'Що робити далі?'),
      QuickAction(icon: Icons.help_outline, text: 'Поясни цей крок'),
    ];

    final quickActionsRow2 = [
      QuickAction(icon: Icons.emoji_emotions, text: 'Мотивація'),
      QuickAction(icon: Icons.lightbulb_outline, text: 'Поради'),
    ];

    return Container(
      // P3 #30: Такий же padding як у _buildMessagesList (16)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P3 #30: Заголовок вирівняно по лівому краю (без додаткового відступу)
          GestureDetector(
            onTap: () {
              setState(() {
                _isQuickActionsExpanded = !_isQuickActionsExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  'Швидкі дії',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isQuickActionsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const Spacer(),
                Text(
                  _isQuickActionsExpanded ? 'Згорнути' : 'Розгорнути',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isQuickActionsExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const SizedBox(height: 8),
                // P3 #30: Кнопки вирівняні по лівому краю
                Row(
                  children: quickActionsRow1.map((action) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == quickActionsRow1.first ? 4 : 0,
                          left: action == quickActionsRow1.last ? 4 : 0,
                        ),
                        child: _buildQuickActionChip(action),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: quickActionsRow2.map((action) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == quickActionsRow2.first ? 4 : 0,
                          left: action == quickActionsRow2.last ? 4 : 0,
                        ),
                        child: _buildQuickActionChip(action),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            secondChild: const SizedBox(height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(QuickAction action) {
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _sendMessage(action.text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  action.text,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
            const SizedBox(width: 8),
            Text(
              'AI друкує...',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.3 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Введіть повідомлення...',
                hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _isTyping ? null : () => _sendMessage(),
              icon: Icon(
                Icons.send_rounded,
                color: _isTyping ? Colors.white60 : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Очистити чат?',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        content: const Text(
          'Всі повідомлення будуть видалені.',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ═══════════════════════════════════════════════════════════════
// МОДЕЛІ
// ═══════════════════════════════════════════════════════════════

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class QuickAction {
  final IconData icon;
  final String text;

  QuickAction({required this.icon, required this.text});
}

// ═══════════════════════════════════════════════════════════════
// Допрацювання #14: ПАРСЕР ФОРМАТОВАНОГО ТЕКСТУ
// ═══════════════════════════════════════════════════════════════

class FormattedTextParser {
  /// Парсить текст з Markdown-подібним форматуванням
  /// Підтримує:
  /// - **жирний текст**
  /// - *курсив*
  /// - Списки (- або • на початку рядка)
  /// - Нумеровані списки (1. 2. 3.)
  /// - Емодзі (залишаються як є)
  static List<TextSpan> parse(String text, Color baseColor) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // Додаємо новий рядок перед кожним рядком крім першого
      if (lineIndex > 0) {
        spans.add(const TextSpan(text: '\n'));
      }

      // Перевіряємо чи це елемент списку
      final listMatch = RegExp(r'^(\s*)([-•●]\s+|\d+\.\s+)(.*)$').firstMatch(line);

      if (listMatch != null) {
        // Це елемент списку
        final indent = listMatch.group(1) ?? '';
        final bullet = listMatch.group(2) ?? '';
        final content = listMatch.group(3) ?? '';

        // Додаємо відступ
        if (indent.isNotEmpty) {
          spans.add(TextSpan(text: indent));
        }

        // Додаємо маркер списку з кольором
        spans.add(TextSpan(
          text: bullet,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ));

        // Парсимо вміст елемента списку
        spans.addAll(_parseInlineFormatting(content, baseColor));
      } else {
        // Звичайний рядок - парсимо inline форматування
        spans.addAll(_parseInlineFormatting(line, baseColor));
      }
    }

    return spans;
  }

  /// Парсить inline форматування (жирний, курсив)
  static List<TextSpan> _parseInlineFormatting(String text, Color baseColor) {
    final List<TextSpan> spans = [];

    // Regex для пошуку форматування
    // **жирний** або *курсив*
    final regex = RegExp(r'(\*\*(.+?)\*\*)|(\*(.+?)\*)');

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Додаємо текст до match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }

      // Визначаємо тип форматування
      if (match.group(2) != null) {
        // **жирний**
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: baseColor,
          ),
        ));
      } else if (match.group(4) != null) {
        // *курсив*
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Додаємо залишок тексту
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    // Якщо spans пустий, додаємо весь текст
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(color: baseColor),
      ));
    }

    return spans;
  }
}
