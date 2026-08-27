# Starlink — Личный кабинет абонента

Мобильное приложение для абонентов телеком-оператора. Отображает баланс, подключённые услуги, историю платежей, новости и обеспечивает связь с техподдержкой.

**Стек:** Flutter 3.x · Dart 3.13+ · Riverpod · GoRouter · Dio · Freezed 4.x · fpdart

**Архитектура:** Clean Architecture — три слоя (Domain / Data / Presentation) с односторонней зависимостью `presentation → domain ← data`.

---

## Функциональность

### Авторизация
- Вход по ПИН-коду (6 цифр)
- Вход по паролю
- Выбор метода авторизации при первом запуске
- Быстрый повторный вход (Quick Login)
- Биометрическая аутентификация (отпечаток пальца)

### Экраны

| Экран | Описание | ViewModel |
|-------|----------|-----------|
| Главная (`/`) | Баланс, дата оплаты, список активных услуг, уведомления, замок тарифа | `HomeViewModel` |
| Оплата (`/payment`) | Быстрые действия, последние операции, обещанный платёж | `PaymentViewModel` |
| Новости (`/news`) | Лента статей с детальным просмотром (`/news/:id`) | `NewsViewModel` |
| Поддержка (`/support`) | Создание обращений, отслеживание статуса | `SupportViewModel` |
| Пополнение (`/top_up`) | Ввод суммы и оплата (карта / СБП QR) | `TopUpViewModel` |
| История (`/history`) | Все транзакции с фильтрацией по периоду | `HistoryViewModel` |
| Услуги (`/services`) | Список подключённых услуг | — |
| Уведомления (`/notifications`) | Лента уведомлений с read/unread | — |
| Настройки (`/settings`) | Смена метода авторизации, выход | — |

### Навигация

Нижнее меню с 4 вкладками: **Главная**, **Оплата**, **Новости**, **Поддержка**.
Реализовано через GoRouter `ShellRoute` с `_ShellWrapper` (StatefulWidget).
Переключение вкладок через `context.go(route)`.

### Общая шапка

Все экраны авторизованной зоны используют единый виджет `AppHeader` — логотип, имя/ID пользователя, колокольчик уведомлений, настройки, выход. На внутренних экранах добавляется кнопка «назад».

---

## Тестовые данные

| Параметр | Значение |
|----------|----------|
| ПИН      | `039103` |
| Пароль   | `123456` |

> Для учётной записи `039103` / `123456` приложение использует **моковые данные** — сервер не требуется.
> Все остальные пользователи работают с реальным HTTP API.

---

## CI/CD — Автоматическая сборка

При каждом push в `main` GitHub Actions автоматически собирает:

| Platform | Workflow | Артефакт | Runner |
|----------|----------|----------|--------|
| Android | `.github/workflows/android.yml` | `.apk` или `.aab` | ubuntu-latest |
| iOS | `.github/workflows/ios.yml` | `.ipa` (без подписи) | macos-latest |

Артефакты доступны для скачивания во вкладке **Actions**.

Подробная инструкция — см. [**CI_GUIDE.md**](./CI_GUIDE.md).

---

## Технологии

| Категория           | Технология                        |
|---------------------|-----------------------------------|
| Фреймворк           | Flutter 3.x (Dart 3.13+)          |
| State management    | Riverpod (`flutter_riverpod`)     |
| Роутинг             | GoRouter 14.x (ShellRoute)        |
| Сеть                | Dio                               |
| Сериализация        | Freezed 4.x + json_serializable   |
| Функц. программ.    | fpdart (`Either`)                 |
| Локальное хранилище | SharedPreferences                  |
| Локализация         | `flutter_localizations` + `intl`  |
| Биометрия           | `local_auth`                      |
| QR-коды (СБП)       | `qr_flutter`                      |
| Платёжная WebView   | `webview_flutter`                 |
| URL launcher        | `url_launcher`                     |
| Push-уведомления    | `firebase_core` + `firebase_messaging` |
| Конфигурация        | `flutter_dotenv`                  |
| CI/CD               | GitHub Actions                    |

---

## Структура проекта

```
lib/
├── main.dart                          # Точка входа, Firebase, .env, ProviderScope
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # URL-базы, ключи (из .env), таймауты
│   │   ├── routes.dart                # Константы маршрутов
│   │   └── themes.dart                # Цвета, текстовые стили, паддинги
│   ├── errors/
│   │   ├── failures.dart              # Failure (sealed union hierarchy)
│   │   └── exceptions.dart            # DioExceptionMapper
│   ├── utils/
│   │   ├── currency_formatter.dart    # Форматирование рублей
│   │   ├── date_formatter.dart        # Форматирование дат
│   │   └── validators.dart            # Валидация ПИН / пароля
│   └── widgets/
│       ├── app_header.dart            # Единая шапка (логотип, user, bell)
│       ├── empty_state.dart           # Пустое состояние
│       ├── error_state.dart           # Ошибка с retry
│       ├── loading_spinner.dart       # Индикатор загрузки
│       └── service_card.dart          # Карточка услуги
├── domain/
│   ├── entities/                      # Freezed data-классы
│   │   ├── user.dart
│   │   ├── balance.dart
│   │   ├── service.dart
│   │   ├── transaction.dart
│   │   ├── news_item.dart
│   │   ├── support_ticket.dart
│   │   ├── payment_link.dart
│   │   ├── payment_result.dart
│   │   ├── sms_status.dart
│   │   └── page.dart                  # Пагинация
│   ├── repositories/                  # Абстрактные контракты
│   │   ├── user_repository.dart
│   │   ├── balance_repository.dart
│   │   ├── service_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── news_repository.dart
│   │   ├── payment_repository.dart
│   │   ├── sms_repository.dart
│   │   └── support_repository.dart
│   └── usecases/                      # Бизнес-сценарии
│       ├── auth/
│       ├── balance/
│       ├── services/
│       ├── transactions/
│       ├── news/
│       ├── payments/
│       └── support/
├── data/
│   ├── models/                        # DTO (Freezed + toEntity extension)
│   ├── datasources/
│   │   ├── remote/                    # Dio-based API-клиенты
│   │   │   ├── api_client.dart        # Центральный HTTP-клиент (Dio + interceptors)
│   │   │   ├── user_remote_source.dart
│   │   │   ├── balance_remote_source.dart
│   │   │   ├── service_remote_source.dart
│   │   │   ├── transaction_remote_source.dart
│   │   │   ├── news_remote_source.dart
│   │   │   ├── payment_remote_source.dart
│   │   │   ├── sms_remote_source.dart
│   │   │   └── support_remote_source.dart
│   │   └── local/
│   │       └── user_local_source.dart
│   ├── repositories/                  # Реализации domain-контрактов
│   ├── services/
│   │   └── fcm_service.dart           # Firebase Cloud Messaging
│   └── local/
│       └── storage_service.dart       # Обёртка над SharedPreferences
└── presentation/
    ├── providers/                     # Riverpod providers
    ├── screens/
    │   ├── login/                      # Логин, Quick Login, выбор метода
    │   ├── home/                       # Главная
    │   ├── payment/                    # Оплата, обещанный платёж
    │   ├── top_up/                     # Пополнение, QR СБП, callback
    │   ├── history/                    # История транзакций
    │   ├── news/                       # Новости, детали
    │   ├── support/                    # Поддержка
    │   ├── notifications/              # Уведомления
    │   ├── services/                   # Услуги
    │   └── settings/                   # Настройки
    ├── widgets/navigation/
    │   └── bottom_nav_bar.dart         # Нижняя навигация (4 вкладки)
    └── router/
        └── app_router.dart            # GoRouter + ShellRoute + auth redirect
```

---

## Архитектура

```
┌──────────────────────────────────────────────────┐
│               Presentation Layer                 │
│   Screens (ConsumerStatefulWidget)               │
│   ViewModels (StateNotifier / AutoDispose)       │
│   Providers (Riverpod)                           │
│   Router (GoRouter 14 + ShellRoute)              │
├──────────────────────────────────────────────────┤
│                Domain Layer                      │
│   Entities (Freezed 4.x data-classes)            │
│   Repository Contracts (abstract class)          │
│   UseCases (бизнес-сценарии)                     │
│   Failures (sealed union hierarchy)              │
├──────────────────────────────────────────────────┤
│                Data Layer                        │
│   Models (DTO, Freezed + toEntity extension)     │
│   Remote Sources (Dio)                           │
│   Local Sources (SharedPreferences)              │
│   Services (FCM)                                 │
│   Repository Implementations                     │
└──────────────────────────────────────────────────┘

Dependency Rule: presentation → domain ← data
```

---

## Внешние интеграции

Бэкенд выступает **оркестратором** между мобильным приложением и сторонними сервисами. Приложение напрямую не обращается к внешним API.

| Сервис | Назначение | Протокол |
|--------|-----------|----------|
| **Starlink BSS** | Биллинг: авторизация, счета, услуги, тарифы, транзакции | REST API (JWT) |
| **РСБ ECOMM** | Платёжный шлюз: оплата картой, 3DS 2.x | HTTP POST (SSL) |
| **СБП** (Сбербанк) | Оплата по QR-коду | REST API (JSON) |
| **Devino Telecom** | SMS: OTP, уведомления | REST API v2 (Basic Auth) |
| **Firebase Cloud Messaging** | Push-уведомления | FCM HTTP v1 |

Полная спецификация — [`api.yaml`](./api.yaml) (OpenAPI 3.0.3, 42 эндпоинта).
Подробная архитектура — [`ARCHITECTURE.md`](./ARCHITECTURE.md).
Публикация в сторы — [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md).

---

## Быстрый старт

### Требования

- Flutter >= 3.22.0 (Dart >= 3.13.0)
- Android Studio или VS Code с Flutter-плагином
- Firebase проект (для push-уведомлений)

### Установка и запуск

```bash
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk

# 1. Переменные окружения
cp .env.example .env
# Отредактируйте .env (как минимум API_BASE_URL)

# 2. Зависимости
flutter pub get

# 3. Генерация кода (Freezed + json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Создание платформенных файлов
flutter create --platforms=android,ios,web .
bash scripts/configure_deep_links.sh

# 5. Сгенерировать иконку приложения
flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml

# 6. Запуск
flutter run
```

> **Примечание:** Платформенные директории (`android/`, `ios/`, `web/`) не хранятся в репозитории — генерируются при каждой сборке.

### Если генерация не срабатывает (no-op)

```bash
flutter clean
rm -rf .dart_tool/build
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Маршруты

| Маршрут | Экран | Требует авторизацию |
|---------|-------|---------------------|
| `/` | Главная | Да |
| `/payment` | Оплата | Да |
| `/news` | Новости | Да |
| `/support` | Поддержка | Нет |
| `/top_up` | Пополнение | Да |
| `/history` | История | Да |
| `/news/:id` | Детали новости | Да |
| `/services` | Услуги | Да |
| `/notifications` | Уведомления | Да |
| `/settings` | Настройки | Да |
| `/promised_payment` | Обещанный платёж | Да |
| `/login` | Вход (ПИН/пароль) | Нет |
| `/quick_login` | Быстрый вход | Нет |
| `/auth_method_selection` | Выбор метода входа | Нет |

---

## Конфигурация (.env)

Чувствительные данные хранятся в `.env` (не попадает в git). Шаблон — [`.env.example`](./.env.example).

| Переменная | Описание | По умолчанию |
|------------|----------|---------------|
| `API_BASE_URL` | Основной API (биллинг) | `http://10.0.2.2:3000/api` |
| `SBP_API_URL` | СБП API (пустой = API_BASE_URL) | — |
| `RSB_PAYMENT_URL` | РСБ шлюз (пустой = API_BASE_URL) | — |
| `RSB_REGISTER_URL` | РСБ регистрация (пустой = API_BASE_URL) | — |
| `RSB_MERCHANT_NAME` | Имя мерчанта РСБ | — |
| `RSB_TERMINAL_ID` | Терминал РСБ | — |
| `RSB_MERCHANT_ID` | Merchant ID РСБ | — |
| `RSB_SECRET_KEY` | Секретный ключ РСБ | — |
| `FCM_SERVER_KEY` | Server key для отправки пушей | — |

---

## Полезные команды

```bash
# Статический анализ
flutter analyze

# Форматирование
dart format lib/

# Перегенерировать код
flutter pub run build_runner build --delete-conflicting-outputs

# Watch-режим (автогенерация при изменениях)
flutter pub run build_runner watch

# Сгенерировать иконки
flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml

# Отправить тестовый пуш
bash scripts/send_test_push.sh <DEVICE_TOKEN> "Тест" "Привет!"
```

---

## Лицензия

MIT
