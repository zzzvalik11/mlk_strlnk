# Telecom Dashboard — Flutter

Мобильное приложение **«Личный кабинет телеком-абонента»** (Starlink).

Стек: **Flutter 3.x · Dart 3.x · Riverpod · Dio · Freezed · GoRouter · fpdart**

Архитектура: **Clean Architecture** (Domain ← Data / Presentation)

---

## Скриншоты

| Экран | Описание |
|-------|----------|
| Авторизация | Форма входа по ПИН + пароль |
| Главная | PIN, ФИО, баланс, активные услуги, кнопки «Пополнить» / «История» |
| Оплата | 4 быстрых действия + список транзакций |
| Новости | Лента новостей с детальным просмотром |
| Поддержка | Форма обращения + FAQ (доступна без авторизации) |
| Пополнение | Выбор суммы + ручной ввод |
| История | Полный список операций |

---

## Стек технологий

| Категория | Технология | Версия |
|-----------|------------|--------|
| Фреймворк | Flutter | 3.x |
| Язык | Dart | 3.x |
| State Management | Riverpod (flutter_riverpod) | ^2.5.1 |
| Роутинг | GoRouter | ^14.2.0 |
| Сеть | Dio | ^5.4.3 |
| Сериализация | Freezed + json_serializable | ^2.5.2 / ^6.8.0 |
| Функциональные типы | fpdart (Either) | ^1.1.0 |
| Локальное хранилище | SharedPreferences | ^2.2.3 |
| Форматирование | intl | ^0.19.0 |
| Иконки | lucide_icons | ^0.377.0 |

---

## Структура проекта

```
lib/
├── main.dart                              # Точка входа, ProviderScope
├── core/
│   ├── constants/
│   │   ├── app_constants.dart             # API-бейзы, ключи
│   │   ├── routes.dart                    # Имена роутов
│   │   └── themes.dart                    # Цвета, стили
│   ├── errors/
│   │   ├── failures.dart                  # sealed Failure
│   │   └── exceptions.dart                # DioException → Failure
│   ├── utils/
│   │   ├── date_formatter.dart
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── widgets/
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── loading_spinner.dart
│       └── service_card.dart
├── domain/                                # Чистая бизнес-логика (без зависимостей)
│   ├── entities/                          # Freezed POCO-классы
│   │   ├── user.dart
│   │   ├── balance.dart
│   │   ├── service.dart
│   │   ├── transaction.dart
│   │   ├── news_item.dart
│   │   ├── support_ticket.dart
│   │   └── page.dart
│   ├── repositories/                      # Абстрактные контракты
│   │   ├── user_repository.dart
│   │   ├── balance_repository.dart
│   │   ├── service_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── news_repository.dart
│   │   └── support_repository.dart
│   └── usecases/                          # Бизнес-сценарии
│       ├── auth/
│       ├── balance/
│       ├── services/
│       ├── transactions/
│       ├── news/
│       └── support/
├── data/                                  # Реализации и маппинг
│   ├── models/                            # DTO (json_serializable)
│   ├── datasources/remote/                # Dio-based API
│   ├── datasources/local/                 # SharedPreferences кэш
│   ├── repositories/                      # Impl domain-контрактов
│   └── local/storage_service.dart
└── presentation/                          # UI + State
    ├── providers/                         # Riverpod Providers
    ├── screens/                           # Экраны + ViewModels
    │   ├── login/
    │   ├── home/
    │   ├── top_up/
    │   ├── history/
    │   ├── payment/
    │   ├── news/
    │   └── support/
    ├── widgets/navigation/
    │   └── bottom_nav_bar.dart
    └── router/
        └── app_router.dart
```

---

## Быстрый старт (локальный запуск)

### 1. Установить Flutter SDK

```bash
# macOS / Linux
brew install flutter

# Или вручную (все платформы):
# 1. Скачайте архив с https://docs.flutter.dev/get-started/install
# 2. Распакуйте в нужную директорию
# 3. Добавьте bin/ в PATH

# Проверка
flutter --version
flutter doctor
```

**Минимальные требования:**
- Flutter >= 3.22.0
- Dart >= 3.4.0
- Android Studio (для Android) или Xcode (для iOS)

### 2. Клонировать репозиторий

```bash
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk/flutter
```

### 3. Установить зависимости

```bash
flutter pub get
```

### 4. Сгенерировать код (Freezed + json_serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Эта команда создаст `.freezed.dart` и `.g.dart` файлы для всех сущностей и моделей.

### 5. Запустить на эмуляторе / устройстве

```bash
# Список доступных устройств
flutter devices

# Запуск (выберет первое устройство)
flutter run

# Или конкретное устройство
flutter run -d chrome        # Веб
flutter run -d macos        # macOS
flutter run -d <device_id>  # Конкретный эмулятор/телефон
```

### 6. (Опционально) Собрать APK / IPA

```bash
# Android APK (debug)
flutter build apk --debug
# Результат: build/app/outputs/flutter-apk/app-debug.apk

# Android APK (release, нужен keystore)
flutter build apk --release

# Android App Bundle (для Google Play)
flutter build appbundle --release

# iOS (только на macOS, нужен Xcode)
flutter build ios --release
```

---

## Тестовые данные

| Параметр | Значение |
|----------|----------|
| ПИН (login) | `039103` |
| Пароль | `123456` |

Приложение использует **mock-данные** — реальный бэкенд не требуется.

---

## Авторизация

- Экран входа показывается при запуске
- Все экраны защищены (GoRouter redirect)
- Исключение: экран **Поддержки** доступен без авторизации
- Сессия хранится в SharedPreferences
- Выход — иконка в шапке (HomeScreen)

---

## Архитектура

```
┌──────────────────────────────────────────────┐
│           Presentation Layer                  │
│  Screens (StatefulWidget + ConsumerState)    │
│  ViewModels (StateNotifier)                  │
│  Providers (Riverpod)                        │
│  Router (GoRouter + auth redirect)           │
├──────────────────────────────────────────────┤
│             Domain Layer                      │
│  Entities (Freezed POCO)                     │
│  Repository Contracts (abstract class)       │
│  UseCases (business scenarios)               │
│  Failures (sealed hierarchy)                 │
├──────────────────────────────────────────────┤
│              Data Layer                       │
│  Models (DTO, @JsonSerializable)             │
│  Remote Sources (Dio)                        │
│  Local Sources (SharedPreferences)           │
│  Repository Implementations                  │
│  StorageService                              │
└──────────────────────────────────────────────┘

Dependency Rule: presentation → domain ← data
Domain не зависит ни от чего.
```

---

## Обработка ошибок

```
DioException
    ↓ (ExceptionMapper в data/datasources/remote/)
Failure (sealed class)
    ├── NetworkFailure          — нет соединения, timeout
    ├── ServerFailure(status)   — 4xx, 5xx
    ├── ValidationFailure       — ошибка ввода
    └── UnknownFailure          — непредвиденное
    ↓ (UseCase / Repository)
Either<Failure, T>  (fpdart)
    ↓ (ViewModel)
ScreenState.error(message)  → ErrorState widget
```

---

## Линтинг и анализ

```bash
# Статический анализ
flutter analyze

# Форматирование
dart format lib/

# Запустить тесты
flutter test
```

---

## Полезные команды

```bash
# Очистить сгенерированные файлы
dart run build_runner clean

# Перегенерировать при изменении сущностей
dart run build_runner build --delete-conflicting-outputs

# Watch-режим (автогенерация при сохранении)
dart run build_runner watch --delete-conflicting-outputs

# Обновить зависимости
flutter pub upgrade

# Проверить наличие обновлений
flutter pub outdated
```

---

## Публикация в stores

### Google Play

```bash
# 1. Создать keystore (один раз)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Настроить android/key.properties:
# storePassword=<пароль>
# keyPassword=<пароль>
# keyAlias=upload
# storeFile=<путь к key.jks>

# 3. Собрать signed bundle
flutter build appbundle --release

# 4. Загрузить в Google Play Console
# https://play.google.com/console
```

### App Store

```bash
# 1. Настроить ios/Runner.xcworkspace (Xcode)
# 2. Собрать
flutter build ios --release

# 3. Архивировать и загрузить через Xcode → Product → Archive
# 4. Или через Transporter / Fastlane
```

---

## Лицензия

MIT
