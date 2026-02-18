# 100StepsCareer — Проєктна документація

## КРИТИЧНІ ПРАВИЛА (ОБОВ'ЯЗКОВО)

1. **НЕ починай кодити, якщо не стоїть пряме завдання на кодінг.** Якщо користувач просить подивитись скріншот, проаналізувати помилку, обговорити ідею — це НЕ завдання на кодінг. Відповідай словами, описуй що бачиш, давай рекомендації — але НЕ редагуй файли.
2. **Перед початком внесення змін до коду ОБОВ'ЯЗКОВО запитай у користувача:** "Можу починати вносити зміни?" і дочекайся підтвердження. Без явного дозволу — не чіпай код.
3. **ПИТАННЯ ≠ КОМАНДА. Якщо користувач задає ПИТАННЯ — відповідай ТІЛЬКИ СЛОВАМИ.**
   - Питання ("а можна...?", "як працює...?", "чи є...?") → відповідь текстом + пропозиція дії
   - Команда ("перевір", "зроби", "запусти", "почни") → виконуй дію
   - **Це стосується БУДЬ-ЯКИХ дій:** кодінг, SSH, bash-команди, пошук файлів, запити до серверів
   - Приклад ПРАВИЛЬНО: "Можна перевірити час RAG синхронізації?" → "Так, можна — я подивлюсь логи на сервері. Перевірити?" → Користувач: "Так" → Виконуєш
   - Приклад НЕПРАВИЛЬНО: "Можна перевірити час RAG синхронізації?" → Одразу запускаєш SSH і шукаєш логи
   - **Ніколи не підміняй відповідь на питання виконанням дії. Спочатку відповідь → потім команда від користувача → потім дія.**

## Мова спілкування

Мова проєкту — **українська**. Завжди відповідай українською мовою.

## Загальна інформація

| Параметр | Значення |
|----------|----------|
| **Збереження** | SharedPreferences (локально) + Supabase (хмара) |
| **Сповіщення** | Telegram Bot (@steps100bot) + (планується FCM) |
| **IDE** | Android Studio з Flutter/Dart плагінами |

---

## Ключі та конфігурація

### Supabase:
| Параметр | Значення |
|----------|----------|
| Project | AnantataFlutter |
| Region | eu-west-1 |
| URL | `https://zgyujfgskfurtkstcdjq.supabase.co` |
| Anon Key | в .env |

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

---

## Залежності (pubspec.yaml)

```yaml
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

  # URL Launcher
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

## Сервіси

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
```

### StorageService v4.3:
```dart
// Локальне збереження + синхронізація
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
generateLinkCode() → String          // Генерує 6-символьний код
saveLinkCode(code) → bool            // Зберігає в telegram_users.link_code
openTelegramDeepLink(code) → void    // Відкриває https://t.me/steps100bot?start=CODE
linkTelegram(telegramUsername) → bool
unlinkTelegram() → bool
getTelegramStatus() → Map?
```

---

## Telegram Bot та Сповіщення (Backend)

### Загальна інформація:

| Параметр | Значення |
|----------|----------|
| **Бот** | @steps100bot (100steps) |
| **Сервер** | Hetzner 46.62.204.28 |
| **Шлях до файлів** | `/opt/100steps/` |
| **Бот запуск** | systemd сервіс (`100steps-bot.service`) |
| **Генератор** | cron щодня о 7:00 |
| **Відправник** | cron кожні 15 хв |

### Файли на сервері:

| Файл | Призначення | Запуск |
|------|-------------|--------|
| `/opt/100steps/telegram_bot.py` | Telegram бот (прив'язка, команди) | systemd: `100steps-bot.service` |
| `/opt/100steps/notification_generator.py` | Генерація сповіщень у чергу | cron: `0 7 * * *` |
| `/opt/100steps/notification_sender.py` | Відправка сповіщень з черги | cron: `*/15 * * * *` |

---

## База даних (Supabase)

### Таблиця `telegram_users`:
| Колонка | Тип | Опис |
|---------|-----|------|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users |
| `telegram_id` | bigint | Telegram user ID (заповнюється після прив'язки) |
| `telegram_username` | text | @username в Telegram |
| `telegram_first_name` | text | Ім'я в Telegram |
| `link_code` | text | 6-символьний код для deep link (тимчасовий) |
| `link_code_expires_at` | timestamptz | Термін дії коду (15 хв) |
| `linked_at` | timestamptz | Дата/час прив'язки |
| `notifications_enabled` | boolean | Сповіщення увімкнені |
| `notification_frequency` | text | daily / 3days / weekly / disabled |
| `notification_time` | time | Час відправки (за замовчуванням 09:00) |
| `created_at` | timestamptz | Дата створення запису |

### Таблиця `notification_settings`:
| Колонка | Тип | Опис |
|---------|-----|------|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users |
| `motivational` | boolean | Мотиваційні повідомлення |
| `step_reminders` | boolean | Нагадування про кроки |
| `achievements` | boolean | Досягнення |
| `weekly_stats` | boolean | Тижнева статистика |

### Таблиця `notification_queue`:
| Колонка | Тип | Опис |
|---------|-----|------|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users |
| `telegram_id` | bigint | Telegram ID отримувача |
| `title` | text | Заголовок |
| `body` | text | Текст повідомлення |
| `notification_type` | text | motivational / step_reminders / achievements / weekly_stats |
| `scheduled_at` | timestamptz | Запланований час відправки |
| `sent_at` | timestamptz | Фактичний час відправки |
| `status` | text | pending / sent / failed |
| `created_at` | timestamptz | Дата створення |

---

## Процес прив'язки Telegram

1. User taps "Підключити" в додатку
2. Генерується 6-символьний код (ABC123)
3. Код зберігається в `telegram_users.link_code` (expires +15 хв)
4. Відкривається URL: `t.me/steps100bot?start=ABC123`
5. Бот отримує `/start ABC123`
6. Бот шукає в БД: `WHERE link_code = ABC123 AND NOT expired`
7. Бот зберігає `telegram_id` та `telegram_username`
8. Прив'язка завершена

---

## Команди збірки

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
git commit -m "vX.X.X: опис змін"
git push origin main
```

### Telegram Bot (сервер):
```bash
# Статус бота
ssh root@46.62.204.28 "systemctl status 100steps-bot"

# Перезапуск бота
ssh root@46.62.204.28 "systemctl restart 100steps-bot"

# Логи бота
ssh root@46.62.204.28 "journalctl -u 100steps-bot -f"

# Перевірка cron задач
ssh root@46.62.204.28 "crontab -l"
```

---

## Скріншоти (ShareX)

Папка зі скріншотами:
```
C:\Users\Admin\OneDrive\Dokumenti\ShareX\Screenshots\
```

Структура: підпапки по місяцях (2026-02, 2026-03, ...).
Коли користувач каже "подивись скріншот" або "скрін" — знайти останній файл в найновішій підпапці.

---

## RAG Memory (Персональна пам'ять)

Векторна база з історією розмов з усіх AI чатів.

**Сервер:** `46.62.204.28:8100`

### Коли використовувати RAG:

1. Користувач питає "ми це обговорювали раніше", "як я робив X", "знайди в історії"
2. Потрібен контекст з попередніх розмов
3. Користувач явно просить шукати в RAG/пам'яті

### Команди:

```bash
# Швидкий пошук контексту
ssh root@46.62.204.28 'curl -s "http://localhost:8100/context?query=ЗАПИТ&limit=3"'

# Детальний пошук
ssh root@46.62.204.28 'curl -s -X POST http://localhost:8100/search -H "Content-Type: application/json" -d "{\"query\": \"ЗАПИТ\", \"limit\": 5}"'

# Статистика бази
ssh root@46.62.204.28 'curl -s http://localhost:8100/stats'
```

### Фільтри по джерелу:

- `claude_code` — розмови з Claude Code
- `chatgpt` — розмови з ChatGPT
- `claude_web` — розмови з Claude.ai

```bash
# Шукати тільки в ChatGPT історії
ssh root@46.62.204.28 'curl -s -X POST http://localhost:8100/search -H "Content-Type: application/json" -d "{\"query\": \"ЗАПИТ\", \"source\": \"chatgpt\"}"'
```

