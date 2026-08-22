# 📱 Личный кабинет телеком-абонента — Flutter Clean Architecture

> Мобильное приложение «Личный кабинет телеком-абонента» на Flutter 3.x с полной реализацией Clean Architecture.
> Покрывает авторизацию, просмотр баланса, пополнение, историю операций, новости и поддержку.

---

## О проекте

**«Личный кабинет телеком-абонента»** — мобильное приложение на Flutter 3.x, построенное по Clean Architecture.
Полностью соответствует [ARCHITECTURE.md](./upload/ARCHITECTURE.md).

Приложение включает:

- 🔐 Авторизацию по ПИН-коду и паролю
- 💰 Просмотр баланса и даты оплаты
- ➕ Пополнение баланса с быстрыми суммами
- 📋 Историю транзакций
- 📰 Ленту новостей с деталями
- 🎫 Обращения в техническую поддержку
- 🌐 Активные услуги

### Стек технологий

| Технология | Версия | Назначение |
|------------|--------|------------|
| **Flutter** | 3.22+ | UI-фреймворк |
| **Dart** | 3.2+ | Язык разработки |
| **Riverpod** | ^2.5.1 | Управление состоянием + DI |
| **Dio** | ^5.4.3 | HTTP-клиент с интерцепторами |
| **Freezed** | ^2.5.2 | Immutable сущности и состояния |
| **json_serializable** | ^6.8.0 | Сериализация JSON |
| **go_router** | ^14.2.0 | Декларативная навигация |
| **fpdart** | ^1.1.0 | Функциональный `Either<Failure, T>` |
| **shared_preferences** | ^2.2.3 | Локальное хранилище (сессия) |
| **intl** | ^0.19.0 | Форматирование дат и валюты |
| **lucide_icons** | ^0.377.0 | Иконки |

---

## Архитектура

### Clean Architecture: Domain ← Data / Presentation

Приложение построено по принципу **Clean Architecture** (Роберт Мартин). Бизнес-логика (Domain) находится
в центре и не зависит ни от фреймворка, ни от базы данных, ни от UI.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│  (Screens, Widgets, ViewModels, Providers, Router)  │
│                      ↓ depends on                   │
├─────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                    │
│         (Entities, Repositories, UseCases)          │
│                 ← центр, никаких зависимостей       │
├─────────────────────────────────────────────────────┤
│                     DATA LAYER                       │
│      (Models, DataSources, Repository Impls)        │
│                      ↓ depends on                   │
└─────────────────────────────────────────────────────┘
```

### Dependency Rule

> **Зависимости всегда направлены внутрь — к Domain.**

- `Presentation` → зависит от `Domain` (вызывает UseCases, подписывается на Providers)
- `Data` → зависит от `Domain` (реализует абстрактные Repository, маппит Models → Entities)
- `Domain` → **не зависит ни от чего** — чистый Dart без Flutter, без Dio, без Riverpod

Это позволяет:
- **Тестировать** Domain-слой изолированно (мок-репозитории)
- **Заменять** бэкенд или базу данных без изменения бизнес-логики
- **Переиспользовать** UseCases в разных точках приложения

### Таблица соответствия слоёв и файлов

| Слой | Папка | Количество файлов | Описание |
|------|-------|-------------------|----------|
| **Domain** | `domain/entities/` | 7 | Чистые сущности (freezed, POCO) |
| | `domain/repositories/` | 6 | Абстрактные контракты репозиториев |
| | `domain/usecases/` | 11 | Бизнес-сценарии (fail-fast валидация) |
| **Data** | `data/models/` | 6 | DTO-модели (@JsonSerializable + toDomain/fromDomain) |
| | `data/datasources/remote/` | 7 | Dio-источники данных (API-вызовы) |
| | `data/datasources/local/` | 1 | Локальный источник (SharedPreferences кэш сессии) |
| | `data/repositories/` | 6 | Реализации репозиториев |
| | `data/local/` | 1 | StorageService (SharedPreferences обёртка) |
| **Presentation** | `presentation/providers/` | 6 | Riverpod провайдеры (DI-цепочки) |
| | `presentation/screens/` | 8 экранов + 7 ViewModels | Экраны приложения |
| | `presentation/widgets/` | 1 | BottomNavigationBar |
| | `presentation/router/` | 1 | go_router конфигурация |
| **Core** | `core/constants/` | 3 | API-базы, роуты, тема |
| | `core/errors/` | 2 | Failure-иерархия, DioExceptionMapper |
| | `core/utils/` | 3 | Форматирование дат, валюты, валидаторы |
| | `core/widgets/` | 4 | Общие виджеты (empty, error, loading, service card) |
| | `main.dart` | 1 | Точка входа, ProviderScope |
| **Итого** | | **~60 файлов** | |

---

## Структура проекта

```
lib/
├── main.dart                                  # Точка входа, ProviderScope, Material3 тема
│
├── core/                                      # Общие утилиты и фреймворк
│   ├── constants/
│   │   ├── app_constants.dart                 # API-база, таймауты, ключи авторизации
│   │   ├── routes.dart                        # Константы имён роутов
│   │   └── themes.dart                        # Цвета (#F37021), стили текста, отступы
│   ├── errors/
│   │   ├── failures.dart                      # Sealed Failure: Network, Server, Validation, Cache, Unknown
│   │   └── exceptions.dart                    # DioExceptionMapper → Failure
│   ├── utils/
│   │   ├── date_formatter.dart                # «11 августа 2025» (русская локаль)
│   │   ├── currency_formatter.dart            # «112,50 ₽» через intl
│   │   └── validators.dart                    # Валидация ПИН (6 цифр), пароль (мин. 6 символов)
│   └── widgets/
│       ├── empty_state.dart                   # Пустое состояние с иконкой и текстом
│       ├── error_state.dart                   # Ошибка с кнопкой повтора
│       ├── loading_spinner.dart               # Индикатор загрузки
│       └── service_card.dart                  # Карточка услуги (иконка, название, стоимость, статус)
│
├── domain/                                    # DOMAIN LAYER — чистая бизнес-логика (без Flutter)
│   ├── entities/                              # Сущности — freezed POCO
│   │   ├── user.dart                          # Пользователь (ПИН, ФИО, телефон, аватар)
│   │   ├── balance.dart                       # Баланс (сумма, валюта, оплачено до, флаг isPaid)
│   │   ├── service.dart                       # Услуга (название, категория, стоимость, статус)
│   │   ├── transaction.dart                   # Транзакция (тип, сумма, описание, дата, статус)
│   │   ├── news_item.dart                     # Новость (заголовок, описание, теги, дата)
│   │   ├── support_ticket.dart                # Обращение (тема, описание, статус, ответы)
│   │   └── page.dart                          # Универсальная обёртка для пагинации Page<T>
│   ├── repositories/                          # Абстрактные контракты (Either<Failure, T>)
│   │   ├── user_repository.dart               # getCurrentUser, login, updateProfile
│   │   ├── balance_repository.dart            # getBalance, topUp
│   │   ├── service_repository.dart            # getActiveServices, getServiceDetails, renewService
│   │   ├── transaction_repository.dart        # getHistory(page, limit), getTransactionDetails
│   │   ├── news_repository.dart               # getNewsList, getNewsById
│   │   └── support_repository.dart            # createTicket, getMyTickets, getTicketDetails
│   └── usecases/                              # Бизнес-сценарии (fail-fast валидация)
│       ├── auth/
│       │   ├── login_usecase.dart              # Вход по ПИН + пароль
│       │   └── get_current_user_usecase.dart   # Получение текущего пользователя
│       ├── balance/
│       │   ├── get_balance_usecase.dart        # Запрос баланса
│       │   └── top_up_usecase.dart             # Пополнение (валидация amount > 0)
│       ├── services/
│       │   ├── get_active_services_usecase.dart  # Список активных услуг
│       │   └── get_service_details_usecase.dart  # Детали услуги (валидация id)
│       ├── transactions/
│       │   ├── get_transaction_history_usecase.dart  # Пагинированная история
│       │   └── get_transaction_details_usecase.dart  # Детали транзакции
│       ├── news/
│       │   ├── get_news_list_usecase.dart      # Список новостей
│       │   └── get_news_by_id_usecase.dart     # Детали новости (валидация id)
│       └── support/
│           └── create_ticket_usecase.dart      # Создание тикета (валидация полей)
│
├── data/                                      # DATA LAYER — маппинг, кэш, сетевые запросы
│   ├── local/
│   │   └── storage_service.dart               # SharedPreferences обёртка (init, get, set, remove, clear)
│   ├── models/                                # DTO-модели (freezed + @JsonSerializable)
│   │   ├── user_model.dart                    # ↔ User entity, toDomain/fromDomain
│   │   ├── balance_model.dart                 # ↔ Balance entity, toDomain/fromDomain
│   │   ├── service_model.dart                 # ↔ Service entity, enum mapping
│   │   ├── transaction_model.dart             # ↔ Transaction entity, enum mapping
│   │   ├── news_model.dart                    # ↔ NewsItem entity, toDomain/fromDomain
│   │   └── support_ticket_model.dart          # ↔ SupportTicket entity, enum mapping
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── api_client.dart                # Dio singleton с interceptors (auth, error)
│   │   │   ├── user_remote_source.dart        # getUserProfile, login
│   │   │   ├── balance_remote_source.dart     # getBalance, topUp
│   │   │   ├── service_remote_source.dart     # getActiveServices
│   │   │   ├── transaction_remote_source.dart # getTransactionHistory
│   │   │   ├── news_remote_source.dart        # getNewsList, getNewsById
│   │   │   └── support_remote_source.dart     # createTicket, getMyTickets
│   │   └── local/
│   │       └── user_local_source.dart          # Кэш сессии: токен, пользователь
│   └── repositories/                          # Реализации контрактов Domain
│       ├── user_repository_impl.dart          # login → remote + save session, getCurrentUser → cache first
│       ├── balance_repository_impl.dart       # getBalance/topUp → remote
│       ├── service_repository_impl.dart       # getActiveServices/getDetails/renew → remote
│       ├── transaction_repository_impl.dart   # getHistory → flat list → Page<T>
│       ├── news_repository_impl.dart          # getNewsList → Page<T>, getNewsById
│       └── support_repository_impl.dart       # createTicket, getMyTickets, getTicketDetails
│
└── presentation/                              # PRESENTATION LAYER — UI + State
    ├── providers/                             # Riverpod провайдеры (DI-цепочки)
    │   ├── auth_provider.dart                 # StateNotifierProvider: login, logout, checkAuth
    │   ├── balance_provider.dart              # FutureProvider: баланс + topUp
    │   ├── services_provider.dart              # FutureProvider: список услуг
    │   ├── transactions_provider.dart          # FutureProvider: история (refresh counter)
    │   ├── news_provider.dart                  # FutureProvider: новости + деталь (refresh counter)
    │   └── support_provider.dart               # FutureProvider.family: создание тикета
    ├── screens/
    │   ├── login/
    │   │   ├── login_screen.dart              # Экран авторизации (ПИН + пароль)
    │   │   └── login_view_model.dart          # LoginFormState sealed (initial/submitting/error/success)
    │   ├── home/
    │   │   ├── home_screen.dart                # Главная: аватар, баланс, услуги
    │   │   └── home_view_model.dart            # HomeState sealed (initial/loading/loaded/error/empty)
    │   ├── top_up/
    │   │   ├── top_up_screen.dart              # Пополнение: быстрые суммы + ввод
    │   │   └── top_up_view_model.dart          # TopUpState: selectedAmount, isSubmitting, result
    │   ├── history/
    │   │   ├── history_screen.dart             # История транзакций
    │   │   └── history_view_model.dart         # HistoryState sealed
    │   ├── payment/
    │   │   ├── payment_screen.dart             # Оплата: быстрые действия + транзакции
    │   │   └── payment_view_model.dart         # PaymentState sealed
    │   ├── news/
    │   │   ├── news_screen.dart                # Список новостей
    │   │   ├── news_detail_screen.dart         # Детали новости
    │   │   └── news_view_model.dart            # NewsListState sealed
    │   └── support/
    │       ├── support_screen.dart             # Форма обращения + FAQ
    │       └── support_view_model.dart         # SupportFormState sealed
    ├── widgets/
    │   └── navigation/
    │       └── bottom_nav_bar.dart             # 4 таба: Главная · Оплата · Новости · Поддержка
    └── router/
        └── app_router.dart                     # go_router с ShellRoute и auth guard
```

---

## Быстрый старт (локальный запуск)

### 1. Установка Flutter SDK

Установите Flutter SDK версии **3.22+**:

| Платформа | Ссылка |
|-----------|--------|
| **Windows** | https://docs.flutter.dev/get-started/install/windows |
| **macOS** | https://docs.flutter.dev/get-started/install/macos |
| **Linux** | https://docs.flutter.dev/get-started/install/linux/desktop |

После установки проверьте:

```bash
flutter doctor
```

Убедитесь, что в выводе:
- ✅ `Flutter 3.22.x` (или новее)
- ✅ `Dart 3.2.x` (или новее)
- ✅ Подключено устройство или запущен эмулятор

### 2. Клонирование репозитория

```bash
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk/flutter
```

### 3. Установка зависимостей

```bash
flutter pub get
```

### 4. Генерация кода (ОБЯЗАТЕЛЬНЫЙ ШАГ)

Проект использует **freezed** и **json_serializable** для генерации:
- `.freezed.dart` — immutable-классы, `copyWith`, `union`-типы, `toString`, `==`
- `.g.dart` — `fromJson`/`toJson` для сериализации

**Обязательно выполните перед первым запуском:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Зачем?** Без этих файлов компиляция не пройдёт — entity и model импортируют сгенерированные классы.

**При изменении entity/model** (добавление полей, новых сущностей) — запустите команду заново.

**Альтернатива с автоматической перегенерацией при сохранении:**

```bash
dart run build_runner watch
```

### 5. Запуск мок-API сервера

Flutter-приложение зависит от Next.js мок-API по адресу `http://localhost:3000/api`.

В **родительской папке** проекта:

```bash
cd ..
bun install
bun run dev
```

> **Примечание:** При необходимости API можно заменить на реальный бэкенд — для этого
> измените `apiBaseUrl` в `lib/core/constants/app_constants.dart`.

> **Важно для Android-эмулятора:** В эмуляторе `localhost` недоступен.
> Используйте `http://10.0.2.2:3000/api` вместо `http://localhost:3000/api`.

### 6. Запуск приложения

```bash
# На эмуляторе или подключённом устройстве
cd flutter
flutter run

# В Chrome (web-версия)
flutter run -d chrome

# Список доступных устройств
flutter devices

# Запуск на конкретном устройстве
flutter run -d <device_id>
```

### 7. Тестовые данные для входа

| Поле | Значение |
|------|----------|
| **ПИН** | `039103` |
| **Пароль** | `123456` |

---

## Экраны приложения

| # | Экран | Описание |
|---|-------|----------|
| 1 | **Авторизация** (`/login`) | Ввод ПИН-кода (6 цифр) и пароля. Валидация на клиенте. Ссылка на поддержку без авторизации |
| 2 | **Главная** (`/`) | Аватар с инициалами, ПИН, ФИО, баланс (112,50 ₽), дата оплаты, кнопки «Пополнить» и «История», карточки активных услуг. Pull-to-refresh |
| 3 | **Пополнение** (`/top_up`) | Сетка быстрых сумм (100–5000 ₽) + произвольный ввод. Кнопка «Пополнить». SnackBar при успехе |
| 4 | **История** (`/history`) | Список транзакций с цветовой индикацией (зелёный — начисление, красный — списание). Pull-to-refresh |
| 5 | **Оплата** (`/payment`) | 4 быстрых действия (Оплата услуг, Перевод, Привязать карту, Промокод) + недавние транзакции |
| 6 | **Новости** (`/news`) | Лента новостей с датами и количеством прочтений. Pull-to-refresh |
| 7 | **Детали новости** (`/news/:id`) | Заголовок, дата, теги (chips), изображение, полное описание |
| 8 | **Поддержка** (`/support`) | Форма создания обращения (тема + описание) + FAQ-аккордеон (3 вопроса). Доступна без авторизации |

**Нижняя навигация:** 4 таба — **Главная** · **Оплата** · **Новости** · **Поддержка**

---

## API эндпоинты

Приложение обращается к 6 REST API эндпоинтам Next.js мок-сервера:

| # | Метод | Эндпоинт | Описание | Используется в |
|---|-------|----------|----------|---------------|
| 1 | `POST` | `/api/auth/login` | Авторизация по ПИН + пароль | LoginScreen |
| 2 | `GET` | `/api/account/profile` | Профиль пользователя, баланс, услуги | HomeScreen |
| 3 | `GET` | `/api/transactions` | История транзакций | HistoryScreen, PaymentScreen |
| 4 | `GET` | `/api/news` | Лента новостей | NewsScreen |
| 5 | `GET` | `/api/support` | Список обращений в поддержку | SupportScreen |
| 6 | `POST` | `/api/top-up` | Пополнение баланса | TopUpScreen |

### Примеры запросов и ответов

#### POST /api/auth/login

**Запрос:**
```json
{
  "pin": "039103",
  "password": "123456"
}
```

**Ответ (200):**
```json
{
  "token": "mock-jwt-token-xyz",
  "user": {
    "pin": "039103",
    "fullName": "Примеров-Заде П.",
    "phone": "+7 (999) 123-45-67"
  }
}
```

**Ошибка (401):**
```json
{
  "error": "Invalid credentials"
}
```

#### GET /api/account/profile

**Ответ (200):**
```json
{
  "user": {
    "pin": "039103",
    "fullName": "Примеров-Заде П.",
    "phone": "+7 (999) 123-45-67",
    "avatarUrl": null
  },
  "balance": {
    "amount": 112.50,
    "currency": "RUB",
    "paidUntil": "2025-08-11T00:00:00Z",
    "isPaid": true
  },
  "activeServices": [
    {
      "id": "svc-1",
      "name": "100/100 30 day 250 руб",
      "category": "Интернет",
      "cost": 225.00,
      "status": "active"
    }
  ]
}
```

#### GET /api/transactions

**Ответ (200):**
```json
[
  {
    "id": "tx-1",
    "type": "payment",
    "amount": 225.00,
    "description": "Оплата интернета",
    "date": "2025-07-10T12:00:00Z",
    "status": "success"
  }
]
```

#### POST /api/top-up

**Запрос:**
```json
{
  "amount": 500
}
```

**Ответ (200):**
```json
{
  "newBalance": 612.50
}
```

---

## Доменные сущности

Все сущности — `freezed`-классы без внешних зависимостей (чистый Dart POCO).

### User

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | ПИН-код (например, `039103`) |
| `fullName` | `String` | ФИО клиента |
| `phone` | `String?` | Номер телефона |
| `avatarUrl` | `String?` | URL аватара |
| `createdAt` | `DateTime` | Дата регистрации |

### Balance

| Поле | Тип | Описание |
|------|-----|----------|
| `amount` | `double` | Текущий баланс (например, `112.50`) |
| `currency` | `String` | Код валюты (`RUB`) |
| `paidUntil` | `DateTime?` | Дата, до которой оплачены услуги |
| `isPaid` | `bool` | Производное от `paidUntil` (оплачено ли) |
| `lastUpdated` | `DateTime` | Время последнего обновления |

### Service

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный идентификатор |
| `name` | `String` | Название услуги |
| `category` | `String` | Категория (Интернет, ТВ, Телефония) |
| `cost` | `double` | Стоимость |
| `status` | `ServiceStatus` | `active` · `expired` · `paused` · `error` |
| `iconUrl` | `String?` | URL иконки |
| `warningMessage` | `String?` | Маркер проблемы |
| `billingCycle` | `String?` | Расчётный период (например, `30 days`) |

### Transaction

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный идентификатор |
| `type` | `TransactionType` | `topUp` · `payment` · `refund` · `bonus` |
| `amount` | `double` | Сумма |
| `description` | `String` | Описание операции |
| `date` | `DateTime` | Дата операции |
| `status` | `TransactionStatus` | `success` · `pending` · `failed` |
| `relatedServiceId` | `String?` | ID связанной услуги |

### NewsItem

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный идентификатор |
| `title` | `String` | Заголовок |
| `summary` | `String` | Краткое описание |
| `imageUrl` | `String?` | URL изображения |
| `publishedAt` | `DateTime` | Дата публикации |
| `readCount` | `int?` | Количество прочтений |
| `tags` | `List<String>` | Теги |

### SupportTicket

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный идентификатор |
| `subject` | `String` | Тема обращения |
| `description` | `String` | Описание |
| `status` | `TicketStatus` | `open` · `inProgress` · `resolved` · `closed` |
| `createdAt` | `DateTime` | Дата создания |
| `replyCount` | `int` | Количество ответов |

---

## Схема зависимостей (Dependency Injection)

**Riverpod** связывает все слои через цепочку провайдеров.
Каждый провайдер зависит от предыдущего уровня через `ref.read()`:

```
StorageService (SharedPreferences)          ← override в main.dart
       ↓
ApiClient (Dio + interceptors)             ← Provider, singleton
       ↓
RemoteDataSource (Dio-вызовы API)           ← Provider для каждого источника
       ↓
RepositoryImpl (implements Domain Repo)     ← Provider, маппит DTO → Entity
       ↓
UseCase (бизнес-логика + валидация)          ← Provider для каждого сценария
       ↓
StateNotifier / FutureProvider (состояние)  ← Provider, используется в UI
       ↓
Screen (ConsumerWidget)                     ← ref.watch() / ref.read()
```

**Паттерн для каждого фичи:**

```
Provider (StorageService / ApiClient)
  → RemoteSource (сетевые запросы)
    → RepositoryImpl (маппинг DTO ↔ Entity, обработка ошибок)
      → UseCase (бизнес-правила, fail-fast валидация)
        → Provider (FutureProvider / StateNotifierProvider)
          → Screen (ConsumerWidget)
```

**Пример (баланс):**

```dart
// 1. Remote Source
final balanceRemoteSourceProvider = Provider((ref) => BalanceRemoteSource(ref.read(apiClientProvider)));

// 2. Repository
final balanceRepositoryProvider = Provider((ref) => BalanceRepositoryImpl(ref.read(balanceRemoteSourceProvider)));

// 3. Use Case
final getBalanceUseCaseProvider = Provider((ref) => GetBalanceUseCase(ref.read(balanceRepositoryProvider)));

// 4. UI Provider
final balanceProvider = FutureProvider<Balance>((ref) async {
  final useCase = ref.read(getBalanceUseCaseProvider);
  final result = await useCase.call();
  return result.fold((l) => throw l, (r) => r);
});
```

---

## Обработка ошибок

### Failure — sealed hierarchy

```
Failure (sealed, @Freezed(unionKey: 'type'))
├── NetworkFailure        — нет соединения, timeout, DNS-ошибка
├── ServerFailure         — HTTP 4xx/5xx, содержит status и message
├── ValidationFailure     — ошибка валидации ввода (ПИН, пароль, сумма)
├── CacheFailure          — ошибка чтения/записи из SharedPreferences
└── UnknownFailure        — непредвиденная ошибка (fallback)
```

### DioExceptionMapper

`core/errors/exceptions.dart` содержит `DioExceptionMapper`, который преобразует
все типы `DioException` в соответствующие `Failure`:

| DioExceptionType | → Failure | Описание |
|------------------|-----------|----------|
| `connectionTimeout` | `NetworkFailure` | Таймаут соединения |
| `sendTimeout` | `NetworkFailure` | Таймаут отправки |
| `receiveTimeout` | `NetworkFailure` | Таймаут ответа |
| `connectionError` | `NetworkFailure` | Нет сети |
| `badResponse` (4xx) | `ServerFailure` / `ValidationFailure` | Ошибка клиента |
| `badResponse` (5xx) | `ServerFailure` | Ошибка сервера |
| `cancel` | `NetworkFailure` | Запрос отменён |
| *остальное* | `UnknownFailure` | Непредвиденное |

### Отображение ошибок в UI

Все экраны используют виджет `ErrorState` из `core/widgets/error_state.dart`,
который принимает текст ошибки и callback для повтора:

```
ErrorState(message: "Не удалось загрузить данные", onRetry: () => ref.refresh(provider))
```

---

## Сборка релизных версий

### APK (Android)

```bash
cd flutter
flutter build apk --release
```

> **Файл:** `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Android, для Google Play)

```bash
flutter build appbundle --release
```

> **Файл:** `build/app/outputs/bundle/release/app-release.aab`

### iOS (только на macOS)

```bash
flutter build ios --release
```

Затем:
1. Откройте `ios/Runner.xcworkspace` в **Xcode**
2. Выберите **Generic iOS Device**
3. **Product → Archive**
4. **Distribute App → App Store Connect** или **Ad Hoc**

---

## Публикация в магазинах

### Google Play Store

1. **Зарегистрируйтесь** в [Google Play Console](https://play.google.com/console) (разовый платёж **$25**)
2. **Создайте приложение** — заполните название, описание, скриншоты
3. **Загрузите AAB** — `flutter build appbundle --release` → загрузить в Release-трек
4. **Контент-рейтинг** — укажите целевую аудиторию
5. **Ревью** — обычно 1–3 дня

> Ссылки: [Play Console](https://play.google.com/console) · [Android Studio](https://developer.android.com/studio)

### App Store (iOS)

1. **Apple Developer Program** — [$99/год](https://developer.apple.com/programs/)
2. **Сертификаты и профили** — настройте через Xcode → Signing & Capabilities
3. **Сборка через Xcode** — Archive → Upload to App Store Connect
4. **TestFlight** — внутреннее и внешнее бета-тестирование
5. **Отправка на ревью** — App Store Connect → Submit for Review (1–7 дней)

> Ссылки: [App Store Connect](https://appstoreconnect.apple.com)

---

## CI/CD (GitHub Actions)

### Android (сборка APK по тегу)

```yaml
# .github/workflows/android.yml
name: Build Android APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: cd flutter && flutter pub get

      - name: Generate code (freezed + json_serializable)
        run: cd flutter && dart run build_runner build --delete-conflicting-outputs

      - name: Build APK
        run: cd flutter && flutter build apk --release

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: flutter/build/app/outputs/flutter-apk/app-release.apk
```

### iOS (сборка через macOS runner)

```yaml
# .github/workflows/ios.yml
name: Build iOS

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: cd flutter && flutter pub get

      - name: Generate code (freezed + json_serializable)
        run: cd flutter && dart run build_runner build --delete-conflicting-outputs

      - name: Build iOS (no codesign)
        run: cd flutter && flutter build ios --release --no-codesign

      - name: Upload iOS artifact
        uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: flutter/build/ios/iphoneos/Runner.app
```

---

## Возможные проблемы и решения

| Проблема | Решение |
|----------|----------|
| **`build_runner` не генерирует файлы** | Запустите с флагом `--delete-conflicting-outputs`: `dart run build_runner build --delete-conflicting-outputs` |
| **`Cannot run with sound null safety`** | Обновите Flutter SDK до 3.22+ (`flutter upgrade`) и убедитесь, что все зависимости поддерживают null safety |
| **API недоступен** | Проверьте, что Next.js сервер запущен: `curl http://localhost:3000/api/account/profile`. Запустите: `cd .. && bun run dev` |
| **Android эмулятор не видит `localhost`** | Используйте `10.0.2.2` вместо `localhost` в `app_constants.dart`: `apiBaseUrl = 'http://10.0.2.2:3000/api'` |
| **`Invalid annotation target` warning** | Игнорируется — это известная проблема совместимости freezed + analyzer. Уже добавлено в `analysis_options.yaml`: `invalid_annotation_target: ignore` |
| **Ошибки импорта `.freezed.dart` / `.g.dart`** | Сначала выполните `dart run build_runner build --delete-conflicting-outputs` для генерации файлов |
| **Белый экран после запуска** | Проверьте логи через `flutter run` в терминале. Возможная причина: несоответствие версий пакетов — `flutter clean && flutter pub get` |

---

## Лицензия

MIT
