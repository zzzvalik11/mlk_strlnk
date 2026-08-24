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
| Оплата (`/payment`) | Быстрые действия, последние операции | `PaymentViewModel` |
| Новости (`/news`) | Лента статей с детальным просмотром (`/news/:id`) | `NewsViewModel` |
| Поддержка (`/support`) | Создание обращений, отслеживание статуса | `SupportViewModel` |
| Пополнение (`/top_up`) | Ввод суммы и оплата | `TopUpViewModel` |
| История (`/history`) | Все транзакции с фильтрацией по периоду (вкл. произвольный) | `HistoryViewModel` |
| Услуги (`/services`) | Список подключённых услуг | — |
| Уведомления (`/notifications`) | Лента уведомлений с read/unread | — |
| Настройки (`/settings`) | Смена метода авторизации, выход | — |

### Навигация

Нижнее меню с 4 вкладками: **Главная**, **Оплата**, **Новости**, **Поддержка**.
Реализовано через GoRouter `ShellRoute` с `_ShellWrapper` (StatefulWidget).
Переключение вкладок через `context.go(route)`.

### Общая шапка

Все экраны авторизованной зоны используют единый виджет `AppHeader` — аватар, имя/ID пользователя, колокольчик уведомлений, настройки, выход. На внутренних экранах добавляется кнопка «назад».

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
| iOS | `.github/workflows/ios.yml` | `.ipa` | macos-latest |

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
| CI/CD               | GitHub Actions                    |

---

## Структура проекта

```
lib/
├── main.dart                          # Точка входа, ProviderScope
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # URL-базы, ключи API
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
│       ├── app_header.dart            # Единая шапка для всех экранов
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
│   │   └── page.dart                  # Пагинация
│   ├── repositories/                  # Абстрактные контракты
│   │   ├── user_repository.dart
│   │   ├── balance_repository.dart
│   │   ├── service_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── news_repository.dart
│   │   └── support_repository.dart
│   └── usecases/                      # Бизнес-сценарии
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── get_current_user_usecase.dart
│       ├── balance/
│       │   ├── get_balance_usecase.dart
│       │   └── top_up_usecase.dart
│       ├── services/
│       │   └── get_active_services_usecase.dart
│       ├── transactions/
│       │   └── get_transaction_history_usecase.dart
│       ├── news/
│       │   ├── get_news_list_usecase.dart
│       │   └── get_news_by_id_usecase.dart
│       └── support/
│           └── create_ticket_usecase.dart
├── data/
│   ├── models/                        # DTO (Freezed + toEntity extension)
│   │   ├── user_model.dart
│   │   ├── balance_model.dart
│   │   ├── service_model.dart
│   │   ├── transaction_model.dart
│   │   ├── news_model.dart
│   │   └── support_ticket_model.dart
│   ├── datasources/
│   │   ├── remote/                    # Dio-based API-клиенты
│   │   │   ├── api_client.dart
│   │   │   ├── user_remote_source.dart
│   │   │   ├── balance_remote_source.dart
│   │   │   ├── service_remote_source.dart
│   │   │   ├── transaction_remote_source.dart
│   │   │   ├── news_remote_source.dart
│   │   │   └── support_remote_source.dart
│   │   └── local/
│   │       └── user_local_source.dart
│   ├── repositories/                  # Реализации domain-контрактов
│   │   ├── user_repository_impl.dart
│   │   ├── balance_repository_impl.dart
│   │   ├── service_repository_impl.dart
│   │   ├── transaction_repository_impl.dart
│   │   ├── news_repository_impl.dart
│   │   └── support_repository_impl.dart
│   └── local/
│       └── storage_service.dart       # Обёртка над SharedPreferences
└── presentation/
    ├── providers/                     # Riverpod providers
    │   ├── auth_provider.dart
    │   ├── balance_provider.dart
    │   ├── services_provider.dart
    │   ├── transactions_provider.dart
    │   ├── news_provider.dart
    │   └── support_provider.dart
    ├── screens/
    │   ├── login/
    │   │   ├── login_screen.dart
    │   │   ├── login_view_model.dart
    │   │   ├── quick_login_screen.dart
    │   │   └── auth_method_selection_screen.dart
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── home_view_model.dart
    │   ├── payment/
    │   │   ├── payment_screen.dart
    │   │   └── payment_view_model.dart
    │   ├── top_up/
    │   │   ├── top_up_screen.dart
    │   │   └── top_up_view_model.dart
    │   ├── history/
    │   │   ├── history_screen.dart
    │   │   └── history_view_model.dart
    │   ├── news/
    │   │   ├── news_screen.dart
    │   │   ├── news_view_model.dart
    │   │   └── news_detail_screen.dart
    │   ├── support/
    │   │   ├── support_screen.dart
    │   │   └── support_view_model.dart
    │   ├── notifications/
    │   │   └── notifications_screen.dart
    │   ├── services/
    │   │   └── services_screen.dart
    │   └── settings/
    │       └── settings_screen.dart
    ├── widgets/navigation/
    │   └── bottom_nav_bar.dart        # Нижняя навигация (4 вкладки)
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
│   Repository Implementations                     │
└──────────────────────────────────────────────────┘

Dependency Rule: presentation → domain ← data
```

---

## Быстрый старт

### Требования

- Flutter >= 3.22.0 (Dart >= 3.13.0)
- Android Studio или VS Code с Flutter-плагином

### Установка и запуск

```bash
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk

# 1. Зависимости
flutter pub get

# 2. Генерация кода (Freezed + json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 3. Создание платформенных файлов
flutter create --platforms=android,ios,web .

# 4. Запуск
flutter run
```

> **Примечание:** Платформенные директории (`android/`, `ios/`, `web/`) не хранятся в репозитории.
> Исключение — `ios/Podfile` (в новых версиях Flutter SDK он не генерируется автоматически).
> Если `flutter create` не создал Podfile, он уже есть в репозитории.

### Запуск на Web

```bash
flutter run -d chrome
# или
flutter run -d Edge
```

### Если генерация не срабатывает (no-op)

```bash
flutter clean
rm -rf .dart_tool/build
flutter pub get
dart run build_runner build --delete-conflicting-outputs
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
| `/login` | Вход (ПИН/пароль) | Нет |
| `/quick_login` | Быстрый вход | Нет |
| `/auth_method_selection` | Выбор метода входа | Нет |

---

## Полезные команды

```bash
# Статический анализ
flutter analyze

# Форматирование
dart format lib/

# Перегенерировать код
dart run build_runner build --delete-conflicting-outputs

# Watch-режим (автогенерация при изменениях)
dart run build_runner watch

# Запустить CI локально (нужен act)
act push -W .github/workflows/android.yml
```

---

## Лицензия

MIT
