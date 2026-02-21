# 100Steps Career — Спрінти та Тікети

**Оновлено:** 2026-02-12
**Загальний час:** ~88.5 год Claude Code + ручна робота

---

## Таблиця спрінтів

| Спрінт | Назва | Тікети | Год | Накопичено | Статус |
|--------|-------|--------|-----|------------|--------|
| **1** | **Фундамент AI** | T1, T5, T7, T8, T10 | 5 | 5 | **DONE** (не протестовано) |
| **2** | **Онбординг + Генерація** | T3, T4, T6, T11, T37*, T38* | 5 + ручна | 10 | **DONE** (не протестовано) |
| **W** | **Web-версія** | T39-T59 | 20 | 30 | **NEXT** |
| 3 | iOS + Engagement | T2, T9, T17, T19* | 6 | 36 | |
| **4** | **RAG Memory** | T13, T14, T15, T16 | 7 | 23 | **DONE** (не протестовано) |
| 5 | Геміфікація + FCM | T18, T19*, T20, T21 | 7.5 | 30.5 | |
| 6 | Офлайн | T27, T28 | 4 | 34.5 | |
| 7 | Зовнішні дані | T22, T23, T25, T26 | 11 | 45.5 | |
| 8 | DOU + Монетизація | T24, T30, T31 | 9 | 54.5 | |
| 9 | Проактивний Джарвіс | T32, T33, T34, T35, T36 | 11 | 65.5 | |
| 10 | Community | T29 | 3 | 68.5 | |
| **11W** | **Web-версія** | T39-T59 | 20 | — | **NEXT** |

---

## Всі тікети

### Спрінт 1: Фундамент AI — DONE (код готовий, потребує тестування тестером)

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T1 | Нумерація кроків — index-based нумерація в PlanScreen (stepIndex+1 замість step.localNumber) | 0.5 | **DONE** |
| T5 | Промпт step_chat — роль "Коуч", картка кроку, directionTitle, правила (ресурси, feedback, наступний крок) | 1 | **DONE** |
| T7 | Profile Summary Service — ProfileSummaryService що зберігає/завантажує profile_summary з Supabase та SharedPreferences | 1.5 | **DONE** |
| T8 | Динамічний промпт — інтеграція profile_summary в системні промпти chat_screen та step_chat_screen | 1 | **DONE** |
| T10 | Промпт Коуча (chat_screen) — роль "Кар'єрний Коуч", привітання по імені, аналіз прогресу, рекомендації | 1 | **DONE** |

### Спрінт 2: Онбординг + Генерація — DONE (код готовий, потребує тестування тестером)

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T3 | Напрямок #1 "Знайомство" — 10 незалежних кроків (3 статичні + 7 задач), інжектується в storage_service при збереженні плану | 1.5 | **DONE** |
| T4 | Всі 10 напрямків видимі одразу — без гейту, спрощено (block1_service видалено) | 1 | **DONE** |
| T6 | Промпт генерації: Gemini генерує 9 напрямків (2-10), нові поля type/difficulty/estimatedTime/expectedOutcome | 1.5 | **DONE** |
| T11 | Choice Chips UI — парсинг [CHOICES]...[/CHOICES], тапабельні chips в chat_screen та step_chat_screen | 1 | **DONE** |
| T37* | Amplitude дашборди — створити 5 дашбордів | Ручна | Очікує |
| T38* | Google Play open testing — перехід з closed на open testing | Адмін | Очікує |

### Спрінт 3: iOS + Engagement

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T2 | iOS збірка — flutter build ios, сертифікати, provisioning profiles, TestFlight | 2.5 | |
| T9 | TG-сповіщення персоналізовані — оновити notification_generator.py з контекстом profile_summary + крок + серія | 1 | |
| T17 | Стріки — логіка підрахунку серії днів, таблиця/поле, UI віджет на домашньому екрані | 2 | |
| T19* | Домашній екран (частина 1) — стрік зверху, прогрес-бар, наступний крок з кнопкою "Почати" | 0.5 | |

### Спрінт 4: RAG Memory — DONE (код готовий, потребує тестування тестером)

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T13 | Qdrant колекція `100steps_users` (BGE-M3, 1024 dims, Cosine) + FastAPI ендпоінти `/100steps/add`, `/100steps/search`, `/100steps/add/batch`, `/100steps/stats` на Hetzner. Ізоляція по `user_id` | 2 | **DONE** |
| T14 | Тригери індексації — fire & forget в `chat_screen._sendMessage()` та `step_chat_screen._sendMessage()`: user msg + bot msg індексуються в RAG після відповіді Gemini | 2 | **DONE** |
| T15 | RAG в Коуч — `rag_service.dart` (search/addMessage/addBatch), RAG пошук перед Gemini запитом, top-3 результати в системний промпт + assessment контекст. Збагачений `buildAIContext()` з деталями кроків (type/difficulty/estimatedTime/expectedOutcome) | 2 | **DONE** |
| T16 | Адаптивні правила в `buildAIContext()`: 3+ кроки/тиждень → складніші, застряг >3 дні → альтернатива, пауза >5 днів → м'яке привітання, серія >7 → stretch goal. Історія чату збільшена 10→20 | 1 | **DONE** |

### Спрінт 5: Геміфікація + FCM

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T18 | Бейджі 10 штук — badge_definitions, badge_service, колекція UI, popup при отриманні | 3 | |
| T19* | Домашній екран (частина 2) — останні бейджі, щоденний інсайт (Gemini Flash-Lite) | 1.5 | |
| T20 | FCM інтеграція — firebase_messaging пакет, FCM token збереження в Supabase, server-side відправка | 2 | |
| T21 | Логіка TG/FCM — якщо є Telegram → TG бот, якщо немає → FCM push | 1 | |

### Спрінт 6: Офлайн

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T27 | Офлайн кешування — кешувати план, профіль, прогрес, останні повідомлення (Hive/SharedPreferences) | 3 | |
| T28 | Авто-sync — при поверненні інтернету автоматична синхронізація з Supabase | 1 | |

### Спрінт 7: Зовнішні дані

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T22 | База курсів — таблиця learning_resources, 50-100 курсів (Prometheus, Coursera, YouTube, DOU), інтеграція в Коуч | 4 | |
| T23 | Robota.ua API — Edge Function для пошуку вакансій | 3 | |
| T25 | Djinni API — Edge Function для пошуку IT-вакансій | 2 | |
| T26 | Матчинг профіль↔вакансія — Gemini оцінює збіг профілю з вакансією (score) | 2 | |

### Спрінт 8: DOU + Монетизація

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T24 | DOU зарплати — парсинг зарплатної аналітики DOU | 2 | |
| T30 | Paywall + RevenueCat — екран підписки, логіка лімітів, purchases_flutter SDK | 5 | |
| T31 | AI-дайджест — щотижневий cron генерує дайджест кар'єрних новин через Gemini | 2 | |

### Спрінт 9: Проактивний Джарвіс

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T32 | Cron пошук вакансій — щоденний скан Robota/DOU/Djinni → матчинг → alert | 3 | |
| T33 | Автоматичний scoring — scoring профіль↔вакансія для всіх користувачів | 2 | |
| T34 | TG alert вакансії — TG-повідомлення при score > 80% | 2 | |
| T35 | Ринкова аналітика — тренди зарплат по позиції/сфері | 2 | |
| T36 | Тижневий AI-звіт — щопонеділка: прогрес + нові вакансії + тренди + рекомендації | 2 | |

### Спрінт 10: Community

| Тікет | Опис | Год | Статус |
|-------|------|-----|--------|
| T29 | TG-група + milestone бот — група @100steps_career_ua + бот для auto-post milestone | 3 | |

### Спрінт 11W: Web-версія 100StepsCareer — ~20 год (може виконуватись паралельно зі Спрінт 3)

**Документація:** `plan/Web Version 100steps/WEB_VERSION_FULL_PLAN_For_100Steps.md`, `DEPLOY_INSTRUCTION.md`

#### Фаза W1 — Безпека бекенду (P1)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T39 | Gemini API Proxy — Node.js Express на Hetzner в Docker, 5 ендпоінтів, JWT авторизація, rate limiting, порт 3100 | Сервер | 4 | — | **DONE** |
| T40 | Перевірка RLS Supabase — перевірити `auth.uid() = user_id` на всіх таблицях | Авто+Ручна | 1 | — | **DONE** (увімкнено RLS на notification_queue) |
| T41 | Google OAuth Authorized Domains — додати career.100steps.ai в дозволені origins/redirects | Ручна | 0.25 | — | |
| T42 | Supabase Redirect URLs — Site URL + redirect URLs для Web | Ручна | 0.25 | — | **DONE** |

#### Фаза W2 — Код Flutter (P1)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T43 | Fix `dart:io` import — замінити `Platform.isAndroid/iOS` на `defaultTargetPlatform`, прибрати `dart:io` | Код | 0.5 | — | **DONE** |
| T44 | Оновити `gemini_service.dart` — Web через проксі (`_callViaProxy`), Mobile напряму, розгалуження `kIsWeb` | Код | 1 | T39 | **DONE** |
| T45 | Додати `GEMINI_PROXY_URL` в `.env` Flutter проекту | Код | 0.1 | T39 | **DONE** |

#### Фаза W3 — Деплой (P1)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T46 | Збірка Web (`flutter build web --release`) + деплой на Hostinger + домен career.100steps.ai | DevOps | 1 | T43, T44, T45 | **DONE** |
| T47 | Локальне тестування Web — auth, assessment, генерація, чат, профіль, goals | QA | 2 | T46 | |

#### Фаза W4 — Покращення безпеки (P2)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T48 | Firebase API Key Restrictions — обмежити по доменах та API | Ручна | 0.3 | — | |
| T49 | FCM Service Worker — `firebase-messaging-sw.js` для Web Push | Код | 1 | — | |
| T50 | Content Security Policy — мета-тег CSP в `index.html` | Код | 0.5 | — | **DONE** (тимчасово вимкнено — Flutter Web потребує blob: + fonts.gstatic.com) |
| T51 | HTTPS + Security Headers — X-Frame-Options, HSTS, X-XSS-Protection | DevOps | 0.5 | T46 | **DONE** (nginx: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, HSTS) |
| T52 | SSL для проксі — nginx reverse proxy + certbot для api.100steps.ai | Сервер | 0.5 | T39 | **DONE** |

#### Фаза W5 — Адаптація UI + Тестування (P2)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T53 | Перевірити всі `dart:io` в проекті — grep + замінити всі Platform.* | Код | 0.5 | T43 | **DONE** (чисто, dart:io не знайдено) |
| T54 | Responsive layout — перевірити/адаптувати WebWrapper (500px→600-700px?) | Код | 2 | — | **DONE** (maxWidth 500→600) |
| T55 | URL Strategy SPA — .htaccess або nginx для path-based URL | DevOps | 0.5 | T46 | **DONE** (usePathUrlStrategy + .htaccess) |
| T56 | Повне тестування — Desktop браузери + різні розміри + функціональне | QA | 2 | T46-T55 | |

#### Фаза W6 — Після запуску (P3)

| Тікет | Опис | Тип | Год | Залежності | Статус |
|-------|------|-----|-----|------------|--------|
| T57 | Моніторинг — бюджет Gemini API $10/міс, логи проксі, Supabase usage | Ручна | 0.5 | T39 | |
| T58 | Оптимізація бандла — canvaskit vs html renderer, gzip, caching headers | DevOps | 1 | T46 | |
| T59 | SEO мета-теги — lang="uk", canonical, robots.txt, sitemap.xml | Код | 0.5 | T46 | **DONE** (robots.txt, sitemap.xml, canonical link) |

---

## Примітки

- **T12** (BGE-M3 Docker) — вже існує на сервері, окремий тікет не потрібен
- **T19*** — розділений на 2 частини (спрінт 3 і спрінт 5), бо домашній екран оновлюється поступово
- **T37***, **T38*** — не код, а ручна/адмін робота
- Детальний опис кожної задачі (промпти, файли, SQL) — див. `100STEPS_TASKS_BREAKDOWN v2.md`
- **Спрінти 1, 2 та 4** — код написаний і базово перевірений розробником, але ще **не протестовані тестером** (потрібне повноцінне QA тестування)
- **Спрінт 4** — комбінований підхід: Supabase (останні 20 повідомлень) + Qdrant RAG (семантичний пошук по всій історії). Серверна частина: `/opt/rag/steps_api.py`. Flutter: `rag_service.dart`, збагачені промпти в `gemini_service.dart`, `chat_screen.dart`, `step_chat_screen.dart`
- **Sprint 11W** (Web-версія) — окремий спрінт, може виконуватись паралельно з іншими. T40 вже виконано (RLS аудит). Детальна документація: `plan/Web Version 100steps/`
