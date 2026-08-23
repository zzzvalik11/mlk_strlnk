# Starlink — Личный кабинет абонента

Мобильное приложение **«Личный кабинет телеком-абонента»** (Starlink).

Стек: **Flutter 3.x · Dart 3.13+ · Riverpod · Dio · Freezed 4.x · GoRouter · fpdart**

Архитектура: **Clean Architecture** (Domain ← Data / Presentation)

---

## Возможности

- Авторизация по ПИН + пароль
- Биометрическая повторная авторизация (отпечаток пальца)
- Блокировка приложения с кнопки-замка
- Главная: баланс, оплачено до, активные услуги
- Пополнение баланса
- История операций
- Лента новостей с детальным просмотром
- Обращения в техподдержку
- Выбор метода авторизации при первом входе
- Настройки: смена метода авторизации

---

## Тестовый пользователь

| Параметр | Значение |
|----------|----------|
| ПИН | `039103` |
| Пароль | `123456` |

> Для ПИН `039103` / пароль `123456` используются **моковые данные** — сервер не требуется.
> Для всех остальных пользователей выполняются реальные HTTP-запросы к API.

---

## Стек технологий

| Категория | Технология |
|-----------|------------|
| Фреймворк | Flutter 3.x (Dart 3.13+) |
| State Management | Riverpod (flutter_riverpod) |
| Роутинг | GoRouter |
| Сеть | Dio |
| Сериализация | Freezed 4.x + json_serializable |
| Функциональные типы | fpdart (Either) |
| Локальное хранилище | SharedPreferences |
| Локализация | flutter_localizations + intl |
| Биометрия | local_auth |

---

## Структура проекта

```
lib/
├── main.dart
├── core/
│   ├── constants/          # API-бейзы, ключи, роуты, тема
│   ├── errors/             # Failure (sealed), DioExceptionMapper
│   ├── utils/              # Валидаторы, форматтеры
│   └── widgets/            # Общие виджеты
├── domain/                 # Чистая бизнес-логика (без зависимостей)
│   ├── entities/           # Freezed sealed-классы
│   ├── repositories/       # Абстрактные контракты
│   └── usecases/           # Бизнес-сценарии
├── data/
│   ├── models/             # DTO (Freezed sealed + extension для маппинга)
│   ├── datasources/
│   │   ├── remote/         # Dio-based API
│   │   └── local/          # SharedPreferences кэш
│   ├── repositories/       # Impl domain-контрактов
│   └── local/              # StorageService
└── presentation/
    ├── providers/          # Riverpod Providers
    ├── screens/            # Экраны + ViewModels
    ├── widgets/navigation/
    └── router/             # GoRouter + auth redirect
```

---

## Быстрый старт

### Требования

- Flutter >= 3.22.0 (Dart >= 3.8.0)
- Android Studio или VS Code с Flutter-плагином

### Установка

```bash
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk

# 1. Зависимости
flutter pub get

# 2. Сгенерировать код (Freezed + json_serializable)
flutter pub run build_runner build

# 3. Запуск
flutter run
```

---

## Архитектура

```
┌──────────────────────────────────────────────┐
│           Presentation Layer                  │
│  Screens (ConsumerStatefulWidget)            │
│  ViewModels (StateNotifier)                  │
│  Providers (Riverpod)                        │
│  Router (GoRouter + auth redirect)           │
├──────────────────────────────────────────────┤
│             Domain Layer                      │
│  Entities (Freezed sealed class)             │
│  Repository Contracts (abstract class)       │
│  UseCases (business scenarios)               │
│  Failures (sealed hierarchy)                 │
├──────────────────────────────────────────────┤
│              Data Layer                       │
│  Models (DTO, Freezed sealed + extensions)   │
│  Remote Sources (Dio)                        │
│  Local Sources (SharedPreferences)           │
│  Repository Implementations                  │
└──────────────────────────────────────────────┘

Dependency Rule: presentation → domain ← data
```

---

## Полезные команды

```bash
# Статический анализ
flutter analyze

# Форматирование
dart format lib/

# Перегенерировать код
flutter pub run build_runner build

# Watch-режим
flutter pub run build_runner watch
```

---

## Лицензия

MIT
