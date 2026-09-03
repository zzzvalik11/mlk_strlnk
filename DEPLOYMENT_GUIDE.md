# Руководство по публикации — Google Play и App Store

Пошаговая инструкция по подготовке, подписи и публикации приложения в магазинах.

---

## Содержание

1. [Подготовка](#1-подготовка)
2. [Google Play](#2-google-play)
3. [App Store Connect](#3-app-store-connect)
4. [Fastlane (автоматизация)](#4-fastlane-автоматизация)
5. [Материалы для сторов](#5-материалы-для-сторов)
6. [Чеклист перед релизом](#6-чеклист-перед-релизом)

---

## 1. Подготовка

### 1.1. Версия и build number

Файл `pubspec.yaml`:

```yaml
version: 1.0.0+1
#         ^^^ ^
#         |   |-- build number (целое, увеличивается при каждом релизе)
#         |------- version name (semver: major.minor.patch)
```

- **Version name** (`1.0.0`) — видят пользователи. Меняется при новых фичах/исправлениях.
- **Build number** (`+1`) — внутренний счётчик. Должен быть **строго больше** предыдущего для каждого магазина.

### 1.2. Подпись Android (Keystore)

Для публикации в Google Play нужен **релизный keystore**.

#### Создание keystore (один раз)

```bash
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore android/app/keystore/release.jks \
  -keyalias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Запомните пароль от keystore и alias — они понадобятся при каждом релизе.

> **Критично**: если потеряете keystore — невозможно обновить приложение. Храните `.jks` в безопасном месте (не в git!).

#### Настройка подписи в Gradle

После `flutter create --platforms=android .` создайте `android/key.properties`:

```properties
storePassword=ваш_пароль_от_keystore
keyPassword=ваш_пароль_от_alias
keyAlias=release
storeFile=keystore/release.jks
```

В `android/app/build.gradle` добавьте:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

Добавьте `key.properties` и `keystore/` в `.gitignore`:

```
android/key.properties
android/app/keystore/
```

### 1.3. Подпись iOS

Для iOS подпись привязана к аккаунту Apple Developer.

- **Регистрация**: [developer.apple.com](https://developer.apple.com/programs/enroll/) — $99/год.
- Сертификаты создаются через Xcode или Fastlane `match`.
- Provisioning Profile привязывает сертификат к Bundle ID.

Пошаговая настройка описана в разделе [App Store Connect](#3-app-store-connect).

### 1.4. App ID и Bundle Identifier

Убедитесь, что Bundle ID уникален и соответствует проекту.

```bash
# Android: android/app/build.gradle
applicationId "com.example.telecomdashboard"  # замените на свой

# iOS: ios/Runner.xcodeproj/project.pbxproj
PRODUCT_BUNDLE_IDENTIFIER = com.example.telecomdashboard
```

> Важно: Bundle ID для iOS и Android **можно** делать разными, но обычно делают одинаковыми.

---

## 2. Google Play

### 2.1. Регистрация

1. Зайдите на [Google Play Console](https://play.google.com/console).
2. Оплатите разовый регистрационный взнос ($25).
3. Создайте приложение: **Create app**.
4. Заполните базовую информацию: название, язык, бесплатное/платное, реклама (да/нет).

### 2.2. Настройка приложения в консоли

#### Store settings (слева в меню)

- **App access** — выберите ограничение (если нужно).
- **Content rating** — заполните анкету (наличие рекламы, возрастные ограничения).
- **Target audience** — возрастная группа и аудитория.
- **Privacy policy** — ссылка на политику конфиденциальности (обязательна).
- **App content** — объявления, рекламный ID, контент приложения.

#### Доступ к приложению (optional)

- **Internal testing** — до 100 тестировщиков, мгновенная доставка.
- **Closed testing** — до 10 000, email-приглашения или Google Groups.
- **Open testing** — любой пользователь из Google Play (бета).

### 2.3. Сборка AAB

```bash
# Генерация платформы и кода
flutter create --platforms=android .
bash scripts/configure_deep_links.sh
flutter pub run build_runner build --delete-conflicting-outputs

# Сборка релизного AAB (требует key.properties с keystore)
flutter build appbundle --release
```

Файл: `build/app/outputs/bundle/release/app-release.aab`

> Если keystore не настроен, AAB будет подписан debug-ключом. Google Play примет, но для production нужен релизный keystore.

### 2.4. Загрузка в Google Play Console

#### Через браузер

1. Откройте приложение в Google Play Console.
2. Перейдите в **Dashboard** → **Production** → **Create new release**.
3. Загрузите AAB-файл.
4. Заполните **Release notes** (что нового в этой версии).
5. Нажмите **Next** → **Review release** → **Start rollout**.

#### Через Fastlane (рекомендуется для регулярных релизов)

```bash
# Установка
gem install fastlane -NV

# Инициализация (создаёт fastlane/ с конфигами)
cd /путь/к/проекту
fastlane init
```

См. подробности в разделе [Fastlane](#4-fastlane-автоматизация).

### 2.5. Обзор Google Play (Review)

- Срок: обычно от нескольких часов до 7 дней.
- Причины отклонения: нарушения политики, неполные метаданные, краши на старте.
- Статус можно отслеживать в **Dashboard** → **Production**.

### 2.6. Релиз по этапам (Staged Rollout)

Вместо выпуска 100% пользователей сразу:

1. В **Release details** выберите **Staged rollout**.
2. Начните с 5-10% пользователей.
3. Мониторьте краш-репорты (Firebase Crashlytics, Google Play Vitals).
4. Увеличивайте процент: 25% → 50% → 100%.

---

## 3. App Store Connect

### 3.1. Регистрация

1. Зайдите на [developer.apple.com](https://developer.apple.com/programs/enroll/).
2. Оплатите подписку ($99/год).
3. После подтверждения (до 48 часов) зайдите в [App Store Connect](https://appstoreconnect.apple.com).

### 3.2. Создание приложения

1. В App Store Connect: **My Apps** → **+** → **New App**.
2. Заполните:
   - **Name** — название (должно быть уникальным в App Store).
   - **Primary Language** — русский (если приложение на русском).
   - **Bundle ID** — должен совпадать с Xcode проектом.
   - **SKU** — внутренний идентификатор (любой, например `telecom-dashboard-001`).

### 3.3. Сертификаты и профили

#### Через Xcode (простой путь для первого релиза)

1. Откройте проект в Xcode: `open ios/Runner.xcworkspace`.
2. Выберите **Runner** в Targets.
3. Вкладка **Signing & Capabilities**:
   - Поставьте галочку **Automatically manage signing**.
   - Выберите **Team** (ваш Apple ID Developer).
   - Xcode автоматически создаст сертификат и provisioning profile.
4. Убедитесь, что Bundle Identifier совпадает с App Store Connect.

#### Через Fastlane `match` (рекомендуется для команды)

```bash
# Первый запуск — создаёт сертификаты и загружает в Git-репозиторий
fastlane match appstore

# Последующие релизы — скачивает существующие сертификаты
fastlane match appstore
```

См. раздел [Fastlane match](#41-fastlane-match).

### 3.4. Сборка IPA

```bash
# Генерация платформы и кода
flutter create --platforms=ios,android .
bash scripts/configure_deep_links.sh
flutter pub run build_runner build --delete-conflicting-outputs

# Сборка (требует настройки подписи в Xcode или через match)
flutter build ios --release
```

Xcode архив:

```bash
# Откройте Xcode
open ios/Runner.xcworkspace

# Или создайте архив через командную строку
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Экспорт IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ipa
```

Файл: `build/ipa/Runner.ipa`

### 3.5. Загрузка в App Store Connect

#### Через Xcode

1. **Window** → **Organizer**.
2. Выбрать архив → **Distribute App**.
3. Выбрать **App Store Connect** → **Upload**.
4. Xcode загрузит IPA и метаданные.

#### Через Transporter (из App Store)

1. Скачать [Transporter](https://apps.apple.com/app/transporter/id1450874784) с Mac App Store.
2. Перетащить IPA в окно Transporter.
3. Нажать **Deliver**.

#### Через Fastlane (рекомендуется)

```bash
fastlane deliver --ipa build/ipa/Runner.ipa
```

### 3.6. Заполнение метаданных в App Store Connect

После загрузки IPA:

1. Откройте приложение в App Store Connect.
2. Заполните обязательные поля:
   - **Версия** — должна совпадать с pubspec.yaml (`1.0.0`).
   - **Описание** — подробное описание приложения.
   - **Ключевые слова** — до 100 символов, через запятую.
   - **Категория** — выберите подходящую (например, «Финансы» или «Утилиты»).
   - **Возрастной рейтинг** — заполните анкету.
   - **Скриншоты** — минимум 4, максимум 10 (см. [требования](#5-материалы-для-сторов)).
   - **Иконка 1024x1024** — без альфа-канала, без круглых углов.
   - **URL политики конфиденциальности** (обязателен).

### 3.7. Отправка на ревью

1. В App Store Connect: **Select a build** → выберите загруженный билд.
2. Если билд не появился, подождите 15-30 минут (обработка Apple).
3. Заполните все обязательные поля (без красных предупреждений).
4. Нажмите **Add for Review**.
5. Ответьте на вопросы (экспортные compliance, рекламные идентификаторы и т.д.).
6. **Submit for Review**.

### 3.8. Обзор Apple (Review)

- Срок: от 24 часов до нескольких дней.
- Возможен rejection с указанием причины — исправляете и загружаете заново.
- Частые причины:
  - Неполные метаданные.
  - Краш при запуске.
  - Нарушение [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
  - Отсутствие политики конфиденциальности.

---

## 4. Fastlane (автоматизация)

### Что такое Fastlane

Fastlane — это набор инструментов Ruby для автоматизации публикации. Позволяет одной командой собрать, подписать и загрузить приложение в магазин.

### 4.1. Установка и инициализация

```bash
# Требуется Ruby 2.5+
ruby --version

# Установка
sudo gem install fastlane -NV
# Или через bundler (рекомендуется):
bundle init
echo 'gem "fastlane"' >> Gemfile
bundle install

# Инициализация в корне проекта (создаёт папку fastlane/)
fastlane init
```

При инициализации Fastlane задаст вопросы:
- Какой секрет JSON-файла Google Play использовать? (для `supply`)
- Bundle Identifier приложения.
- Apple ID для App Store Connect.

### 4.2. Fastlane `match` (сертификаты iOS)

`match` управляет сертификатами и provisioning profiles через зашифрованный Git-репозиторий.

#### Первый запуск

```bash
# Создать приватный Git-репозиторий для сертификатов (например, на GitHub)
# Создать хранилище паролей:
fastlane match appstore --git_url https://github.com/you/certificates.git
```

Fastlane:
1. Создаст новый сертификат Distribution.
2. Создаст provisioning profile App Store.
3. Сохранит всё в Git-репозиторий (зашифровано).

#### Использование

```bash
# Скачать и установить сертификаты перед сборкой
fastlane match appstore

# Сборка и загрузка (сертификаты автоматически установятся)
fastlane ios release
```

#### Добавление новых устройств (для Ad Hoc)

```bash
fastlane match adhoc --force_for_new_devices
```

### 4.3. Конфигурация Fastfile

Файл `fastlane/Fastfile` — основной конфиг с lanes (полосами/задачами).

```ruby
# fastlane/Fastfile
default_platform(:ios)

# ====================================
# iOS
# ====================================

platform :ios do
  desc "Upload to TestFlight"
  lane :beta do
    setup_ci if ENV['CI']
    match(type: "appstore")
    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Upload to App Store"
  lane :release do
    setup_ci if ENV['CI']
    match(type: "appstore")
    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store(
      force: true,
      submit_for_review: true,
      automatic_release: false,
      precheck_include_in_app_purchases: false
    )
  end
end

# ====================================
# Android
# ====================================

platform :android do
  desc "Upload to Google Play (Internal Track)"
  lane :internal do
    # Скачайте JSON-ключ из Google Play Console:
    # Settings → API access → Create new key → JSON
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      json_key: "fastlane/api-key.json"
    )
  end

  desc "Upload to Google Play (Production Track)"
  lane :production do
    upload_to_play_store(
      track: "production",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      json_key: "fastlane/api-key.json"
    )
  end
end
```

### 4.4. Google Play API-ключ

Для `upload_to_play_store` нужен сервисный аккаунт:

1. Google Play Console → **Settings** → **API access**.
2. В разделе **Service accounts** нажмите **Create new service account**.
3. Перейдите по ссылке в Google Cloud Console.
4. Создайте сервисный аккаунт, скачайте JSON-ключ.
5. Сохраните как `fastlane/api-key.json`.
6. Добавьте в `.gitignore`.

### 4.5. Использование Fastlane

```bash
# iOS — загрузка в TestFlight (для внутреннего тестирования)
fastlane ios beta

# iOS — публикация в App Store
fastlane ios release

# Android — внутреннее тестирование
fastlane android internal

# Android — продакшн
fastlane android production

# Всё одной командой (сборка + загрузка):
fastlane ios release
```

### 4.6. Fastlane в CI (GitHub Actions)

Пример добавления в существующий workflow:

```yaml
# В .github/workflows/ios.yml или android.yml
- name: Deploy to Store
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
    APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
    APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
  run: |
    gem install fastlane -NV
    fastlane release
```

> `secrets` доступен в `env:` на уровне шага, но **не** в `if:` на уровне шага.

### 4.7. Скриншоты через Fastlane

```bash
# Установить симуляторы
fastlane snapshot
```

Создайте скрипты в `fastlane/screenshots/` — Fastlane автоматически запустит приложение на разных размерах экрана и сделает скриншоты.

---

## 5. Материалы для сторов

### 5.1. Иконки

| Платформа | Размер | Формат | Требования |
|-----------|--------|--------|------------|
| Android (Adaptive Icon) | 108x108 dp (foreground 72dp) | PNG / Vector | Без текста, без теней |
| iOS App Icon | 1024x1024 px | PNG | Без альфа-канала, без круглых углов |

> Для Android Flutter автоматически генерирует иконки из `assets/images/` через `flutter_launcher_icons`.

```bash
# Установка
flutter pub dev flutter_launcher_icons --version
flutter pub add dev:flutter_launcher_icons

# flutter_launcher_icons.yaml
flutter pub run flutter_launcher_icons
```

### 5.2. Скриншоты

#### Google Play (минимум 2, рекомендовано 5-8)

| Тип | Размеры (px) | Количество |
|-----|-------------|------------|
| Телефон | 1080x1920, 1080x2400 | 2-8 штук |
| 7-дюймовый планшет | 1200x2133 | 0-8 штук |
| 10-дюймовый планшет | 1920x1200 | 0-8 штук |

Формат: PNG или JPEG. Без кнопок навигации (статус-бара можно не убирать).

#### App Store (минимум 4, максимум 10)

| Устройство | Размер (px) |
|------------|-------------|
| iPhone 6.7" (15 Pro Max) | 1290x2796 |
| iPhone 6.5" (11 Pro Max) | 1284x2778 |
| iPad Pro 12.9" | 2048x2732 |

Формат: PNG, без альфа-канала.

### 5.3. Описание и ключевые слова

#### Google Play

- **Краткое описание** — до 80 символов (видно в поиске).
- **Полное описание** — до 4000 символов.

#### App Store

- **Описание** — до 4000 символов.
- **Подзаголовок** — до 30 символов.
- **Ключевые слова** — до 100 символов, через запятую (не видны пользователям, влияют на поиск).

### 5.4. Политика конфиденциальности

Обязательна для обоих сторов. Варианты:

- Страница на сайте (предпочтительно).
- Генераторы: [app-privacy-policy-generator.firebaseapp.com](https://app-privacy-policy-generator.firebaseapp.com/).
- Если приложение не собирает данные — можно указать это явно.

---

## 6. Чеклист перед релизом

### Общие

- [ ] Версия в `pubspec.yaml` увеличена (`version: X.Y.Z+N`)
- [ ] `build_runner` отработал без ошибок
- [ ] Нет закоммиченных `.freezed.dart` / `.g.dart` файлов
- [ ] Deep links работают (`starlink://`)
- [ ] Все экраны открываются без крашей
- [ ] Адаптивная верстка проверена на разных размерах экрана

### Android

- [ ] Keystore создан и `key.properties` настроен
- [ ] `flutter build appbundle --release` завершается успешно
- [ ] AAB подписан релизным ключом (проверить: `apksigner verify --print-certs app-release.aab`)
- [ ] Скриншоты загружены (минимум 2, разных размеров)
- [ ] Иконка 512x512 для Google Play
- [ ] Описание, категория, возрастной рейтинг заполнены
- [ ] Политика конфиденциальности указана

### iOS

- [ ] Apple Developer аккаунт активен ($99/год оплачен)
- [ ] Bundle ID совпадает между Xcode и App Store Connect
- [ ] Сертификат и provisioning profile валидны (через Xcode или `match`)
- [ ] `flutter build ios --release` завершается успешно
- [ ] IPA загружен через Xcode Organizer / Transporter / Fastlane
- [ ] Скриншоты загружены (минимум 4, для каждого размера устройства)
- [ ] Иконка 1024x1024 без альфа-канала
- [ ] Описание, ключевые слова, категория заполнены
- [ ] Возрастной рейтинг пройден
- [ ] Экспортные compliance-вопросы отвечены

### Опционально (но рекомендуется)

- [ ] Fastlane настроен и протестирован
- [ ] TestFlight / Internal Testing пройден
- [ ] Firebase Crashlytics подключён
- [ ] Стейджд-роллаут вместо мгновенного выпуска 100%
- [ ] Changelog записан

---

## Быстрый старт (минимальный путь)

### Первый релиз в Google Play

```bash
# 1. Создать keystore
keytool -genkeypair -v -storetype PKCS12 -keystore release.jks -keyalias release -keyalg RSA -keysize 2048 -validity 10000

# 2. Настроить key.properties (см. раздел 1.2)

# 3. Собрать AAB
flutter create --platforms=android .
bash scripts/configure_deep_links.sh
flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release

# 4. Загрузить AAB в Google Play Console
```

### Первый релиз в App Store

```bash
# 1. Зарегистрировать Apple Developer ($99/год)

# 2. Создать приложение в App Store Connect

# 3. Настроить подпись в Xcode (Signing & Capabilities)

# 4. Собрать и загрузить
flutter create --platforms=ios,android .
bash scripts/configure_deep_links.sh
flutter pub run build_runner build --delete-conflicting-outputs
flutter build ios --release

# 5. Архивировать и экспортировать через Xcode Organizer

# 6. Отправить на ревью в App Store Connect
```

---

## Полезные ссылки

| Ресурс | Ссылка |
|--------|--------|
| Google Play Console | https://play.google.com/console |
| App Store Connect | https://appstoreconnect.apple.com |
| Apple Developer | https://developer.apple.com |
| Fastlane документация | https://docs.fastlane.tools |
| Flutter deploy guide | https://docs.flutter.dev/deployment |
| App Store Review Guidelines | https://developer.apple.com/app-store/review/guidelines/ |
| Google Play policies | https://play.google.com/about/developer-content-policy/ |
