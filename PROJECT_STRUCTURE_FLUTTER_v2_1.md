# Anantata Flutter Project - Структура та Документація

## 📌 Версія документа: 2.1
## 📅 Дата створення: 11.12.2025
## 🔄 Остання зміна: 15.12.2025

---

## 📋 Загальна інформація про проект

| Параметр | Значення |
|----------|----------|
| **Назва проекту** | Anantata Career Coach (Flutter) |
| **Package name** | ai.anantata.anantata |
| **Версія додатку** | 1.0.0+1 |
| **Тип проекту** | Flutter (кросплатформний) |
| **Flutter SDK** | 3.38.4 stable |
| **Dart SDK** | ^3.10.3 |
| **Платформи** | Android, iOS, Web |
| **Дизайн-система** | XelaUI (Individual License) |
| **AI** | Google Gemini (gemini-2.0-flash) |
| **Backend** | Supabase (PostgreSQL + Auth) |
| **Авторизація** | Google OAuth 2.0 |
| **Збереження** | SharedPreferences (локально) + Supabase (хмара) |
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

---

## 📁 Повна структура проекту

```
C:\Users\Admin\AndroidStudioProjects\anantata\
│
├── 📁 android/                 # ⚙️ Android платформа
├── 📁 ios/                     # 🍎 iOS платформа
├── 📁 web/                     # 🌐 Web платформа
│
├── 📁 assets/                  # 🎨 Ресурси
│   ├── 📁 fonts/               # Шрифти (Bitter, Akrobat, NunitoSans)
│   ├── 📁 icons/               # SVG іконки XelaUI
│   └── 📁 images/              # Зображення (logo_anantata.png)
│
├── 📁 lib/                     # ⭐ ОСНОВНИЙ КОД (Dart)
│   │
│   ├── 📄 main.dart            # Точка входу v2.0
│   │
│   ├── 📁 config/              # ⚙️ Конфігурація
│   │   └── 📄 app_theme.dart   # Тема (кольори #413659, шрифти)
│   │
│   ├── 📁 models/              # 📦 Моделі даних
│   │   ├── 📄 assessment_model.dart    # Питання оцінювання
│   │   ├── 📄 career_plan_model.dart   # ⭐ v2.1 + GoalsListModel
│   │   ├── 📄 models.dart              # Експорт
│   │   └── 📄 user_model.dart          # Користувач
│   │
│   ├── 📁 screens/             # 📱 Екрани
│   │   ├── 📁 assessment/
│   │   │   ├── 📄 assessment_screen.dart   # 15 питань
│   │   │   └── 📄 generation_screen.dart   # ⭐ v1.1 + перехід до goals
│   │   ├── 📁 auth/
│   │   │   └── 📄 auth_screen.dart         # 🆕 Google Sign-In
│   │   ├── 📁 chat/
│   │   │   └── 📄 chat_screen.dart         # 🆕 AI Чат v1.0
│   │   ├── 📁 goal/
│   │   │   ├── 📄 goal_screen.dart         # "Моя ціль" (Match Score)
│   │   │   └── 📄 goals_list_screen.dart   # 🆕 "Мої цілі" (до 3)
│   │   ├── 📁 home/
│   │   │   └── 📄 home_screen.dart         # ⭐ v4.2 + кнопка "Мої цілі"
│   │   ├── 📁 plan/
│   │   │   └── 📄 plan_screen.dart         # План v4.0 (10 напрямків)
│   │   ├── 📁 profile/
│   │   │   └── 📄 profile_screen.dart      # ⭐ v2.0 + Google авторизація
│   │   └── 📁 splash/
│   │       └── 📄 splash_screen.dart       # Splash
│   │
│   ├── 📁 services/            # 🔧 Сервіси
│   │   ├── 📄 gemini_service.dart      # ⭐ AI v2.3.0 (gemini-2.0-flash)
│   │   ├── 📄 services.dart            # Експорт
│   │   ├── 📄 storage_service.dart     # ⭐ v4.0 + GoalsList
│   │   ├── 📄 supabase_service.dart    # 🆕 Supabase v1.0
│   │   └── 📄 sync_service.dart        # 🆕 Синхронізація v1.0
│   │
│   ├── 📁 widgets/             # 🧩 Власні віджети
│   │
│   └── 📁 xelauikit/           # 🎨 XelaUI бібліотека
│       ├── 📄 xela_color.dart          # Кольори Anantata
│       ├── 📄 xela_button.dart
│       └── ...інші компоненти
│
├── 📁 test/                    # 🧪 Тести
│
├── 📄 .env                     # 🔐 API ключі
├── 📄 .gitignore
├── 📄 pubspec.yaml             # ⭐ Залежності
├── 📄 PROJECT_STRUCTURE.md     # 📋 Цей файл
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
| `Bitter` | Заголовки |
| `Akrobat Black` | Великі числа, статистика |
| `NunitoSans` | Основний текст |

### Додаткові кольори:

| Колір | Використання |
|-------|--------------|
| `Colors.green` | Виконані кроки, успіх |
| `Colors.orange` | Попередження |
| `Colors.amber` | Головна ціль (⭐) |
| `Colors.red` | Видалення, помилки |

---

## 📦 Залежності (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.10+1
  
  # Утиліти
  uuid: ^4.2.1
  intl: ^0.19.0
  http: ^1.2.0
  
  # Збереження
  shared_preferences: ^2.2.2
  
  # AI
  google_generative_ai: ^0.4.6
  flutter_dotenv: ^5.1.0
  
  # 🆕 Backend
  supabase_flutter: ^2.3.0
  google_sign_in: ^6.1.6
```

---

## 🗄️ База даних Supabase

### Таблиці:

```sql
-- Користувачі (через Supabase Auth)
auth.users

-- Цілі
goals (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  assessment_id UUID,
  title TEXT,
  target_salary TEXT,
  is_primary BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ
)

-- Напрямки
directions (
  id UUID PRIMARY KEY,
  goal_id UUID REFERENCES goals,
  direction_number INTEGER,
  title TEXT,
  description TEXT,
  status TEXT DEFAULT 'pending',
  block_number INTEGER DEFAULT 1
)

-- Кроки
steps (
  id UUID PRIMARY KEY,
  goal_id UUID REFERENCES goals,
  direction_id UUID REFERENCES directions,
  step_number INTEGER,
  local_number INTEGER,
  title TEXT,
  description TEXT,
  status TEXT DEFAULT 'pending',
  block_number INTEGER DEFAULT 1
)

-- Історія чату
chat_history (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  role TEXT,
  content TEXT,
  created_at TIMESTAMPTZ
)

-- Оцінювання
assessments (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  answers JSONB,
  created_at TIMESTAMPTZ
)
```

---

## 🏗️ Архітектура даних

### CareerPlanModel v2.1:

```
CareerPlanModel
├── goal: GoalModel
│   ├── id, userId
│   ├── title ("Перехід на фріланс в IT...")
│   ├── targetSalary ("$5,000+")
│   ├── isPrimary, status
│   └── createdAt
│
├── matchScore: int (0-100)
├── gapAnalysis: String
│
├── directions: List<DirectionModel> (10 шт)
│   └── ...
│
├── steps: List<StepModel> (100 шт)
│   └── ...
│
└── currentBlock: int
```

### 🆕 GoalsListModel (до 3 цілей):

```
GoalsListModel
├── goals: List<GoalSummary> (max 3)
│   ├── id, title, targetSalary
│   ├── matchScore, gapAnalysis
│   ├── isPrimary
│   ├── progress (0-100)
│   └── formattedDate
│
├── primaryGoalId: String?
│
├── canAddNew → bool
├── availableSlots → int
└── primaryGoal → GoalSummary?
```

### ItemStatus enum:

```dart
enum ItemStatus {
  pending,    // ⏳ Очікує
  inProgress, // 🔄 В процесі
  done,       // ✅ Виконано
  skipped     // ⏭️ Пропущено
}
```

---

## 📱 Екрани додатку

### Навігація (BottomNavigationBar):

| Index | Іконка | Назва | Екран |
|-------|--------|-------|-------|
| 0 | home | Головна | HomeScreen |
| 1 | insights | План | PlanScreen |
| 2 | chat_bubble | Чат | ChatScreen 🆕 |
| 3 | person | Профіль | ProfileScreen |

### HomeScreen v4.2:
- Привітання (Доброго ранку/дня/вечора)
- Картка "Ваш прогрес"
- Швидкі дії (AI Чат, Оцінювання, План)
- **🆕 Картка "Мої цілі" (N/3)**
- Банер AI чату

### 🆕 GoalsListScreen v1.1:
- Заголовок "Мої цілі (N/3)"
- Картки цілей:
  - ⭐ Головна (жовта рамка)
  - 💰 Зарплата
  - 📅 Дата створення
  - 📊 Прогрес (0/100 кроків)
- Кнопки: Результат, Обговорити, Головна ціль, Видалити, Поділитися
- ➕ Додати нову ціль (якщо < 3)

### 🆕 ChatScreen v1.0:
- Історія повідомлень
- Контекст плану для AI
- Синхронізація з Supabase

### ProfileScreen v2.0:
- Google авторизація
- Аватар та ім'я з Google
- Кнопка "Вийти"
- Синхронізація даних

---

## 🔧 Сервіси

### GeminiService v2.3.0:

```dart
// Модель: gemini-2.0-flash
GenerationConfig(
  temperature: 0.3,  // Детермінована генерація
  maxOutputTokens: 8192,
)

// Методи:
generateCareerPlan(answers) → GeneratedPlan
```

### StorageService v4.0:

```dart
// Локальне збереження + GoalsList
getGoalsList() → GoalsListModel
canAddNewGoal() → bool
setPrimaryGoal(goalId) → void
deleteGoal(goalId) → void
saveGeneratedPlan(plan) → CareerPlanModel
getCareerPlan() → CareerPlanModel?
markStepDone(stepId) → void
```

### 🆕 SupabaseService v1.0:

```dart
// Авторизація
signInWithGoogle() → User?
signOut() → void
isAuthenticated → bool

// Дані
saveFullPlan(plan) → bool
loadFullPlan() → CareerPlanModel?
saveChatMessage(role, content) → void
getChatHistory() → List<Message>
```

### 🆕 SyncService v1.0:

```dart
// Синхронізація локальних та хмарних даних
syncPlanFromCloud() → CareerPlanModel?
syncPlanToCloud(plan) → bool
```

---

## 🚀 Команди

### Розробка:

| Команда | Опис |
|---------|------|
| `flutter run` | Запуск на пристрої |
| `flutter run -d chrome` | Запуск в Chrome |
| `flutter pub get` | Встановити залежності |
| `flutter clean` | Очистити кеш |

### Git:

```bash
cd C:\Users\Admin\AndroidStudioProjects\anantata
git add .
git commit -m "v2.1: Множинні цілі, ChatScreen, Supabase"
git push origin main
```

---

## 📝 Історія версій

| Версія | Дата | Зміни |
|--------|------|-------|
| **1.0** | 11.12.2025 | Початковий проект, XelaUI, кольори |
| **2.0** | 13.12.2025 | PlanScreen v4.0, ProfileScreen, GoalScreen |
| **2.1** | 15.12.2025 | **Supabase, Google OAuth, ChatScreen, GoalsListScreen (до 3 цілей)** |

---

## 🎯 TODO

### Виконано ✅:
- [x] Supabase інтеграція
- [x] Google OAuth авторизація
- [x] AI Чат екран
- [x] Множинні цілі (до 3)
- [x] Синхронізація з хмарою

### В процесі 🔄:
- [ ] Виправлення помилок goals_list
- [ ] Генерація Блоку 2
- [ ] Онбордінг під час генерації

### Заплановано 📋:
- [ ] Функція "Поділитися"
- [ ] Push-нотифікації
- [ ] Офлайн режим
- [ ] iOS збірка

---

## 📎 Посилання

| Ресурс | URL |
|--------|-----|
| **GitHub** | https://github.com/freeteamclub/anantata-flutter |
| **Supabase Dashboard** | https://supabase.com/dashboard/project/zgyujfgskfurtkstcdjq |
| **Google Cloud Console** | https://console.cloud.google.com |

---

*Документ оновлено: 15.12.2025*
*Автор: Pavlo + Claude AI*
