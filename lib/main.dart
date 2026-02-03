import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, FlutterError;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:anantata/firebase_options.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/services/supabase_service.dart';
import 'package:anantata/services/sync_service.dart';
import 'package:anantata/services/analytics_service.dart';
import 'package:anantata/screens/splash/splash_screen.dart';
import 'package:anantata/screens/home/home_screen.dart';
import 'package:anantata/screens/auth/auth_screen.dart';

/// Anantata Career Coach
/// Версія: 2.5.0 - Виправлено автоматичний запит сповіщень
/// Дата: 06.01.2026
///
/// Що змінено:
/// - FCMService.initialize() більше НЕ запитує дозвіл автоматично
/// - Дозвіл запитується тільки коли користувач вмикає Push в налаштуваннях
/// - Додано метод requestPermissionAndGetToken() для явного запиту
///
/// AI-powered career development application

/// Background message handler (має бути top-level функція)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message: ${message.messageId}');
}

void main() async {
  // Баг #11: Глобальний error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter Error: ${details.exceptionAsString()}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Баг #11: Безпечна ініціалізація з try-catch
  try {
    // Завантаження змінних середовища
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Помилка завантаження .env: $e');
    // Продовжуємо без .env (використовуються значення за замовчуванням)
  }

  // Ініціалізація Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase ініціалізовано');

    // Налаштування FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  } catch (e) {
    debugPrint('⚠️ Помилка ініціалізації Firebase: $e');
  }

  // Ініціалізація Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('⚠️ Помилка ініціалізації Supabase: $e');
    // Продовжуємо в офлайн режимі
  }

  // Ініціалізація Analytics (Amplitude)
  try {
    await AnalyticsService().initialize();
    debugPrint('✅ Analytics ініціалізовано');
  } catch (e) {
    debugPrint('⚠️ Помилка ініціалізації Analytics: $e');
  }

  runApp(const AnantataApp());
}

/// Клас для роботи з FCM
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  String? get currentToken => _currentToken;

  /// Ініціалізація FCM БЕЗ запиту дозволу
  /// Тільки налаштовує слухачі для оновлення токена
  Future<void> initialize() async {
    try {
      // 🆕 НЕ запитуємо дозвіл автоматично!
      // Просто перевіряємо чи вже є дозвіл
      final settings = await _messaging.getNotificationSettings();
      
      debugPrint('🔔 Current notification status: ${settings.authorizationStatus}');

      // Якщо дозвіл вже був наданий раніше — отримуємо токен
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _currentToken = await _messaging.getToken();
        debugPrint('🔑 FCM Token (existing permission): $_currentToken');

        // Зберігаємо токен в Supabase
        await _saveTokenToSupabase();
      }

      // Слухаємо оновлення токена (працює навіть без дозволу)
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM Token оновлено: $newToken');
        _currentToken = newToken;
        await _saveTokenToSupabase();
      });
      
    } catch (e) {
      debugPrint('⚠️ Помилка ініціалізації FCM: $e');
    }
  }

  /// 🆕 Запит дозволу та отримання токена
  /// Викликається тільки коли користувач явно вмикає Push в налаштуваннях
  Future<bool> requestPermissionAndGetToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Notification permission requested: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Отримуємо FCM токен
        _currentToken = await _messaging.getToken();
        debugPrint('🔑 FCM Token: $_currentToken');

        // Зберігаємо токен в Supabase
        await _saveTokenToSupabase();
        
        return true; // Дозвіл надано
      }
      
      return false; // Дозвіл відхилено
    } catch (e) {
      debugPrint('⚠️ Помилка запиту дозволу FCM: $e');
      return false;
    }
  }

  /// Зберегти токен в Supabase
  Future<void> _saveTokenToSupabase() async {
    if (_currentToken == null) return;

    final supabase = SupabaseService();
    if (!supabase.isAuthenticated) {
      debugPrint('⚠️ Користувач не авторизований, токен не збережено');
      return;
    }

    final deviceType = _getDeviceType();
    final deviceName = _getDeviceName();

    await supabase.saveFcmToken(
      token: _currentToken!,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }

  /// Визначити тип пристрою
  String _getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Отримати назву пристрою
  String _getDeviceName() {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'Unknown Device';
  }

  /// Видалити токен при виході
  Future<void> deleteToken() async {
    if (_currentToken != null) {
      final supabase = SupabaseService();
      await supabase.deactivateFcmToken(_currentToken!);
      await _messaging.deleteToken();
      _currentToken = null;
      debugPrint('✅ FCM токен видалено');
    }
  }
}

class AnantataApp extends StatefulWidget {
  const AnantataApp({super.key});

  @override
  State<AnantataApp> createState() => _AnantataAppState();
}

class _AnantataAppState extends State<AnantataApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
  }

  /// Налаштування слухачів FCM
  void _setupFCMListeners() {
    // Повідомлення коли додаток відкритий (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message: ${message.notification?.title}');

      // Показуємо локальне сповіщення або snackbar
      if (message.notification != null) {
        _showInAppNotification(message);
      }
    });

    // Коли користувач натискає на сповіщення
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Message opened: ${message.data}');
      // TODO: Навігація до відповідного екрану
    });
  }

  /// Показати сповіщення всередині додатку
  void _showInAppNotification(RemoteMessage message) {
    // Буде реалізовано пізніше з SnackBar або overlay
    debugPrint('📬 In-app notification: ${message.notification?.title}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Основні налаштування
      title: 'Anantata Career Coach',
      debugShowCheckedModeBanner: false,

      // Тема
      theme: AppTheme.lightTheme,

      // Analytics: автоматичний трекінг навігації
      navigatorObservers: [AnalyticsService().observer],

      // Builder обгортає ВСІ екрани в WebWrapper (тільки для Web)
      builder: (context, child) {
        // Баг #11: Додано перевірку на null та ErrorWidget
        Widget content = child ?? const SizedBox.shrink();

        // Обгортка для перехоплення помилок рендерингу
        content = _ErrorBoundary(child: content);

        if (kIsWeb) {
          return WebWrapper(child: content);
        }
        return content;
      },

      // Початковий екран
      home: const AppStartup(),
    );
  }
}

/// Баг #11: Error Boundary для перехоплення помилок рендерингу
class _ErrorBoundary extends StatefulWidget {
  final Widget child;

  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Щось пішло не так',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Спробуйте перезавантажити сторінку',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _resetError,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Спробувати знову'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Стартовий екран - перевіряє авторизацію
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = true;
  bool _showAuth = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Показуємо splash на 2 секунди
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final isAuthenticated = _supabase.isAuthenticated;
        
        // Якщо авторизований — ініціалізуємо сервіси (БЕЗ запиту дозволу)
        if (isAuthenticated) {
          await _initializeUserServices();
        }

        setState(() {
          _isLoading = false;
          _showAuth = !isAuthenticated;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Помилка перевірки авторизації: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showAuth = true; // При помилці показуємо auth
          _error = e.toString();
        });
      }
    }
  }

  /// Ініціалізація сервісів для авторизованого користувача
  /// 🆕 БЕЗ автоматичного запиту дозволу на сповіщення
  Future<void> _initializeUserServices() async {
    try {
      // Ініціалізуємо FCM (тільки слухачі, БЕЗ запиту дозволу)
      await FCMService().initialize();
      
      // Ініціалізуємо налаштування сповіщень
      await _supabase.initNotificationSettings();
      
      debugPrint('✅ Сервіси користувача ініціалізовано');
    } catch (e) {
      debugPrint('⚠️ Помилка ініціалізації сервісів: $e');
    }
  }

  void _onAuthSuccess() async {
    // Ініціалізуємо сервіси після успішної авторизації
    await _initializeUserServices();

    // Перевірка конфлікту планів
    await _handleSyncConflict();

    setState(() {
      _showAuth = false;
      _error = null;
    });
  }

  Future<void> _handleSyncConflict() async {
    final sync = SyncService();
    final result = await sync.checkConflict();

    switch (result.conflict) {
      case SyncConflict.both:
        if (!mounted) return;
        await _showConflictDialog(sync, result);
        break;

      case SyncConflict.cloudOnly:
        await sync.applyCloudPlan(result.cloudPlan!);
        break;

      case SyncConflict.localOnly:
        await sync.applyLocalPlan(result.localPlan!);
        break;

      case SyncConflict.none:
        break;
    }
  }

  Future<void> _showConflictDialog(SyncService sync, SyncConflictResult result) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_sync, color: Color(0xFF6C63FF), size: 48),
        title: const Text('Знайдено план в акаунті'),
        content: Text(
          'В акаунті вже є збережена ціль «${result.cloudGoalTitle}».\n\n'
          'Поточне локальне тестування буде замінено даними з акаунту.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'keepLocal'),
            child: const Text('Зберегти локальний'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'useCloud'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );

    if (choice == 'keepLocal') {
      await sync.applyLocalPlan(result.localPlan!);
    } else {
      // За замовчуванням (useCloud або закриття) — хмарний план
      await sync.applyCloudPlan(result.cloudPlan!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показуємо Splash
    if (_isLoading) {
      return const SplashScreen();
    }

    // Показуємо Auth екран
    if (_showAuth) {
      return AuthScreen(
        onAuthSuccess: _onAuthSuccess,
      );
    }

    // Показуємо Home
    return const HomeScreen();
  }
}

/// WebWrapper - обмежує ширину на десктопі (тільки для Web)
/// На мобільних браузерах: повна ширина
/// На десктопі: максимум 500px, центрування, світлий фон
class WebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundColor;

  const WebWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.backgroundColor = const Color(0xFFE8E5ED), // Світло-фіолетовий
  });

  @override
  Widget build(BuildContext context) {
    // Отримуємо ширину екрану
    final screenWidth = MediaQuery.of(context).size.width;

    // Якщо екран вузький (мобільний) - показуємо на повну ширину
    if (screenWidth <= maxWidth) {
      return child;
    }

    // На широкому екрані (десктоп) - центруємо з обмеженням
    return ColoredBox(
      color: backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: maxWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  // Баг #11: Замінено withOpacity на withValues
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
