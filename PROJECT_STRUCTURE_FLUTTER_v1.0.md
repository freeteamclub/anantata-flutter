# Anantata Flutter Project - Структура та Документація

## 📌 Версія документа: 1.0
## 📅 Дата створення: 11.12.2025
## 🔄 Остання зміна: 11.12.2025

---

## 📋 Загальна інформація про проект

| Параметр | Значення |
|----------|----------|
| **Назва проекту** | Anantata (Flutter) |
| **Package name** | ai.anantata.anantata |
| **Версія додатку** | 1.0.0+1 |
| **Тип проекту** | Flutter (кросплатформний) |
| **Flutter SDK** | 3.38.4 stable |
| **Dart SDK** | ^3.10.3 |
| **Платформи** | Android, iOS, Web |
| **Дизайн-система** | XelaUI (Individual License, $258) |
| **IDE** | Android Studio з Flutter/Dart плагінами |
| **Дата створення проекту** | 11.12.2025 |

### Відмінність від Kotlin проекту:

| Параметр | Kotlin (старий) | Flutter (новий) |
|----------|-----------------|-----------------|
| **Папка** | AnantataCoach | anantata |
| **Мова** | Kotlin | Dart |
| **UI Framework** | Jetpack Compose | Flutter + XelaUI |
| **Платформи** | Тільки Android | Android + iOS + Web |
| **Статус** | Призупинено | Активна розробка |

---

## 🛠️ Встановлене середовище розробки

### Шляхи на комп'ютері:

| Компонент | Шлях |
|-----------|------|
| Flutter SDK | `C:\SRC\flutter` |
| Flutter в PATH | `C:\SRC\flutter\bin` |
| Проект Anantata Flutter | `C:\Users\Admin\AndroidStudioProjects\anantata` |
| Проект Anantata Kotlin (старий) | `C:\Users\Admin\AndroidStudioProjects\AnantataCoach` |
| XelaUI файли | `C:\Xela\` |
| Android SDK | `C:\Users\Admin\AppData\Local\Android\Sdk` |

### Результат `flutter doctor`:

```
[✓] Flutter (Channel stable, 3.38.4)
[✓] Windows Version (Windows 10 Pro 64-bit)
[✓] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
[✓] Chrome - develop for the web
[✓] Connected device (4 available)
[✓] Network resources
```

### Встановлені залежності (pubspec.yaml):

| Пакет | Версія | Призначення |
|-------|--------|-------------|
| flutter | SDK | Основний фреймворк |
| cupertino_icons | ^1.0.8 | iOS-стиль іконки |
| intl | ^0.19.0 | Інтернаціоналізація, форматування дат |
| flutter_svg | ^2.0.10+1 | Підтримка SVG зображень |
| flutter_lints | ^6.0.0 | Правила якості коду (dev) |

---

## 📁 Повна структура проекту

```
C:\Users\Admin\AndroidStudioProjects\anantata\
│
├── 📁 .dart_tool/              # Службові файли Dart (автогенеровані, не чіпати)
├── 📁 .idea/                   # Налаштування Android Studio/IntelliJ
│
├── 📁 android/                 # ⚙️ Android платформа
│   ├── 📁 app/
│   │   ├── 📁 src/
│   │   │   ├── 📁 debug/
│   │   │   ├── 📁 main/
│   │   │   │   ├── 📁 kotlin/ai/anantata/anantata/
│   │   │   │   │   └── 📄 MainActivity.kt
│   │   │   │   ├── 📁 res/
│   │   │   │   └── 📄 AndroidManifest.xml
│   │   │   └── 📁 profile/
│   │   └── 📄 build.gradle.kts
│   ├── 📁 gradle/
│   ├── 📄 build.gradle.kts
│   ├── 📄 gradle.properties
│   ├── 📄 gradlew
│   ├── 📄 gradlew.bat
│   ├── 📄 local.properties
│   └── 📄 settings.gradle.kts
│
├── 📁 assets/                  # 🎨 Ресурси додатку
│   ├── 📁 font/                # Шрифти
│   │   ├── 📄 nunitosansblack.ttf
│   │   ├── 📄 nunitosansbold.ttf
│   │   ├── 📄 nunitosansregular.ttf
│   │   └── 📄 nunitosanssemibold.ttf
│   ├── 📁 icons/               # SVG іконки XelaUI
│   └── 📁 images/              # Зображення
│
├── 📁 build/                   # Скомпільовані файли (автогенеровані)
│
├── 📁 ios/                     # 🍎 iOS платформа
│   ├── 📁 Flutter/
│   ├── 📁 Runner/
│   │   ├── 📁 Assets.xcassets/
│   │   ├── 📁 Base.lproj/
│   │   ├── 📄 AppDelegate.swift
│   │   └── 📄 Info.plist
│   ├── 📁 Runner.xcodeproj/
│   ├── 📁 Runner.xcworkspace/
│   └── 📄 Podfile
│
├── 📁 lib/                     # ⭐ ОСНОВНИЙ КОД ДОДАТКУ (Dart)
│   ├── 📄 main.dart            # Точка входу
│   └── 📁 xelauikit/           # XelaUI бібліотека
│       ├── 📁 models/
│       ├── 📁 utils/
│       ├── 📄 xela_accordion.dart
│       ├── 📄 xela_alert.dart
│       ├── 📄 xela_badge.dart
│       ├── 📄 xela_button.dart
│       ├── 📄 xela_chart.dart
│       ├── 📄 xela_checkbox.dart
│       ├── 📄 xela_chip.dart
│       ├── 📄 xela_color.dart      # ⭐ КОЛЬОРИ ANANTATA
│       ├── 📄 xela_date_picker.dart
│       ├── 📄 xela_dialog.dart
│       ├── 📄 xela_divider.dart
│       ├── 📄 xela_number_input.dart
│       ├── 📄 xela_radiobutton.dart
│       ├── 📄 xela_range_slider_input.dart
│       └── 📄 xela_segmented_control.dart
│
├── 📁 test/                    # 🧪 Тести
│   └── 📄 widget_test.dart
│
├── 📁 web/                     # 🌐 Web платформа
│   ├── 📁 icons/
│   ├── 📄 favicon.png
│   ├── 📄 index.html
│   └── 📄 manifest.json
│
├── 📄 .gitignore               # Git виключення
├── 📄 .metadata                # Flutter метадані
├── 📄 analysis_options.yaml    # Правила аналізу коду
├── 📄 anantata.iml             # IntelliJ модуль
├── 📄 pubspec.lock             # Зафіксовані версії залежностей
├── 📄 pubspec.yaml             # ⭐ ГОЛОВНИЙ КОНФІГ ПРОЕКТУ
├── 📄 README.md                # Опис проекту
└── 📄 PROJECT_STRUCTURE_FLUTTER_v1.0.md  # Цей файл
```

---

## 🎨 Кольорова палітра Anantata

### Файл: `lib/xelauikit/xela_color.dart`

### Основні кольори бренду:

| Константа | HEX | RGB | Використання |
|-----------|-----|-----|--------------|
| `XelaColor.Ananta` | #413659 | rgb(65, 54, 89) | Основний колір бренду |
| `XelaColor.AnantaWhite` | #FFFFFF | rgb(255, 255, 255) | Білий для контрасту |

### Повна палітра відтінків Anantata (12 рівнів):

| Константа | HEX | Опис | Приклад використання |
|-----------|-----|------|---------------------|
| `Ananta1` | #1e1829 | Найтемніший | Тіні, overlay |
| `Ananta2` | #2d2440 | Дуже темний | Темний фон, header |
| `Ananta3` | #413659 | ⭐ **Основний** | Кнопки, акценти, AppBar |
| `Ananta4` | #554770 | Темний | Hover стан кнопок |
| `Ananta5` | #6a5987 | Середньо-темний | Вторинні елементи |
| `Ananta6` | #7f6b9e | Середній | Іконки, бордери |
| `Ananta7` | #9683b0 | Середньо-світлий | Placeholder текст |
| `Ananta8` | #ad9cc2 | Світлий | Disabled стан |
| `Ananta9` | #c4b5d4 | Дуже світлий | Світлі акценти |
| `Ananta10` | #dacee6 | Пастельний | Фон карток |
| `Ananta11` | #eee8f4 | Майже білий | Світлий фон секцій |
| `Ananta12` | #f8f6fb | Найсвітліший | Основний фон сторінки |

### Приклади використання в коді:

```dart
import 'package:anantata/xelauikit/xela_color.dart';

// Основний колір
Container(color: XelaColor.Ananta)

// Білий текст на фіолетовому фоні
Text('Hello', style: TextStyle(color: XelaColor.AnantaWhite))

// Світлий фон сторінки
Scaffold(backgroundColor: XelaColor.Ananta12)

// Градієнт
LinearGradient(colors: [XelaColor.Ananta2, XelaColor.Ananta])

// Disabled кнопка
ElevatedButton(
  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(XelaColor.Ananta8)),
)
```

---

## 📄 Ключові файли та їх вміст

### 1. `lib/main.dart` — Точка входу

**Що робить:**
- Імпортує Flutter та XelaUI кольори
- Запускає додаток через `runApp()`
- Налаштовує тему з кольорами Anantata (#413659)
- Встановлює шрифт NunitoSans як основний
- Вимикає debug banner

**Налаштування теми:**
```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: XelaColor.Ananta,
    primary: XelaColor.Ananta,
    onPrimary: XelaColor.AnantaWhite,
  ),
  fontFamily: 'NunitoSans',
  appBarTheme: AppBarTheme(
    backgroundColor: XelaColor.Ananta,
    foregroundColor: XelaColor.AnantaWhite,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: XelaColor.Ananta,
    foregroundColor: XelaColor.AnantaWhite,
  ),
)
```

### 2. `pubspec.yaml` — Конфігурація проекту

**Структура:**
```yaml
name: anantata
description: "Anantata Career Coach - AI-powered career development"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.10.3

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.19.0
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/images/
    - assets/font/

  fonts:
    - family: NunitoSans
      fonts:
        - asset: assets/font/nunitosansregular.ttf
        - asset: assets/font/nunitosansbold.ttf
          weight: 700
        - asset: assets/font/nunitosanssemibold.ttf
          weight: 600
        - asset: assets/font/nunitosansblack.ttf
          weight: 900
```

### 3. `lib/xelauikit/xela_color.dart` — Кольори

**Що містить:**
- Стандартні кольори XelaUI (Blue, Pink, Green, Yellow, Orange, Red, Purple, Gray)
- 12 відтінків кожного кольору (Color1-Color12)
- **Кольори Anantata** (Ananta, AnantaWhite, Ananta1-Ananta12)

---

## 🚀 Команди для роботи з проектом

### Запуск та розробка:

| Команда | Опис |
|---------|------|
| `flutter run` | Запуск на підключеному пристрої/емуляторі |
| `flutter run -d chrome` | Запуск в Chrome браузері |
| `flutter run -d windows` | Запуск як Windows додаток |
| `flutter run -d <device_id>` | Запуск на конкретному пристрої |
| `flutter devices` | Показати доступні пристрої |
| `Ctrl+S` в IDE | Hot Reload (миттєве оновлення) |
| `Shift+F10` в Android Studio | Run |
| `r` в терміналі | Hot Reload |
| `R` в терміналі | Hot Restart |
| `q` в терміналі | Вихід |

### Збірка для релізу:

| Команда | Результат |
|---------|-----------|
| `flutter build apk` | APK файл для Android |
| `flutter build apk --release` | Оптимізований APK |
| `flutter build appbundle` | AAB для Google Play |
| `flutter build ios` | iOS збірка (потрібен Mac) |
| `flutter build web` | Web збірка |

### Обслуговування проекту:

| Команда | Опис |
|---------|------|
| `flutter pub get` | Встановити/оновити залежності |
| `flutter pub upgrade` | Оновити до останніх версій |
| `flutter pub outdated` | Показати застарілі пакети |
| `flutter clean` | Очистити build кеш |
| `flutter doctor` | Діагностика середовища |
| `flutter analyze` | Аналіз коду на помилки |
| `flutter test` | Запуск тестів |

### Git команди:

| Команда | Опис |
|---------|------|
| `git init` | Ініціалізувати репозиторій |
| `git add .` | Додати всі файли |
| `git commit -m "message"` | Зафіксувати зміни |
| `git push origin main` | Відправити на GitHub |
| `git pull` | Отримати оновлення |

---

## 📦 XelaUI — Детальна інформація

### Ліцензія:

| Параметр | Значення |
|----------|----------|
| **Тип** | Individual License |
| **Ціна** | $258 |
| **Проекти** | Необмежено |
| **Комерційне використання** | ✅ Дозволено |
| **Доступ до коду** | ✅ Повний |
| **Figma файли** | ✅ Включено |
| **Оновлення** | ✅ Lifetime |

### Компоненти XelaUI:

| Файл | Компонент | Опис |
|------|-----------|------|
| `xela_button.dart` | XelaButton | Кнопки всіх типів |
| `xela_checkbox.dart` | XelaCheckbox | Чекбокси |
| `xela_radiobutton.dart` | XelaRadioButton | Радіо-кнопки |
| `xela_chip.dart` | XelaChip | Теги, фільтри |
| `xela_badge.dart` | XelaBadge | Мітки, лічильники |
| `xela_alert.dart` | XelaAlert | Сповіщення |
| `xela_dialog.dart` | XelaDialog | Модальні вікна |
| `xela_accordion.dart` | XelaAccordion | Розгортувані списки |
| `xela_divider.dart` | XelaDivider | Роздільники |
| `xela_number_input.dart` | XelaNumberInput | Числовий ввід |
| `xela_date_picker.dart` | XelaDatePicker | Вибір дати |
| `xela_range_slider_input.dart` | XelaRangeSlider | Слайдер діапазону |
| `xela_segmented_control.dart` | XelaSegmentedControl | Перемикач сегментів |
| `xela_chart.dart` | XelaChart | Графіки та діаграми |
| `xela_color.dart` | XelaColor | Кольори (включаючи Anantata) |

### Файли XelaUI на диску:

```
C:\Xela\
├── 📁 xelauikit/                    # Оригінальні файли (розпаковані)
├── 📁 XelaUIKitFlutter/             # Flutter бібліотека (розпакована)
├── 📄 XelaFullProject (Flutter).zip # Повний приклад проекту
├── 📄 XelaUIKitFlutterLibrary.zip   # Тільки бібліотека
├── 📄 New system 2020 (Copy).fig    # Figma дизайн-система
├── 📄 How_to_import_FIG_file.png    # Інструкція імпорту в Figma
└── 📁 _MACOSX/                      # Можна видалити (Mac сміття)
```

---

## 🔮 Плани на майбутнє (TODO)

### Етап 5: Шрифти бренду Anantata
- [ ] Завантажити шрифт Bitter (для заголовків)
- [ ] Завантажити шрифт Akrobat Black (для тексту)
- [ ] Додати файли в `assets/font/`
- [ ] Зареєструвати в `pubspec.yaml`
- [ ] Оновити тему в `main.dart`

### Етап 6: Структура папок для коду
- [ ] Створити `lib/screens/` — екрани додатку
- [ ] Створити `lib/widgets/` — власні віджети
- [ ] Створити `lib/services/` — сервіси (API, DB)
- [ ] Створити `lib/models/` — моделі даних
- [ ] Створити `lib/utils/` — утиліти
- [ ] Створити `lib/constants/` — константи

### Етап 7: Екрани додатку
- [ ] Splash Screen з логотипом
- [ ] Onboarding (3-4 екрани)
- [ ] Login / Registration
- [ ] Home Dashboard
- [ ] Assessment (15 питань)
- [ ] Results з аналізом
- [ ] Chat з AI
- [ ] Profile
- [ ] Settings

### Етап 8: Інтеграції
- [ ] Google Gemini API — AI функціонал
- [ ] Supabase — база даних, авторизація
- [ ] Firebase — push notifications, analytics
- [ ] Google Sign-In
- [ ] Apple Sign-In (для iOS)

### Етап 9: Міграція логіки з Kotlin
- [ ] Assessment flow
- [ ] Career analysis алгоритм
- [ ] 10-step action plan generator
- [ ] Chat функціонал
- [ ] Task management
- [ ] Progress tracking

### Етап 10: Публікація
- [ ] Іконка додатку
- [ ] Splash screen
- [ ] Google Play Store listing
- [ ] App Store listing (потребує Mac)
- [ ] Web hosting

---

## 🐛 Відомі проблеми та рішення

### DevTools server start-up failure
**Проблема:** Попередження "DevTools server start-up failure" при запуску
**Рішення:** Натиснути "Dismiss" — це не критична помилка, не впливає на роботу

### Skipped frames warning
**Проблема:** "Skipped XX frames! The application may be doing too much work on its main thread"
**Рішення:** Нормально для debug режиму, зникне в release збірці

### Visual Studio not installed
**Проблема:** `flutter doctor` показує [X] Visual Studio
**Рішення:** Ігнорувати — потрібно тільки для Windows desktop apps, не для Android/iOS

---

## 📞 Ресурси та посилання

### Документація:
- Flutter: https://docs.flutter.dev/
- Dart: https://dart.dev/guides
- XelaUI: Figma файл `New system 2020 (Copy).fig`
- Material Design 3: https://m3.material.io/

### Anantata Brand Guidelines:
- **Primary Color:** #413659
- **Secondary Color:** #FFFFFF
- **Logo Font:** Bitter
- **Body Font:** Akrobat Black
- **Logo file:** `LOGO_ANANTATA.png`

### Корисні ресурси:
- Flutter Packages: https://pub.dev/
- Flutter YouTube: https://www.youtube.com/c/flutterdev
- Dart Pad (онлайн редактор): https://dartpad.dev/

---

## 📝 Історія версій документа

| Версія | Дата | Зміни |
|--------|------|-------|
| **1.0** | 11.12.2025 | Початкова версія. Створення проекту, XelaUI інтеграція, кольори Anantata |

---

## 📝 Історія версій додатку

| Версія | Дата | Зміни |
|--------|------|-------|
| **1.0.0+1** | 11.12.2025 | Початковий Flutter проект з XelaUI та брендовими кольорами |

---

*Документ створено: 11.12.2025*
*Автор: Pavlo + Claude AI*
*Проект: Anantata Career Coach*
