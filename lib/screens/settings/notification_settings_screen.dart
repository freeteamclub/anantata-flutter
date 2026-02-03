import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/telegram_service.dart';
import 'package:anantata/main.dart';

/// Екран налаштувань нагадувань
/// Версія: 2.0.0 — Push/Telegram взаємовиключні (radio buttons)
/// Дата: 03.02.2026

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SupabaseService _supabase = SupabaseService();
  final TelegramService _telegram = TelegramService();

  // Стан налаштувань
  // Канал доставки: 'push', 'telegram', 'disabled'
  String _notificationChannel = 'disabled';
  String _reminderTime = '09:00';
  String _frequency = 'daily';
  bool _motivational = true;
  bool _stepReminders = true;
  bool _achievements = true;
  bool _weeklyStats = false;
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Telegram статус
  TelegramLinkStatus? _telegramStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Завантажуємо налаштування
      final settings = await _supabase.getNotificationSettings();
      if (settings != null && mounted) {
        // Визначаємо канал на основі збережених значень
        final pushEnabled = settings['push_enabled'] ?? false;
        final telegramEnabled = settings['telegram_enabled'] ?? false;
        String channel = 'disabled';
        if (pushEnabled) {
          channel = 'push';
        } else if (telegramEnabled) {
          channel = 'telegram';
        }

        setState(() {
          _notificationChannel = channel;
          _reminderTime = settings['reminder_time'] ?? '09:00';
          _frequency = settings['frequency'] ?? 'daily';
          _motivational = settings['motivational'] ?? true;
          _stepReminders = settings['step_reminders'] ?? true;
          _achievements = settings['achievements'] ?? true;
          _weeklyStats = settings['weekly_stats'] ?? false;
        });
      }
      
      // Завантажуємо статус Telegram
      final telegramStatus = await _telegram.getLinkStatus();
      if (mounted) {
        setState(() => _telegramStatus = telegramStatus);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await _supabase.saveNotificationSettings(
        pushEnabled: _notificationChannel == 'push',
        telegramEnabled: _notificationChannel == 'telegram',
        reminderTime: _reminderTime,
        frequency: _frequency,
        motivational: _motivational,
        stepReminders: _stepReminders,
        achievements: _achievements,
        weeklyStats: _weeklyStats,
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectChannel(String channel) async {
    if (channel == _notificationChannel) return;

    // Якщо вибрано Push — запитуємо дозвіл
    if (channel == 'push') {
      setState(() => _isSaving = true);

      try {
        final success = await FCMService().requestPermissionAndGetToken();

        if (success) {
          setState(() => _notificationChannel = 'push');
          await _saveSettings();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Push-сповіщення увімкнено'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Дозвіл на сповіщення не надано'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error enabling push: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    } else {
      // Telegram або Вимкнено — просто зберігаємо
      setState(() => _notificationChannel = channel);
      await _saveSettings();
    }
  }

  void _showTimePickerDialog() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = newTime);
      await _saveSettings();
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
          'Профіль / Нагадування',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Секція: Канали
                  _buildSectionTitle('Канали'),
                  const SizedBox(height: 12),
                  _buildChannelsSection(),
                  const SizedBox(height: 24),
                  
                  // Секція: Розклад
                  _buildSectionTitle('Розклад'),
                  const SizedBox(height: 12),
                  _buildScheduleSection(),
                  const SizedBox(height: 24),
                  
                  // Секція: Типи повідомлень
                  _buildSectionTitle('Типи повідомлень'),
                  const SizedBox(height: 12),
                  _buildNotificationTypesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildChannelsSection() {
    final isTelegramLinked = _telegramStatus?.isLinked == true;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Отримувати сповіщення через:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Push-сповіщення
          _buildRadioItem(
            icon: Icons.phone_android,
            iconColor: AppTheme.primaryColor,
            title: 'Push-сповіщення',
            subtitle: 'На телефон та браузер',
            value: 'push',
            groupValue: _notificationChannel,
            onChanged: (val) => _selectChannel(val!),
          ),

          const Divider(height: 1, indent: 56),

          // Telegram
          _buildRadioItem(
            icon: Icons.telegram,
            iconColor: const Color(0xFF0088cc),
            title: 'Telegram',
            subtitle: isTelegramLinked ? 'Підключено' : 'Не підключено',
            value: 'telegram',
            groupValue: _notificationChannel,
            onChanged: isTelegramLinked ? (val) => _selectChannel(val!) : null,
            enabled: isTelegramLinked,
          ),

          const Divider(height: 1, indent: 56),

          // Вимкнено
          _buildRadioItem(
            icon: Icons.notifications_off_outlined,
            iconColor: Colors.grey,
            title: 'Вимкнено',
            subtitle: 'Не отримувати сповіщення',
            value: 'disabled',
            groupValue: _notificationChannel,
            onChanged: (val) => _selectChannel(val!),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required void Function(String?)? onChanged,
    bool enabled = true,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: enabled ? () => onChanged?.call(value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (enabled ? iconColor : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: enabled ? iconColor : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppTheme.textPrimary : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? onChanged : null,
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
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
      child: Column(
        children: [
          // Час нагадувань
          _buildTimeSelector(),
          
          const Divider(height: 1, indent: 56),
          
          // Частота
          _buildFrequencySelector(),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _showTimePickerDialog,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Час нагадувань',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Коли надсилати сповіщення',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _reminderTime,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Частота',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Як часто нагадувати',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _frequency,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Щодня')),
                DropdownMenuItem(value: '3days', child: Text('Кожні 3 дні')),
                DropdownMenuItem(value: 'weekly', child: Text('Раз на тиждень')),
                DropdownMenuItem(value: 'disabled', child: Text('Вимкнено')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _frequency = val);
                  await _saveSettings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
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
      child: Column(
        children: [
          _buildCheckboxItem(
            title: 'Мотиваційні',
            subtitle: 'Щоденні надихаючі повідомлення',
            value: _motivational,
            onChanged: (val) async {
              setState(() => _motivational = val ?? true);
              await _saveSettings();
            },
          ),
          
          const Divider(height: 1, indent: 56),
          
          _buildCheckboxItem(
            title: 'Нагадування про кроки',
            subtitle: 'Нагадування про наступний крок',
            value: _stepReminders,
            onChanged: (val) async {
              setState(() => _stepReminders = val ?? true);
              await _saveSettings();
            },
          ),
          
          const Divider(height: 1, indent: 56),
          
          _buildCheckboxItem(
            title: 'Досягнення',
            subtitle: 'Повідомлення про прогрес',
            value: _achievements,
            onChanged: (val) async {
              setState(() => _achievements = val ?? true);
              await _saveSettings();
            },
          ),
          
          const Divider(height: 1, indent: 56),
          
          _buildCheckboxItem(
            title: 'Тижнева статистика',
            subtitle: 'Звіт про прогрес за тиждень',
            value: _weeklyStats,
            onChanged: (val) async {
              setState(() => _weeklyStats = val ?? false);
              await _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
