import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/telegram_service.dart';

/// Екран прив'язки соцмереж
/// Версія: 2.0.0
/// Дата: 07.01.2026

class SocialNetworksScreen extends StatefulWidget {
  const SocialNetworksScreen({super.key});

  @override
  State<SocialNetworksScreen> createState() => _SocialNetworksScreenState();
}

class _SocialNetworksScreenState extends State<SocialNetworksScreen> {
  final SupabaseService _supabase = SupabaseService();
  final TelegramService _telegram = TelegramService();

  bool _isLoading = true;
  bool _isTelegramLoading = false;
  bool _isSaving = false;
  TelegramLinkStatus? _telegramStatus;
  String? _pendingLinkCode;

  // Контролери для полів соцмереж
  final TextEditingController _link1Controller = TextEditingController();
  final TextEditingController _link2Controller = TextEditingController();
  final TextEditingController _link3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _link1Controller.dispose();
    _link2Controller.dispose();
    _link3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Завантаження Telegram статусу
      if (_supabase.isAuthenticated) {
        final status = await _telegram.getLinkStatus();
        if (mounted) {
          setState(() {
            _telegramStatus = status;
            if (status.isPending) {
              _pendingLinkCode = status.linkCode;
            }
          });
        }

        // Завантаження соцмереж з Supabase
        await _loadSocialLinksFromSupabase();
      }

      // Завантаження з SharedPreferences (локальний кеш)
      await _loadSocialLinksFromLocal();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSocialLinksFromSupabase() async {
    try {
      final userId = _supabase.userId;
      if (userId == null) return;

      final response = await _supabase.client
          .from('user_social_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _link1Controller.text = response['social_link_1'] ?? '';
          _link2Controller.text = response['social_link_2'] ?? '';
          _link3Controller.text = response['social_link_3'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading social links from Supabase: $e');
    }
  }

  Future<void> _loadSocialLinksFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Якщо поля порожні, завантажити з локального сховища
      if (_link1Controller.text.isEmpty) {
        _link1Controller.text = prefs.getString('social_link_1') ?? '';
      }
      if (_link2Controller.text.isEmpty) {
        _link2Controller.text = prefs.getString('social_link_2') ?? '';
      }
      if (_link3Controller.text.isEmpty) {
        _link3Controller.text = prefs.getString('social_link_3') ?? '';
      }
    } catch (e) {
      debugPrint('Error loading social links from local: $e');
    }
  }

  Future<void> _saveSocialLinks() async {
    setState(() => _isSaving = true);

    try {
      final link1 = _link1Controller.text.trim();
      final link2 = _link2Controller.text.trim();
      final link3 = _link3Controller.text.trim();

      // Зберегти локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('social_link_1', link1);
      await prefs.setString('social_link_2', link2);
      await prefs.setString('social_link_3', link3);

      // Зберегти в Supabase (якщо авторизований)
      if (_supabase.isAuthenticated) {
        final userId = _supabase.userId;
        if (userId != null) {
          await _supabase.client.from('user_social_profiles').upsert({
            'user_id': userId,
            'social_link_1': link1.isEmpty ? null : link1,
            'social_link_2': link2.isEmpty ? null : link2,
            'social_link_3': link3.isEmpty ? null : link3,
          }, onConflict: 'user_id');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Збережено'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving social links: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка збереження: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _generateTelegramCode() async {
    setState(() => _isTelegramLoading = true);

    try {
      final result = await _telegram.generateLinkCode();

      if (result.success && mounted) {
        setState(() {
          _pendingLinkCode = result.linkCode;
          _telegramStatus = TelegramLinkStatus.pendingLink(
            linkCode: result.linkCode!,
            expiresAt: result.expiresAt!,
          );
        });

        _showTelegramLinkDialog(result.linkCode!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTelegramLoading = false);
      }
    }
  }

  void _showTelegramLinkDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Баг #7: Відцентрований заголовок
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0088cc).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.telegram,
                  color: Color(0xFF0088cc),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Прив\'язати Telegram',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Баг #7: Відцентрований контент з правильними шрифтами
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Відкрий бота та надішли цей код:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Баг #7: Відцентрований блок з кодом
            Center(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Код скопійовано!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          letterSpacing: 4,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.copy, color: Colors.grey[600], size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Код дійсний 15 хвилин',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Закрити',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
          // Баг #6: Спочатку відкриваємо URL, потім закриваємо діалог
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse(_telegram.getBotLinkWithCode(code));
              // Баг #6: Спочатку відкриваємо URL
              final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
              // Потім закриваємо діалог
              if (context.mounted) {
                Navigator.pop(context);
              }
              // Якщо не вдалося відкрити - показуємо помилку
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❗ Не вдалося відкрити Telegram. Скопіюйте код та відкрийте бота вручну.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.telegram, size: 20),
            label: const Text(
              'Відкрити бота',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088cc),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkTelegram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Відв\'язати Telegram?'),
        content: const Text('Ви більше не будете отримувати сповіщення в Telegram.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Відв\'язати'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isTelegramLoading = true);

      final success = await _telegram.unlinkTelegram();

      if (mounted) {
        setState(() => _isTelegramLoading = false);

        if (success) {
          setState(() {
            _telegramStatus = TelegramLinkStatus.notLinked();
            _pendingLinkCode = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Telegram відв\'язано')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Помилка відв\'язки'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Профіль / Соцмережі',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Пояснення
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Прив\'яжіть соцмережі для отримання сповіщень та синхронізації',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Telegram
                  _buildTelegramItem(),
                  const SizedBox(height: 24),

                  // Розділювач
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 24),

                  // Секція соціальних мереж
                  Row(
                    children: [
                      Icon(Icons.share, color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Ваші соціальні мережі',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Вкажіть профілі в соціальних мережах (X, Facebook, Instagram, LinkedIn, TikTok), де ви найбільше проводите час',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Поле 1
                  _buildLinkField(
                    controller: _link1Controller,
                    hint: 'Посилання 1',
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 12),

                  // Поле 2
                  _buildLinkField(
                    controller: _link2Controller,
                    hint: 'Посилання 2',
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 12),

                  // Поле 3
                  _buildLinkField(
                    controller: _link3Controller,
                    hint: 'Посилання 3',
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 24),

                  // Кнопка Зберегти
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSocialLinks,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 20),
                      label: Text(
                        _isSaving ? 'Збереження...' : 'Зберегти',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLinkField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
        ),
      ),
    );
  }

  String _getTelegramSubtitle() {
    if (!_supabase.isAuthenticated) return 'Увійдіть для підключення';
    if (_telegramStatus?.isLinked == true) {
      final username = _telegramStatus?.telegramUsername;
      return username != null ? '@$username' : 'Підключено';
    }
    if (_telegramStatus?.isPending == true) return 'Очікує прив\'язки';
    return 'Не підключено';
  }

  Widget _buildTelegramItem() {
    final isConnected = _telegramStatus?.isLinked == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.telegram, color: Color(0xFF0088cc), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telegram',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTelegramSubtitle(),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: isConnected ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_isTelegramLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isConnected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Підключено',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _unlinkTelegram,
                  child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _supabase.isAuthenticated ? _generateTelegramCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Підключити',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
