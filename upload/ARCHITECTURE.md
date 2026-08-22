# Architecture Plan — Telecom Dashboard (Flutter)

> **Stack:** Flutter 3.x · Dart 3.x · Riverpod (State Management) · Dio (Networking) · Freezed + json_serializable (Serialization)
> **Style:** Clean Architecture (Domain ← Data / Presentation)

---

## 1. Folder Structure (`lib/`)

```
lib/
├── main.dart                          # Точка входа, ProviderScope, Bootstrap
│
├── core/                              # Общие утилиты и фреймворк
│   ├── constants/
│   │   ├── app_constants.dart         # API-бейзы, ключи, лимиты
│   │   ├── routes.dart                # Имена роутов
│   │   └── themes.dart                # Цвета, шрифты, стили
│   ├── errors/
│   │   ├── failures.dart              # sealed-класс Failure (NetworkFailure, ServerFailure, CacheFailure…)
│   │   └── exceptions.dart            # DioExceptionMapper → Failure
│   ├── utils/
│   │   ├── date_formatter.dart
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── widgets/
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── loading_spinner.dart
│       └── service_card.dart          # Карточка услуги (общий виджет)
│
├── data/                              # Data Layer
│   ├── local/
│   │   └── storage_service.dart       # SharedPreferences / Hive кэш
│   ├── models/                        # DTO-модели (json_serializable)
│   │   ├── user_model.dart            # ↔ User (domain)
│   │   ├── balance_model.dart         # ↔ Balance (domain)
│   │   ├── service_model.dart         # ↔ Service (domain)
│   │   ├── transaction_model.dart     # ↔ Transaction (domain)
│   │   ├── news_model.dart            # ↔ NewsItem (domain)
│   │   └── support_ticket_model.dart  # ↔ SupportTicket (domain)
│   ├── repositories/                  # Реализации контрактов из Domain
│   │   ├── user_repository_impl.dart
│   │   ├── balance_repository_impl.dart
│   │   ├── service_repository_impl.dart
│   │   ├── transaction_repository_impl.dart
│   │   ├── news_repository_impl.dart
│   │   └── support_repository_impl.dart
│   └── datasources/
│       ├── remote/
│       │   ├── api_client.dart         # Dio-клиент (interceptors: auth, error mapping)
│       │   ├── user_remote_source.dart
│       │   ├── balance_remote_source.dart
│       │   ├── service_remote_source.dart
│       │   ├── transaction_remote_source.dart
│       │   ├── news_remote_source.dart
│       │   └── support_remote_source.dart
│       └── local/
│           └── user_local_source.dart  # SharedPreferences-кэш сессии
│
├── domain/                            # Domain Layer (чистая бизнес-логика)
│   ├── entities/                      # Сущности — POCO, без зависимостей
│   │   ├── user.dart
│   │   ├── balance.dart
│   │   ├── service.dart
│   │   ├── transaction.dart
│   │   ├── news_item.dart
│   │   └── support_ticket.dart
│   ├── repositories/                  # Контракты (abstract-классы)
│   │   ├── user_repository.dart
│   │   ├── balance_repository.dart
│   │   ├── service_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── news_repository.dart
│   │   └── support_repository.dart
│   └── usecases/                      # Интерпретированные бизнес-сценарии
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── get_current_user_usecase.dart
│       ├── balance/
│       │   ├── get_balance_usecase.dart
│       │   └── top_up_usecase.dart
│       ├── services/
│       │   ├── get_active_services_usecase.dart
│       │   └── get_service_details_usecase.dart
│       ├── transactions/
│       │   ├── get_transaction_history_usecase.dart
│       │   └── get_transaction_details_usecase.dart
│       ├── news/
│       │   ├── get_news_list_usecase.dart
│       │   └── get_news_by_id_usecase.dart
│       └── support/
│           └── create_ticket_usecase.dart
│
└── presentation/                      # Presentation Layer (UI + State)
    ├── providers/                     # Riverpod Providers
    │   ├── auth_provider.dart
    │   ├── balance_provider.dart
    │   ├── services_provider.dart
    │   ├── transactions_provider.dart
    │   ├── news_provider.dart
    │   └── support_provider.dart
    ├── screens/
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── home_view_model.dart   # StateNotifierProvider для HomeScreen
    │   ├── top_up/
    │   │   ├── top_up_screen.dart
    │   │   └── top_up_view_model.dart
    │   ├── history/
    │   │   ├── history_screen.dart
    │   │   └── history_view_model.dart
    │   ├── payment/
    │   │   ├── payment_screen.dart
    │   │   └── payment_view_model.dart
    │   ├── news/
    │   │   ├── news_screen.dart
    │   │   ├── news_detail_screen.dart
    │   │   └── news_view_model.dart
    │   └── support/
    │       ├── support_screen.dart
    │       └── support_view_model.dart
    ├── widgets/                       # Экранно-специфичные виджеты
    │   └── navigation/
    │       └── bottom_nav_bar.dart     # 4 таба: Главная · Оплата · Новости · Поддержка
    └── router/
        └── app_router.dart            # go_router конфигурация
```

---

## 2. Domain Entities

Каждая сущность — `freezed`-класс с `@JsonKey`-аннотациями.

### 2.1 `User` (ПИН, имя клиента)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | ПИН (039103) |
| `fullName` | `String` | Примеров-Заде П. |
| `phone` | `String?` | Номер телефона |
| `avatarUrl` | `String?` | URL аватара |
| `createdAt` | `DateTime` | Дата регистрации |

### 2.2 `Balance` (баланс и статус оплаты)

| Поле | Тип | Описание |
|------|-----|----------|
| `amount` | `double` | 112.5 |
| `currency` | `String` | "RUB" |
| `paidUntil` | `DateTime?` | "до 11 августа" |
| `isPaid` | `bool` | derived from paidUntil |
| `lastUpdated` | `DateTime` | Время последнего обновления |

### 2.3 `Service` (активная услуга)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный ID |
| `name` | `String` | "100/100 30 day 250 руб" |
| `category` | `String` | "Интернет" |
| `cost` | `double` | 225.0 |
| `status` | `ServiceStatus` | active · expired · paused · error |
| `iconUrl` | `String?` | URL иконки |
| `warningMessage` | `String?` | "!" — маркер проблемы |
| `billingCycle` | `String?` | "30 days" |

### 2.4 `Transaction` (операция в истории)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный ID |
| `type` | `TransactionType` | topUp · payment · refund · bonus |
| `amount` | `double` | Сумма |
| `description` | `String` | Описание |
| `date` | `DateTime` | Дата |
| `status` | `TransactionStatus` | success · pending · failed |
| `relatedServiceId` | `String?` | ID связанной услуги |

### 2.5 `NewsItem` (новости)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный ID |
| `title` | `String` | Заголовок |
| `summary` | `String` | Краткое описание |
| `imageUrl` | `String?` | URL изображения |
| `publishedAt` | `DateTime` | Дата публикации |
| `readCount` | `int?` | Количество прочтений |
| `tags` | `List<String>` | Теги |

### 2.6 `SupportTicket` (обращение в поддержку)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | `String` | Уникальный ID |
| `subject` | `String` | Тема |
| `description` | `String` | Описание |
| `status` | `TicketStatus` | open · inProgress · resolved · closed |
| `createdAt` | `DateTime` | Дата создания |
| `replyCount` | `int` | Количество ответов |

---

## 3. Repository Contracts

Каждый `Repository` — `abstract class`, возвращающий `Either<Failure, T>`.

### 3.1 `UserRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `getCurrentUser()` | `Future<Either<Failure, User>>` | Получить данные текущего клиента (ПИН, ФИО) |
| `login(pin)` | `Future<Either<Failure, User>>` | Авторизация по ПИН |
| `updateProfile(profile)` | `Future<Either<Failure, User>>` | Обновить профиль |

### 3.2 `BalanceRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `getBalance()` | `Future<Either<Failure, Balance>>` | Текущий баланс и дата окончания оплаты |
| `topUp(amount, method)` | `Future<Either<Failure, Balance>>` | Пополнение баланса |

### 3.3 `ServiceRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `getActiveServices()` | `Future<Either<Failure, List<Service>>>` | Список активных услуг |
| `getServiceDetails(id)` | `Future<Either<Failure, Service>>` | Детали конкретной услуги |
| `renewService(id)` | `Future<Either<Failure, Service>>` | Продлить услугу |

### 3.4 `TransactionRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `getHistory(page, limit)` | `Future<Either<Failure, Page<Transaction>>>` | Paginated история |
| `getTransactionDetails(id)` | `Future<Either<Failure, Transaction>>` | Детали операции |

### 3.5 `NewsRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `getNewsList(page, limit)` | `Future<Either<Failure, Page<NewsItem>>>` | Paginated список |
| `getNewsById(id)` | `Future<Either<Failure, NewsItem>>` | Детали новости |

### 3.6 `SupportRepository`

| Метод | Подпись | Описание |
|-------|---------|----------|
| `createTicket(subject, description)` | `Future<Either<Failure, SupportTicket>>` | Создать обращение |
| `getMyTickets()` | `Future<Either<Failure, List<SupportTicket>>>` | Мои обращения |
| `getTicketDetails(id)` | `Future<Either<Failure, SupportTicket>>` | Детали обращения |

---

## 4. Data Layer Implementation

### 4.1 API Client (`Dio`)

```
ApiClient
├── dio: Dio                           // singleton, baseOptions (baseUrl, headers)
├── authInterceptor                    // Bearer-токен из SharedPreferences
├── errorInterceptor                   // DioException → Failure (mapped)
├── cacheInterceptor                   // кэш GET-запросов (TTL)
└── methods:
    ├── get<T>(path, query) → Response<T>
    ├── post<T>(path, body) → Response<T>
    ├── put<T>(path, body) → Response<T>
    └── postMultipart(path, files) → Response<T>
```

### 4.2 Models (DTO ↔ Entity)

```
data/models/        @JsonSerializable()
       ↓ toDomain()
domain/entities/    pure freezed classes
```

Каждый `model.dart` — `@freezed` + `@JsonSerializable()`, содержит методы `fromJson`/`toJson` и `toDomain()` для маппинга на чистую сущность.

### 4.3 Repository Implementation Pattern

```
DataRepositoryImpl (implements DomainRepository)
├── RemoteSource _remoteSource
├── LocalSource? _localSource  // optional cache
│
├── Future<Either<Failure, T>> getSomething()
│   1. Попытка из кэша (if _localSource != null)
│   2. Запрос к _remoteSource
│   3. Mapping RemoteModel → Domain Entity
│   4. Кэширование результата
│   5. return right(entity) / left(failure)
```

---

## 5. Presentation Layer (Riverpod)

### 5.1 Provider Hierarchy

```
ProviderContainer (app_level_provider)
├── authProvider                    — StateNotifierProvider
├── balanceProvider                 — FutureProvider
├── activeServicesProvider          — FutureProvider
├── transactionHistoryProvider      — FutureProvider.family
├── newsListProvider                — FutureProvider.family
└── topUpProvider                   — FutureProvider
```

### 5.2 Provider Types

| Provider | Тип | Назначение |
|----------|-----|------------|
| `authProvider` | `StateNotifierProvider` | Сессия входа/выхода, текущий User |
| `balanceProvider` | `FutureProvider` | Загрузка баланса (refresh on demand) |
| `activeServicesProvider` | `FutureProvider` | Список активных услуг |
| `transactionHistoryProvider` | `FutureProvider.family<String?>` | Paginated история |
| `newsListProvider` | `FutureProvider.family<int?>` | Paginated новости |
| `topUpProvider` | `FutureProvider` | Выполнение пополнения |

### 5.3 ViewModels (StateNotifier)

Каждый экран имеет `*_view_model.dart` — `StateNotifier<ScreenState>`, где:

```
ScreenState (freezed union)
├── initial
├── loading
├── loaded(T data)
├── error(String message)
└── empty
```

### 5.4 Navigation

`go_router` с экранами:

```
/                 → HomeScreen
/top_up           → TopUpScreen
/history          → HistoryScreen
/payment/:id      → PaymentScreen
/news             → NewsScreen
/news/:id         → NewsDetailScreen
/support          → SupportScreen
```

Нижняя навигация (4 таба): **Главная** · **Оплата** · **Новости** · **Поддержка**

---

## 6. Dependency Injection (Riverpod)

DI осуществляется через `Ref.watch()` / `Ref.read()` в провайдерах.

```dart
// Пример: баланс
final balanceRepositoryProvider = Provider((ref) => BalanceRepositoryImpl(
  remoteSource: ref.read(balanceRemoteSourceProvider),
  localSource: ref.read(balanceLocalSourceProvider),
));

final balanceProvider = FutureProvider<Balance>((ref) async {
  final repo = ref.read(balanceRepositoryProvider);
  final result = await repo.getBalance();
  return result.fold((l) => throw l, (r) => r);
});
```

Корневые провайдеры регистрируются в `main.dart` через `ProviderScope`:

```dart
runApp(
  ProviderScope(
    overrides: [
      // можно переопределить на mock при тестировании
    ],
    child: const MyApp(),
  ),
);
```

---

## 7. Error Handling Flow

```
DioException
    ↓ (errorInterceptor)
Failure (sealed hierarchy)
    ├── NetworkFailure          — нет соединения, timeout
    ├── ServerFailure(status, msg) — 4xx, 5xx
    ├── ValidationFailure       — валидация ввода
    └── UnknownFailure          — непредвиденное
    ↓ (mapper)
String message → shown in ErrorState widget
```

---

## 8. Screen Mapping from Screenshot

| Элемент скриншота | Экран | Provider | Repository | Entity |
|-------------------|-------|----------|------------|--------|
| ПИН xxxxxx, ФИО | HomeScreen | `authProvider` | `UserRepository` | `User` |
| Баланс 112.5 ₽ | HomeScreen | `balanceProvider` | `BalanceRepository` | `Balance` |
| "Оплачено до 11 августа" | HomeScreen | `balanceProvider` | `BalanceRepository` | `Balance` |
| Кнопка «Пополнить» | TopUpScreen | `topUpProvider` | `BalanceRepository` | `Balance` |
| Кнопка «История» | HistoryScreen | `transactionHistoryProvider` | `TransactionRepository` | `Transaction` |
| Активные услуги (карточка) | HomeScreen | `activeServicesProvider` | `ServiceRepository` | `Service` |
| Нижняя навигация (4 таба) | AppShell | — | — | — |

---

## 9. Key Principles

1. **Dependency Rule** — зависимости указывают внутрь: `presentation → domain`, `data → domain`. Domain не зависит ни от чего.
2. **One Responsibility per Layer** — Data: маппинг и кэш. Domain: бизнес-правила. Presentation: UI-логика.
3. **Immutable State** — все сущности и состояния через `freezed` (immutability + copyWith).
4. **Unidirectional Data Flow** — Events → State → UI.
5. **Testability** — Domain и Repository — абстракции, легко мокаются.
6. **No magic numbers** — все строковые константы (пути API, ключи) вынесены в `core/constants/`.
7. **Fail-fast** — валидация на входе каждого UseCase, ранний возврат `left(failure)`.