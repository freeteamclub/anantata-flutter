import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/telegram_service.dart';

/// Екран прив'язки соцмереж
/// Версія: 1.0.0
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
  TelegramLinkStatus? _telegramStatus;
  String? _pendingLinkCode;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _isLoading = true);

    try {
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
      }
    } catch (e) {
      debugPrint('Error loading statuses: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0088cc).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.telegram,
                color: Color(0xFF0088cc),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Прив\'язати Telegram'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Відкрий бота та надішли цей код:',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            GestureDetector(
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
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
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
            const SizedBox(height: 12),
            Text(
              'Код дійсний 15 хвилин',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Або просто натисни кнопку нижче:',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрити'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse(_telegram.getBotLinkWithCode(code));
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.telegram, size: 20),
            label: const Text('Відкрити бота'),
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

  void _showComingSoonDialog(String network) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.construction, color: Colors.orange[700], size: 48),
        title: Text('$network'),
        content: const Text(
          'Прив\'язка цієї соцмережі буде доступна в наступних версіях додатку.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );
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
            fontFamily: 'Bitter',
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
                              fontFamily: 'NunitoSans',
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
                  _buildSocialItem(
                    icon: Icons.telegram,
                    title: 'Telegram',
                    subtitle: _getTelegramSubtitle(),
                    isConnected: _telegramStatus?.isLinked == true,
                    isLoading: _isTelegramLoading,
                    onConnect: _supabase.isAuthenticated ? _generateTelegramCode : null,
                    onDisconnect: _telegramStatus?.isLinked == true ? _unlinkTelegram : null,
                  ),
                  const SizedBox(height: 12),

                  // Instagram
                  _buildSocialItem(
                    icon: Icons.camera_alt,
                    title: 'Instagram',
                    subtitle: 'Скоро буде доступно',
                    isConnected: false,
                    isLoading: false,
                    onConnect: () => _showComingSoonDialog('Instagram'),
                    isComingSoon: true,
                  ),
                  const SizedBox(height: 12),

                  // LinkedIn
                  _buildSocialItem(
                    icon: Icons.work,
                    title: 'LinkedIn',
                    subtitle: 'Скоро буде доступно',
                    isConnected: false,
                    isLoading: false,
                    onConnect: () => _showComingSoonDialog('LinkedIn'),
                    isComingSoon: true,
                  ),
                  const SizedBox(height: 12),

                  // Facebook
                  _buildSocialItem(
                    icon: Icons.facebook,
                    title: 'Facebook',
                    subtitle: 'Скоро буде доступно',
                    isConnected: false,
                    isLoading: false,
                    onConnect: () => _showComingSoonDialog('Facebook'),
                    isComingSoon: true,
                  ),
                ],
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

  Widget _buildSocialItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
    required bool isLoading,
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    bool isComingSoon = false,
  }) {
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
            child: Icon(icon, color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: isConnected ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
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
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDisconnect != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDisconnect,
                    child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                  ),
                ],
              ],
            )
          else if (isComingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Скоро',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Підключити',
                style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
