# Telecom Dashboard

Мобильное веб-приложение **«Личный кабинет телеком-абонента»** с дашбордом, пополнением баланса, историей операций, новостями и поддержкой.

Приложение разработано по архитектуре Clean Architecture (Domain / Data / Presentation) и повторяет UI мобильного приложения телеком-оператора с максимальной точностью.

---

## Скриншоты

| Экран | Описание |
|-------|----------|
| Главная | PIN, ФИО, баланс 112.5 ₽, активные услуги, кнопки «Пополнить» / «История» |
| Оплата | 4 быстрых действия + список последних транзакций |
| Новости | Лента новостей с детальным просмотром в bottom-sheet |
| Поддержка | Форма обращения + FAQ-аккордеон |

---

## Стек технологий

| Категория | Технология |
|-----------|------------|
| Фреймворк | Next.js 16 (App Router, Turbopack) |
| Язык | TypeScript 5 |
| UI | Tailwind CSS 4 + shadcn/ui + Lucide Icons |
| Анимации | Framer Motion 12 |
| Уведомления | Sonner (toast) |
| Модальные окна | Radix Sheet (shadcn/ui) |
| БД | Prisma ORM 6 + SQLite |
| API | Next.js Route Handlers (mock) |
| Пакетный менеджер | Bun |

---

## Структура проекта

```
src/
├── app/
│   ├── layout.tsx                          # Root layout (lang=ru, viewport)
│   ├── page.tsx                            # Все экраны (4 таба + 3 модалки)
│   ├── globals.css                         # Глобальные стили + CSS-переменные
│   └── api/
│       ├── account/profile/route.ts        # GET  — профиль, баланс, услуги
│       ├── transactions/route.ts           # GET  — история операций
│       ├── news/route.ts                   # GET  — лента новостей
│       ├── support/route.ts                # GET  — список тикетов
│       └── top-up/route.ts                 # POST — пополнение баланса
├── components/ui/
│   └── sheet.tsx                           # Bottom-sheet (shadcn/ui)
└── lib/
    ├── db.ts                               # Prisma Client
    └── utils.ts                             # cn() утилита

prisma/
└── schema.prisma                           # 6 моделей: UserProfile, Balance, Service,
                                            # Transaction, NewsItem, SupportTicket
```

---

## Быстрый старт (разработка)

### Предварительные требования

- [Bun](https://bun.sh/) >= 1.0
- [Node.js](https://nodejs.org/) >= 18 (альтернатива Bun)
- Git

### Установка и запуск

```bash
# 1. Клонировать репозиторий
git clone https://github.com/zzzvalik11/mlk_strlnk.git
cd mlk_strlnk

# 2. Установить зависимости
bun install

# 3. Инициализировать базу данных
bun run db:push
bun run db:generate

# 4. Запустить dev-сервер
bun run dev
```

Приложение будет доступно на **http://localhost:3000**

### Другие команды

```bash
# Линтинг
bun run lint

# Продакшн-сборка
bun run build

# Запуск продакшн-сборки
bun run start

# Перегенерация Prisma-клиента
bun run db:generate
```

---

## API эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/account/profile` | Профиль пользователя, баланс, активные услуги |
| GET | `/api/transactions` | История транзакций |
| GET | `/api/news` | Лента новостей |
| GET | `/api/support` | Список обращений в поддержку |
| POST | `/api/top-up` | Пополнение баланса (body: `{ "amount": 500 }`) |

### Пример ответа `/api/account/profile`

```json
{
  "user": {
    "pin": "039103",
    "fullName": "Примеров-Заде П."
  },
  "balance": {
    "amount": 112.5,
    "currency": "RUB",
    "paidUntilLabel": "до 11 августа"
  },
  "activeServices": [
    {
      "id": "svc-1",
      "name": "100/100 30 day 250 руб",
      "category": "Интернет",
      "cost": 225.0,
      "warningMessage": "!"
    }
  ]
}
```

---

## Схема базы данных (Prisma)

| Модель | Описание |
|--------|----------|
| `UserProfile` | ПИН, ФИО, телефон, аватар |
| `Balance` | Сумма, валюта, дата оплаты, статус |
| `Service` | Название, категория, стоимость, статус |
| `Transaction` | Тип, сумма, описание, дата, статус |
| `NewsItem` | Заголовок, текст, дата, просмотры |
| `SupportTicket` | Тема, описание, статус, ответы |

Связи: `UserProfile` 1→N `Service`, `Transaction`, `SupportTicket`

---

## Получение мобильных сборок (APK / iOS)

> **Важно:** текущий проект — это **веб-приложение** (Next.js). Для получения нативных APK и IPA-файлов его необходимо обернуть в мобильную оболочку. Существует **три основных подхода**.

---

### Подход 1: Capacitor (рекомендуемый)

[Capacitor](https://capacitorjs.com/) от Ionic — это стандартный способ превратить веб-приложение в нативное. Генерирует полноценные Xcode/Android Studio проекты.

#### Установка

```bash
# 1. Собрать веб-приложение
bun run build

# 2. Установить Capacitor
bun add @capacitor/core @capacitor/cli
bun add @capacitor/android @capacitor/ios

# 3. Инициализировать Capacitor
npx cap init "Telecom Dashboard" "com.telecom.dashboard" --web-dir .next/standalone

# 4. Добавить платформы
npx cap add android
npx cap add ios

# 5. Синхронизировать веб-код в нативные проекты
npx cap sync
```

#### Сборка APK (Android)

```bash
# Синхронизировать
npx cap sync android

# Открыть в Android Studio
npx cap open android
```

В Android Studio:
1. **Build → Generate Signed Bundle / APK**
2. Выбрать **APK**
3. Выбрать или создать keystore (для релиза)
4. **Build** → файл `app-debug.apk` или `app-release.apk` появится в `android/app/build/outputs/apk/`

#### Сборка IPA (iOS)

```bash
# Синхронизировать
npx cap sync ios

# Открыть в Xcode
npx cap open ios
```

В Xcode (только на macOS):
1. **Product → Archive**
2. **Distribute App** → **App Store Connect** или **Ad Hoc**
3. IPA-файл будет сохранён в папке `~/Library/Developer/Xcode/Archives/`

---

### Подход 2: PWA (Progressive Web App)

Самый простой путь — никаких нативных сборок. Приложение устанавливается прямо из браузера.

#### Настройка

```bash
# 1. Установить next-pwa
bun add @ducanh2912/next-pwa

# 2. Добавить в next.config.ts:
```

```ts
// next.config.ts
import withPWA from "@ducanh2912/next-pwa";

const pwaConfig = {
  dest: "public",
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === "development",
};

export default withPWA(pwaConfig)(
  // ... ваши настройки next.config
);
```

```bash
# 3. Собрать
bun run build

# 4. Разместить на любом хостинге с HTTPS
```

Пользователь открывает сайт в Chrome/Safari → видит предложение **«Добавить на главный экран»** → приложение работает как нативное (оффлайн, иконка на рабочем столе, полноэкранный режим).

---

### Подход 3: Trusted Web Activity (TWA) — только Android

[Trusted Web Activity](https://developer.chrome.com/docs/android/trusted-web-activity/) оборачивает PWA в полноценный APK через [Bubblewrap](https://github.com/nicedoc/nicedoc.io). Основное преимущество — публикация в Google Play **без Java/Kotlin кода**.

#### Инструмент Bubblewrap

```bash
# 1. Установить
npm install -g @nicolo-ribaudo/nice2rep @nicolo-nicolo/bubblewrap
npm install -g @nicolo-nicolo/bubblewrap

# 2. Инициализация проекта TWA
bubblewrap init --manifest https://your-domain.com/manifest.json

# 3. Сборка APK
bubblewrap build

# Результат: app-release-signed.apk
```

Требования: домен с **HTTPS**, файл `manifest.json` и `assetlinks.json` на сервере.

---

## Сравнение подходов

| Критерий | Capacitor | PWA | TWA |
|----------|-----------|-----|-----|
| APK (Android) | Да | Нет (из Chrome) | Да |
| IPA (iOS) | Да (нужен macOS) | Нет (из Safari) | Нет |
| Доступ к нативным API | Полный | Ограниченный | Нет |
| Скорость запуска | Быстрая | Средняя | Быстрая |
| Размер установки | ~15-30 МБ | ~2 МБ (кэш) | ~5 МБ |
| Сложность | Средняя | Низкая | Низкая |
| Google Play | Да | Нет | Да |
| App Store | Да | Нет | Нет |

---

## Публикация в магазинах приложений

### Google Play Store

#### Инструменты

| Инструмент | Назначение |
|------------|----------|
| [Google Play Console](https://play.google.com/console) | Панель управления (загрузка APK, монетизация, аналитика) |
| [Android Studio](https://developer.android.com/studio) | Среда разработки, отладка, подпись APK |
| [jarsigner / apksigner](https://developer.android.com/studio/publish/app-signing) | Подпись APK релизным ключом |
| [Bundletool](https://developer.android.com/studio/command-line/bundletool) | Проверка и конвертация AAB ↔ APK |
| [Google Play Badge](https://play.google.com/intl/ru/badges/) | Бейдж для сайта «Доступно в Google Play» |

#### Пошаговый процесс

```
1. Создать аккаунт разработчика Google Play
   → https://play.google.com/console/signup
   → Разовый платёж $25 (USD)

2. Подготовить APK/AAB
   → Android Studio → Build → Generate Signed Bundle / APK
   → Выбрать Android App Bundle (.aab) — рекомендуемый формат
   → Подписать релизным keystore (создать при первом релизе, хранить вечно!)

3. Создать приложение в Play Console
   → «Создать приложение» → заполнить форму
   → Название, описание (русский + английский), скриншоты, иконка 512×512

4. Загрузить AAB
   → «Выпуск» → «Создать выпуск» → «Сборка» → загрузить файл

5. Заполнить контент-рейтинг
   → Вопросник о контенте приложения
   → Целевая аудитория (все ages или 3+)

6. Тестирование
   → Internal Testing → загрузить APK для проверки
   → Closed Track → ограниченный круг тестировщиков
   → Open Testing → бета-тестирование для всех желающих

7. Релиз
   → «Выпуск» → «Создать выпуск» → «Production» → загрузить AAB
   → Отправить на ревью (обычно 1-3 дня)
   → После одобрения — публикация (может быть поэтапная в течение 7 дней)
```

#### Автоматизация (CI/CD)

```yaml
# GitHub Actions (.github/workflows/android.yml)
name: Android Build & Deploy

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      - uses: bun/setup-bun@v2
      - run: bun install
      - run: bun run build
      - run: npx cap sync android
      - run: cd android && ./gradlew assembleRelease
      - uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: android/app/build/outputs/apk/release/
```

---

### Apple App Store

#### Инструменты

| Инструмент | Назначение |
|------------|----------|
| [App Store Connect](https://appstoreconnect.apple.com) | Панель управления (загрузка IPA, метрики, отзывы) |
| [Xcode](https://developer.apple.com/xcode/) | IDE для iOS-разработки, архивация, отправка в Store |
| [Transporter](https://apps.apple.com/app/transporter/id1450874784) | Альтернативная загрузка IPA без Xcode |
| [Fastlane](https://fastlane.tools/) | Автоматизация сборки, скриншотов, загрузки |
| [TestFlight](https://developer.apple.com/testflight/) | Бета-тестирование (внутреннее + внешнее) |
| [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Правила проверки приложений |

#### Требования

- **macOS** (обязательно для сборки IPA)
- **Apple Developer Program** — $99/год
- **Xcode** (бесплатно из Mac App Store)
- **Mac с процессором Apple Silicon или Intel**

#### Пошаговый процесс

```
1. Регистрация в Apple Developer Program
   → https://developer.apple.com/programs/enroll/
   → $99 в год
   → Подтверждение личности (паспорт / Apple ID)

2. Создать App ID и Provisioning Profile
   → Xcode → Preferences → Accounts → Manage Certificates
   → App Store Connect → Identifiers → создать App ID
   → Profiles → создать Distribution Profile

3. Настроить проект в Xcode
   → npx cap open ios
   → Установить Bundle Identifier (com.telecom.dashboard)
   → Signing & Capabilities → выбрать Team и Provisioning Profile
   → Deployment Target → iOS 15.0+ (рекомендуется)

4. Добавить иконки и скриншоты
   → Иконки: 1024×1024 (App Store), набор 20×20 — 1024×1024 (приложение)
   → Скриншоты: 6.5" (iPhone 14 Pro Max) и 5.5" (минимум)
   → Можно использовать [Fastlane Snapshot](https://docs.fastlane.tools/actions/snapshots/) или [Screenshot Creator](https://search.itunes.apple.com/WebObjects/MZContentLink.woa/wa/link?path=/apps/939854486)

5. Архивация
   → Xcode → Product → Archive
   → Organizer → выбрать архив → Distribute App

6. Загрузка в TestFlight
   → «TestFlight» → «Internal Testing» → загрузить для команды
   → «External Testing» → пригласить до 10 000 тестировщиков
   → Обязательное ожидание обработки (~24 часа для первого билда)

7. Отправка на ревью App Store
   → App Store Connect → «Мои приложения» → «Создать приложение»
   → Заполнить: название, описание, категория, возрастной рейтинг, ключевые слова
   → Xcode → Archive → Distribute App → App Store Connect
   → Статус: «Ожидает ревью» → «Одобрено» / «Отклонено» (обычно 1-2 дня)

8. Релиз
   → После одобрения выбрать: автоматический выпуск или ручной
   → Ручной: нажать «Выпустить эту версию» в App Store Connect
```

#### Автоматизация (Fastlane + GitHub Actions)

```ruby
# Fastfile
lane :release do
  setup_ci if ENV['CI']
  sync_code_signing(type: "appstore", readonly: true)
  build_app(workspace: "App.xcworkspace", scheme: "App")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

```yaml
# GitHub Actions (.github/workflows/ios.yml)
name: iOS Build & Deploy

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.4'
      - uses: bun/setup-bun@v2
      - run: bun install
      - run: bun run build
      - run: npx cap sync ios
      - name: Build & Upload to TestFlight
        uses: yukiarrr/ios-build-action@v1.12.0
        with:
          project-path: ios/App/App.xcodeproj
          p12-base64: ${{ secrets.P12_BASE64 }}
          mobileprovision-base64: ${{ secrets.MOBILEPROVISION_BASE64 }}
          team-id: ${{ secrets.TEAM_ID }}
          export-method: app-store
```

---

## Развертывание веб-версии

Для продакшн-размещения (Vercel, Netlify, Docker):

```bash
# Сборка
bun run build

# Запуск
bun run start
# Сервер на порту 3000, обслуживает статику + API
```

### Vercel (рекомендуется)

```bash
# Установить Vercel CLI
bun add -g vercel

# Деплой
vercel --prod
```

### Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json bun.lock ./
RUN npm install -g bun && bun install --frozen-lockfile
COPY . .
RUN bun run build
EXPOSE 3000
CMD ["bun", "run", "start"]
```

```bash
docker build -t telecom-dashboard .
docker run -p 3000:3000 -e DATABASE_URL=file:/app/db/custom.db telecom-dashboard
```

---

## Архитектура

```
┌─────────────────────────────────────────────┐
│              Presentation Layer             │
│  page.tsx — 4 таба + 3 модалки              │
│  Доменные типы (TypeScript interfaces)       │
│  Loading / Error / Empty states             │
├─────────────────────────────────────────────┤
│              API Layer (Route Handlers)      │
│  GET  /api/account/profile                  │
│  GET  /api/transactions                     │
│  GET  /api/news                             │
│  GET  /api/support                          │
│  POST /api/top-up                           │
├─────────────────────────────────────────────┤
│              Data Layer                      │
│  Prisma ORM → SQLite                        │
│  6 моделей (schema.prisma)                  │
├─────────────────────────────────────────────┤
│              Domain Layer                    │
│  UserProfile, Balance, Service,             │
│  Transaction, NewsItem, SupportTicket       │
└─────────────────────────────────────────────┘
```

---

## Лицензия

MIT
