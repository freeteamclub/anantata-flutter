import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/models/career_plan_model.dart';
import 'package:anantata/services/gemini_service.dart';
import 'package:anantata/services/storage_service.dart';
import 'package:anantata/services/supabase_service.dart';

/// Екран AI чату з кар'єрним коучем
/// Версія: 1.0.0
/// Дата: 14.12.2025

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();

  final List<ChatMessage> _messages = [];
  CareerPlanModel? _plan;
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Завантажити історію чату з Supabase
  Future<void> _loadChatHistory() async {
    // Завантажуємо план
    final plan = await _storage.getCareerPlan();
    setState(() {
      _plan = plan;
    });

    // Якщо авторизований - завантажуємо історію з Supabase
    if (_supabase.isAuthenticated) {
      try {
        final history = await _supabase.getChatHistory(limit: 50);
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
          return; // Не показуємо привітання якщо є історія
        }
      } catch (e) {
        debugPrint('❌ Помилка завантаження історії чату: $e');
      }
    }

    // Привітальне повідомлення (якщо немає історії)
    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage(_getGreetingMessage(), saveToCloud: false);
  }

  /// Зберегти повідомлення в Supabase
  Future<void> _saveToCoud(String text, bool isUser) async {
    if (_supabase.isAuthenticated) {
      try {
        await _supabase.saveChatMessage(
          text: text,
          isUser: isUser,
          // Не передаємо goal_id - він може не існувати в Supabase
          goalId: null,
        );
      } catch (e) {
        debugPrint('❌ Помилка збереження повідомлення: $e');
      }
    }
  }

  String _getGreetingMessage() {
    if (_plan == null) {
      return 'Привіт! 👋 Я ваш AI кар\'єрний коуч.\n\n'
          'Схоже, у вас ще немає плану розвитку. '
          'Пройдіть оцінювання, щоб я міг надавати персоналізовані поради!\n\n'
          'Чим можу допомогти?';
    }

    final progress = _plan!.overallProgress.toStringAsFixed(0);
    final goal = _plan!.goal.title;
    final nextStep = _plan!.nextStep;

    String greeting = 'Привіт! 👋 Я ваш AI кар\'єрний коуч.\n\n';
    greeting += '🎯 Ваша ціль: $goal\n';
    greeting += '📊 Прогрес: $progress%\n';

    if (nextStep != null) {
      greeting += '📌 Наступний крок: ${nextStep.title}\n';
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

    // Зберігаємо в Supabase
    if (saveToCloud) {
      _saveToCoud(text, false);
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

    // Зберігаємо в Supabase
    _saveToCoud(text, true);
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

    // Очищаємо поле вводу
    if (quickAction == null) {
      _messageController.clear();
    }

    // Додаємо повідомлення користувача
    _addUserMessage(text);

    // Показуємо індикатор друку
    setState(() {
      _isTyping = true;
    });

    try {
      String response;

      if (_plan != null) {
        // Відправляємо з контекстом плану
        final context = _gemini.buildAIContext(
          plan: _plan!,
          chatHistory: _messages
              .map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          })
              .toList(),
        );

        response = await _gemini.sendMessageWithContext(
          message: text,
          context: context,
        );
      } else {
        // Простий чат без контексту
        response = await _gemini.chat(text);
      }

      setState(() {
        _isTyping = false;
      });

      _addBotMessage(response);
    } catch (e) {
      setState(() {
        _isTyping = false;
      });

      _addBotMessage(
        'Вибачте, виникла помилка. Спробуйте ще раз пізніше. 🙏',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Повідомлення
          Expanded(
            child: _buildMessagesList(),
          ),

          // Швидкі дії
          if (_messages.length <= 2) _buildQuickActions(),

          // Індикатор друку
          if (_isTyping) _buildTypingIndicator(),

          // Поле вводу
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Коуч',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Онлайн',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _clearChat,
          icon: const Icon(Icons.refresh, color: Colors.white),
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
            Text(
              message.text,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 15,
                color: isUser ? Colors.white : AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 11,
                color: isUser ? Colors.white60 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      QuickAction(icon: Icons.arrow_forward, text: 'Що робити далі?'),
      QuickAction(icon: Icons.help_outline, text: 'Поясни поточний крок'),
      QuickAction(icon: Icons.emoji_emotions, text: 'Мотивація'),
      QuickAction(icon: Icons.lightbulb_outline, text: 'Поради'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Швидкі дії',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickActions.map((action) {
              return ActionChip(
                avatar: Icon(
                  action.icon,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                label: Text(
                  action.text,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: () => _sendMessage(action.text),
              );
            }).toList(),
          ),
        ],
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
                fontFamily: 'NunitoSans',
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
          // Текстове поле
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Введіть повідомлення...',
                hintStyle: TextStyle(
                  fontFamily: 'NunitoSans',
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

          // Кнопка відправки
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
          style: TextStyle(fontFamily: 'Bitter'),
        ),
        content: const Text(
          'Всі повідомлення будуть видалені.',
          style: TextStyle(fontFamily: 'NunitoSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              _loadChatHistory();
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