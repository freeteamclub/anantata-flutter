# 100StepsCareer Flutter Project - Структура та Документація

## 📌 Версія документа: 2.4
## 📅 Дата створення: 11.12.2025
## 🔄 Остання зміна: 19.01.2026

---

## 📋 Загальна інформація про проект

| Параметр | Значення |
|----------|----------|
| **Назва проекту** | 100StepsCareer (раніше Anantata) |
| **Package name** | ai.anantata.careercoach |
| **Версія додатку** | 2.0.0+20 |
| **Статус** | ✅ Опубліковано в Google Play |
| **Тип проекту** | Flutter (кросплатформний) |
| **Flutter SDK** | 3.38.4 stable |
| **Dart SDK** | ^3.10.3 |
| **Платформи** | Android, iOS, Web |
| **Дизайн-система** | XelaUI (Individual License) |
| **AI** | Google Gemini (gemini-3-flash-preview) |
| **Backend** | Supabase (PostgreSQL + Auth) + Hetzner (Docker) |
| **Авторизація** | Google OAuth 2.0 |
| **Збереження** | SharedPreferences (локально) + Supabase (хмара) |
| **Сповіщення** | Telegram Bot + (планується FCM) |
| **IDE** | Android Studio з Flutter/Dart плагінами |

---

## 🔑 Ключі та конфігурація

### Supabase:
| Параметр | Значення |
|----------|----------|
| Project | AnantataFlutter |
| Region | eu-west-1 |
| URL | `https://zgyujfgskfurtkstcdjq.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1...` (в .env) |

### Google OAuth:
| Параметр | Значення |
|----------|----------|
| Web Client ID | `251334772648-pkvp5vis4ngao0qvb56sfcg2lo17ufl9...` |
| Android Client ID | `251334772648-59rs7as3m0s9tps4lvpectbeg1cari7n...` |
| SHA-1 | `FA:C6:17:45:DC:09:03:78...` |

### Release Keystore:
| Параметр | Значення |
|----------|----------|
| File | `C:\Users\Admin\Downloads\keyAnantataCoach2` |
| Alias | `key0` |
| Config | `android/key.properties` |

### Hetzner Server (Backend):
| Параметр | Значення |
|----------|----------|
| IP | Налаштовано |
| Шлях | `/opt/100steps/` |
| Docker | ✅ Telegram Bot, Notification services |

---

## 📁 Повна структура проекту

```
C:\Users\Admin\AndroidStudioProjects\anantata\
│
├── 📁 android/                 # ⚙️ Android платформа
│   ├── 📁 app/
│   │   ├── 📁 src/main/
│   │   │   └── 📄 AndroidManifest.xml  # ⭐ android:label="100StepsCareer"
│   │   └── 📄 build.gradle.kts         # ⭐ v2.0 + release signing
│   ├── 📄 key.properties               # 🔐 Keystore паролі
│   └── ...
│
├── 📁 ios/                     # 🍎 iOS платформа
├── 📁 web/                     # 🌐 Web платформа
│   └── 📄 index.html
│
├── 📁 assets/                  # 🎨 Ресурси
│   ├── 📁 font/                # Шрифти (Roboto - системний)
│   ├── 📁 icons/               # SVG іконки XelaUI
│   └── 📁 images/              # Зображення (logo_anantata.png)
│
├── 📁 lib/                     # ⭐ ОСНОВНИЙ КОД (Dart)
│   │
│   ├── 📄 main.dart                    # ⭐ v2.3 + Error Boundary
│   │
│   ├── 📁 config/                      # ⚙️ Конфігурація
│   │   ├── 📄 app_theme.dart           # Тема (кольори #413659, шрифти)
│   │   └── 📄 app_constants.dart       # Константи
│   │
│   ├── 📁 data/                        # 📊 Статичні дані
│   │   └── 📄 assessment_questions.dart # 15 питань
│   │
│   ├── 📁 models/                      # 📦 Моделі даних
│   │   ├── 📄 assessment_model.dart    # Питання оцінювання
│   │   ├── 📄 career_plan_model.dart   # ⭐ v2.1 + GoalsListModel
│   │   ├── 📄 models.dart              # Експорт
│   │   └── 📄 user_model.dart          # Користувач
│   │
│   ├── 📁 screens/                     # 📱 Екрани
│   │   │
│   │   ├── 📁 assessment/
│   │   │   ├── 📄 assessment_screen.dart   # ⭐ v2.5 + intro fix
│   │   │   └── 📄 generation_screen.dart   # ⭐ v1.2 + smooth progress
│   │   │
│   │   ├── 📁 auth/
│   │   │   └── 📄 auth_screen.dart         # ⭐ v1.3 + privacy link
│   │   │
│   │   ├── 📁 chat/
│   │   │   ├── 📄 chat_screen.dart         # ⭐ v2.4 + embedded param + URL fix
│   │   │   └── 📄 step_chat_screen.dart    # ⭐ v1.5 + URL fix
│   │   │
│   │   ├── 📁 goal/
│   │   │   ├── 📄 goal_screen.dart         # "Моя ціль" (Match Score)
│   │   │   └── 📄 goals_list_screen.dart   # ⭐ v1.5 + URL fix (career.100steps.ai)
│   │   │
│   │   ├── 📁 home/
│   │   │   └── 📄 home_screen.dart         # ⭐ v6.1 + ChatScreen embedded
│   │   │
│   │   ├── 📁 plan/
│   │   │   └── 📄 plan_screen.dart         # ⭐ v4.4 + skip limit
│   │   │
│   │   ├── 📁 profile/
│   │   │   └── 📄 profile_screen.dart      # ⭐ v4.0 + unified cards
│   │   │
│   │   ├── 📁 settings/
│   │   │   ├── 📄 social_networks_screen.dart       # ⭐ v1.1 + telegram fix
│   │   │   └── 📄 notification_settings_screen.dart # ⭐ v1.0 + types config
│   │   │
│   │   └── 📁 splash/
│   │       └── 📄 splash_screen.dart       # ⭐ v1.2 + 100StepsCareer
│   │
│   ├── 📁 services/                    # 🔧 Сервіси
│   │   ├── 📄 gemini_service.dart      # ⭐ v2.5 + rebrand
│   │   ├── 📄 services.dart            # Експорт
│   │   ├── 📄 storage_service.dart     # ⭐ v4.3 + cloud goals load
│   │   ├── 📄 supabase_service.dart    # ⭐ v2.5 + getAllGoals()
│   │   ├── 📄 sync_service.dart        # Синхронізація v1.0
│   │   └── 📄 telegram_service.dart    # Telegram v1.0
│   │
│   ├── 📁 widgets/                     # 🧩 Власні віджети
│   │
│   └── 📁 xelauikit/                   # 🎨 XelaUI бібліотека
│       ├── 📄 xela_color.dart          # Кольори
│       ├── 📄 xela_button.dart
│       └── ...інші компоненти
│
├── 📁 test/                    # 🧪 Тести
│
├── 📄 .env                     # 🔐 API ключі
├── 📄 .gitignore
├── 📄 pubspec.yaml             # ⭐ v2.0.0+20
└── 📄 README.md
```

---

## 🎨 Кольорова палітра

### Файл: `lib/config/app_theme.dart`

| Константа | HEX | Використання |
|-----------|-----|--------------|
| `primaryColor` | #413659 | Основний фіолетовий |
| `backgroundColor` | #F5F5F5 | Фон сторінок |
| `textPrimary` | #1A1A1A | Основний текст |
| `textSecondary` | #666666 | Вторинний текст |

### Шрифти:

| Шрифт | Використання |
|-------|--------------|
| `Roboto` | Всі тексти (заголовки, основний текст, кнопки) |

### Додаткові кольори:

| Колір | Використання |
|-------|--------------|
| `Colors.green` | Виконані кроки, успіх |
| `Colors.orange` | Пропущені кроки, попередження |
| `Colors.amber` | Головна ціль (⭐) |
| `Colors.red` | Видалення, помилки, ліміт |

---

## 📦 Залежності (pubspec.yaml)

```yaml
name: anantata
description: "100StepsCareer - AI-powered career development"
version: 2.0.0+20

dependencies:
  flutter:
    sdk: flutter
  
  # Core
  uuid: ^4.2.1
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.10+1
  intl: ^0.19.0
  http: ^1.2.0
  
  # URL Launcher (для посилань)
  url_launcher: ^6.2.4
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # AI
  google_generative_ai: ^0.4.6
  flutter_dotenv: ^5.1.0
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # Google Sign-In
  google_sign_in: ^6.2.1
  
  # Share
  share_plus: ^7.2.1
  
  # File System
  path_provider: ^2.1.1
```

---

## 📱 Версії файлів (актуальні на 19.01.2026)

| Файл | Версія | Ключові зміни |
|------|--------|---------------|
| `AndroidManifest.xml` | - | `android:label="100StepsCareer"` |
| `main.dart` | v2.3 | Error Boundary, WebWrapper |
| `assessment_screen.dart` | v2.5 | Intro screen fix (`_showIntro = true`) |
| `generation_screen.dart` | v1.2 | Smooth progress bar |
| `chat_screen.dart` | **v2.4** | 🆕 embedded param, URL fix (career.100steps.ai) |
| `step_chat_screen.dart` | **v1.5** | 🆕 URL fix (career.100steps.ai) |
| `goals_list_screen.dart` | **v1.5** | 🆕 URL fix share + MD export |
| `home_screen.dart` | **v6.1** | 🆕 ChatScreen(embedded: true) |
| `social_networks_screen.dart` | v1.1 | Telegram dialog centered, font fix |
| `notification_settings_screen.dart` | **v1.0** | 🆕 Типи повідомлень, час, частота |
| `splash_screen.dart` | v1.2 | "100StepsCareer" title |
| `gemini_service.dart` | v2.5 | User-friendly errors, rebrand |
| `storage_service.dart` | v4.3 | `_loadGoalsFromCloud()` method |
| `supabase_service.dart` | v2.5 | `getAllGoals()` method |

---

## 🔧 Сервіси

### GeminiService v2.5:

```dart
// Модель: gemini-3-flash-preview
GenerationConfig(
  temperature: 0.3,
  maxOutputTokens: 8192,
)

// Методи:
generateCareerPlan(answers) → GeneratedPlan
sendMessageWithContext(message, context) → String
chat(message) → String  // User-friendly error messages
buildAIContext(plan, chatHistory) → String
```

### StorageService v4.3:

```dart
// Локальне збереження + Cloud sync
getGoalsList() → GoalsListModel  // Завантажує з Supabase якщо локально пусто
_loadGoalsFromCloud() → GoalsListModel
canAddNewGoal() → bool
setPrimaryGoal(goalId) → void
deleteGoal(goalId) → void
saveGeneratedPlan(plan) → CareerPlanModel
getCareerPlan() → CareerPlanModel?
getPlanForGoal(goalId) → CareerPlanModel?
markStepDone(stepId) → void
skipStep(stepId) → void
resetStep(stepId) → void
```

### SupabaseService v2.5:

```dart
// Авторизація
signInWithGoogle() → User?
signOut() → void
isAuthenticated → bool

// Дані
getAllGoals() → List<Map>
getActiveGoal() → Map?
saveFullPlan(plan) → bool
loadPlanFromCloud() → CareerPlanModel?
getSteps(goalId) → List<Map>
saveChatMessage(text, isUser, goalId) → void
getChatHistory(limit, goalId) → List<Map>
```

### TelegramService v1.0:

```dart
// Прив'язка Telegram
linkTelegram(telegramUsername) → bool
unlinkTelegram() → bool
getTelegramStatus() → Map?
```

---

## 📲 Telegram Сповіщення (Backend)

### Архітектура:

```
┌─────────────────────────────────────────────────────────┐
│                    Hetzner Server                        │
│                   /opt/100steps/                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │  telegram_bot.py │    │  notification_generator.py  │ │
│  │  (Docker)        │    │  (Cron: 00:05 daily)        │ │
│  │                  │    │                             │ │
│  │  • /start        │    │  • Читає telegram_users     │ │
│  │  • /link {code}  │    │  • Перевіряє frequency      │ │
│  │  • /status       │    │  • Вибирає тип повідомлення │ │
│  │  • /unlink       │    │  • Додає в notification_queue│
│  └─────────────────┘    └─────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           notification_sender.py                     │ │
│  │           (Cron: кожні 5 хв)                         │ │
│  │                                                      │ │
│  │  • Читає notification_queue (status=pending)        │ │
│  │  • Перевіряє scheduled_at <= now                    │ │
│  │  • Відправляє через Telegram Bot API                │ │
│  │  • Оновлює status=sent                              │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Supabase таблиці:

| Таблиця | Призначення |
|---------|-------------|
| `telegram_users` | user_id, telegram_id, telegram_username, notification_time, frequency |
| `notification_settings` | user_id, motivational, step_reminders, achievements, weekly_stats |
| `notification_queue` | user_id, title, body, notification_type, scheduled_at, status |

### Типи повідомлень:

| Тип | Опис |
|-----|------|
| `motivational` | Мотиваційні повідомлення |
| `step_reminders` | Нагадування про кроки |
| `achievements` | Досягнення |
| `weekly_stats` | Тижнева статистика (тільки понеділок) |

### Частота (frequency):

| Значення | Опис |
|----------|------|
| `daily` | Щодня |
| `3days` | Кожні 3 дні (пн, чт, нд) |
| `weekly` | Раз на тиждень (понеділок) |
| `disabled` | Вимкнено |

---

## 🔌 MCP Сервер (Model Context Protocol)

### Підключення:
MCP сервер дає Claude прямий доступ до файлів проекту для читання та редагування.

| Параметр | Значення |
|----------|----------|
| **Назва** | anantata-flutter |
| **Шлях** | `C:\Users\Admin\AndroidStudioProjects\anantata` |
| **Можливості** | Читання, запис, редагування файлів |

### Доступні операції:
- `read_text_file` — читання файлу
- `write_file` — створення/перезапис файлу
- `edit_file` — редагування частини файлу
- `list_directory` — список файлів в папці
- `search_files` — пошук файлів за патерном

### Важливо:
> ⚠️ **Перед редагуванням або записом файлу завжди питати дозвіл користувача!**

---

## 🔐 Release Signing (android/key.properties)

```properties
storePassword=***
keyPassword=***
keyAlias=key0
storeFile=C:/Users/Admin/Downloads/keyAnantataCoach2
```

---

## 🚀 Команди

### Розробка:

```bash
# Повний шлях (Windows)
C:\SRC\flutter\bin\flutter clean
C:\SRC\flutter\bin\flutter pub get
C:\SRC\flutter\bin\flutter run
C:\SRC\flutter\bin\flutter run -d chrome

# Або через Android Studio:
# Build → Flutter → Build App Bundle
```

### Білд APK:

```bash
C:\SRC\flutter\bin\flutter clean
C:\SRC\flutter\bin\flutter pub get
C:\SRC\flutter\bin\flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

### Білд для Play Store:

```bash
C:\SRC\flutter\bin\flutter clean
C:\SRC\flutter\bin\flutter pub get
C:\SRC\flutter\bin\flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

### Git:

```bash
cd C:\Users\Admin\AndroidStudioProjects\anantata
git add .
git commit -m "v2.0.2: URL fix + embedded chat + notifications"
git push origin main
```

---

## ✅ Виконано (сесія 18-19.01.2026)

### URL виправлення (Баг #6, #7):

| Файл | Було | Стало |
|------|------|-------|
| `chat_screen.dart` | 100steps.career | career.100steps.ai |
| `step_chat_screen.dart` | 100steps.career | career.100steps.ai |
| `goals_list_screen.dart` (share) | 100steps.career | career.100steps.ai |
| `goals_list_screen.dart` (MD) | https://100steps.career | https://career.100steps.ai |

### Баг #4 — Подвійний хедер:

| Файл | Зміна |
|------|-------|
| `chat_screen.dart` | Додано параметр `embedded` (якщо true — AppBar не показується) |
| `home_screen.dart` | `ChatScreen(embedded: true)` при вбудовуванні |

### Telegram сповіщення:

| Компонент | Статус |
|-----------|--------|
| Telegram Bot | ✅ Працює |
| Прив'язка з додатку | ✅ Працює |
| Генератор повідомлень | ✅ Cron 00:05 |
| Відправка | ✅ Cron кожні 5 хв |
| Налаштування типів | ✅ З додатку |

---

## ✅ Виконано раніше (сесія 11.01.2026)

### Баги виправлені (8):

| # | Баг | Файл | Виправлення |
|---|-----|------|-------------|
| 1 | Технічна помилка офлайн | `gemini_service.dart` | User-friendly message |
| 2 | Немає кнопки "Назад" в чаті | `chat_screen.dart` | Додано AppBar |
| 3 | Intro не показується | `assessment_screen.dart` | `_showIntro = true` |
| 6 | Telegram не відкривається | `social_networks_screen.dart` | `launchUrl()` before `pop()` |
| 7 | Telegram діалог не по центру | `social_networks_screen.dart` | Centered layout |
| 9 | Чат не очищується | `chat_screen.dart` | Fixed Supabase delete |
| 11 | "AI друкує" під спойлером | `chat_screen.dart` | Moved above quick actions |
| 14 | AI повторює "Привіт!" | `step_chat_screen.dart` | Updated prompt |

### Ребрендинг "100StepsCareer":

| Файл | Що змінено |
|------|------------|
| `AndroidManifest.xml` | `android:label="100StepsCareer"` |
| `splash_screen.dart` | Title: "100StepsCareer" |
| `chat_screen.dart` | Footer: "career.100steps.ai" |
| `step_chat_screen.dart` | AI prompt + footer |
| `goals_list_screen.dart` | Share text + MD export |

---

## ⏳ TODO — Залишилось

### 🔴 P1 Критичні:
- [ ] Баг #11 — Telegram прив'язка без коду в додатку (UX flow)

### 🟠 P2 Важливі:
- [ ] Баг #10 — Технічний URL Supabase при OAuth
- [ ] Баг #3 — Назва "100Steps Career" (з пробілом) на іконці
- [ ] Push notifications (FCM) — сповіщення на телефон

### 🟡 P3 Покращення:
- [ ] Баг #2 — Нормалізація нумерації кроків від ШІ
- [ ] Баг #12 — Код Telegram накладається на текст у попапі
- [ ] AI-персоналізація сповіщень (Gemini API)

### 📱 Майбутнє:
- [ ] iOS App Store публікація
- [ ] PDF експорт плану
- [ ] Генерація Блоку 2
- [ ] Темна/світла тема

---

## 📎 Посилання

| Ресурс | URL |
|--------|-----|
| **GitHub** | https://github.com/AKovtiuk/anantata-flutter |
| **Web Demo** | https://career.100steps.ai |
| **Google Play** | Опубліковано (100StepsCareer) |
| **Supabase Dashboard** | https://supabase.com/dashboard/project/zgyujfgskfurtkstcdjq |
| **Privacy Policy** | https://privacy.anantata.ai |

---

*Документ оновлено: 19.01.2026*
*Автор: Pavlo + Claude AI*
