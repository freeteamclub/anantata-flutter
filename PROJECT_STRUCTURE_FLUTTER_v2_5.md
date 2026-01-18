# 100StepsCareer Flutter Project - Структура та Документація

## 📌 Версія документа: 2.5
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
│   │   │   └── 📄 AndroidManifest.xml  # ⭐ android:label="100Steps Career"
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
│   │   │   ├── 📄 assessment_screen.dart   # ⭐ v2.7 + button fix (Баг #5)
│   │   │   └── 📄 generation_screen.dart   # ⭐ v1.2 + smooth progress
│   │   │
│   │   ├── 📁 auth/
│   │   │   └── 📄 auth_screen.dart         # ⭐ v1.3 + privacy link
│   │   │
│   │   ├── 📁 chat/
│   │   │   ├── 📄 chat_screen.dart         # ⭐ v2.4 + embedded + guest history (Баг #4, #8)
│   │   │   └── 📄 step_chat_screen.dart    # ⭐ v1.5 + URL fix
│   │   │
│   │   ├── 📁 goal/
│   │   │   ├── 📄 goal_screen.dart         # "Моя ціль" (Match Score)
│   │   │   └── 📄 goals_list_screen.dart   # ⭐ v1.5 + URL fix (Баг #6, #7)
│   │   │
│   │   ├── 📁 home/
│   │   │   └── 📄 home_screen.dart         # ⭐ v6.2 + step numbering (Баг #2)
│   │   │
│   │   ├── 📁 plan/
│   │   │   └── 📄 plan_screen.dart         # ⭐ v4.4 + skip limit
│   │   │
│   │   ├── 📁 profile/
│   │   │   └── 📄 profile_screen.dart      # ⭐ v4.0 + unified cards
│   │   │
│   │   ├── 📁 settings/
│   │   │   ├── 📄 social_networks_screen.dart       # ⭐ v2.2 + simplified Telegram (Баг #11, #12)
│   │   │   └── 📄 notification_settings_screen.dart # ⭐ v1.0 + types config
│   │   │
│   │   └── 📁 splash/
│   │       └── 📄 splash_screen.dart       # ⭐ v1.2 + 100StepsCareer
│   │
│   ├── 📁 services/                    # 🔧 Сервіси
│   │   ├── 📄 gemini_service.dart      # ⭐ v2.5 + rebrand
│   │   ├── 📄 services.dart            # Експорт
│   │   ├── 📄 storage_service.dart     # ⭐ v4.4 + delete sync (Баг #9)
│   │   ├── 📄 supabase_service.dart    # ⭐ v2.6 + deleteGoal + sort (Баг #9, #13)
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
| `AndroidManifest.xml` | - | `android:label="100Steps Career"` (Баг #3) |
| `main.dart` | v2.3 | Error Boundary, WebWrapper |
| `assessment_screen.dart` | **v2.7** | Кнопка зафіксована внизу (Баг #5) |
| `generation_screen.dart` | v1.2 | Smooth progress bar |
| `chat_screen.dart` | **v2.4** | embedded param + guest history (Баг #4, #8) |
| `step_chat_screen.dart` | **v1.5** | URL fix (career.100steps.ai) |
| `goals_list_screen.dart` | **v1.5** | URL fix share + MD (Баг #6, #7) |
| `home_screen.dart` | **v6.2** | Index-based step numbering (Баг #2) |
| `social_networks_screen.dart` | **v2.2** | Simplified Telegram + scroll (Баг #11, #12) |
| `notification_settings_screen.dart` | v1.0 | Типи повідомлень, час, частота |
| `splash_screen.dart` | v1.2 | "100StepsCareer" title |
| `gemini_service.dart` | v2.5 | User-friendly errors, rebrand |
| `storage_service.dart` | **v4.4** | deleteGoal sync with Supabase (Баг #9) |
| `supabase_service.dart` | **v2.6** | deleteGoal + directions sort (Баг #9, #13) |

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

### StorageService v4.4:

```dart
// Локальне збереження + Cloud sync
getGoalsList() → GoalsListModel
_loadGoalsFromCloud() → GoalsListModel
canAddNewGoal() → bool
setPrimaryGoal(goalId) → void
deleteGoal(goalId) → void  // 🆕 + Supabase sync (Баг #9)
saveGeneratedPlan(plan) → CareerPlanModel
getCareerPlan() → CareerPlanModel?
getPlanForGoal(goalId) → CareerPlanModel?
markStepDone(stepId) → void
skipStep(stepId) → void
resetStep(stepId) → void
```

### SupabaseService v2.6:

```dart
// Авторизація
signInWithGoogle() → User?
signOut() → void
isAuthenticated → bool

// Дані
getAllGoals() → List<Map>
getActiveGoal() → Map?
saveFullPlan(plan) → bool
loadPlanFromCloud() → CareerPlanModel?  // 🆕 + directions sort (Баг #13)
deleteGoal(goalId) → bool  // 🆕 Повне видалення (Баг #9)
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
git commit -m "v2.0.3: Fixed 11 bugs (#2-#9, #11-#13)"
git push origin main
```

---

## ✅ Виконано (сесія 18-19.01.2026) — 11 БАГІВ!

### 🔴 P1 Критичні (3):

| # | Баг | Файл | Виправлення |
|---|-----|------|-------------|
| **#4** | Подвійний хедер в Помічнику | `chat_screen.dart`, `home_screen.dart` | Додано `embedded` параметр |
| **#8** | Історія чату не зберігається для гостя | `chat_screen.dart` | Локальне збереження + ключ `general_chat` |
| **#9** | Видалення цілі не працює | `storage_service.dart`, `supabase_service.dart` | Повне видалення з Supabase |

### 🟠 P2 Важливі (4):

| # | Баг | Файл | Виправлення |
|---|-----|------|-------------|
| **#3** | Назва "100Steps Career" з пробілом | `AndroidManifest.xml` | `android:label="100Steps Career"` |
| **#5** | Кнопка виходить за межі екрану | `assessment_screen.dart` | Кнопка зафіксована внизу (поза скролом) |
| **#11** | Telegram прив'язка без коду | `social_networks_screen.dart` | Прибрано код з UI, спрощено flow |
| **#13** | Порядок напрямків збивається | `supabase_service.dart` | Додано сортування по `directionNumber` |

### 🟡 P3 Покращення (4):

| # | Баг | Файл | Виправлення |
|---|-----|------|-------------|
| **#2** | Нумерація кроків некоректна | `home_screen.dart` | Index-based: `(directionIndex * 10) + stepIndex + 1` |
| **#6** | Неправильний URL в шерінгу | `goals_list_screen.dart` | `career.100steps.ai` |
| **#7** | Неправильний URL в MD файлі | `goals_list_screen.dart` | `https://career.100steps.ai` |
| **#12** | Код Telegram накладається | `social_networks_screen.dart` | `SingleChildScrollView` для малих екранів |

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
- [ ] Баг #1 — Push notifications не працюють (FCM не реалізовано)

### 🟠 P2 Важливі:
- [ ] Баг #10 — Технічний URL Supabase при OAuth (потребує Custom Domain — платно)

### 📱 Майбутнє:
- [ ] iOS App Store публікація
- [ ] PDF експорт плану
- [ ] Генерація Блоку 2
- [ ] Темна/світла тема
- [ ] Онбордінг/туторіал
- [ ] AI-персоналізація сповіщень (Gemini API)

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
