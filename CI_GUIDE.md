# Руководство по CI/CD — GitHub Actions

Автоматическая сборка Android (APK / AAB) и iOS (IPA) при каждом push в ветку `main`.

---

## Обзор

| Workflow | Файл | Runner | Результат |
|----------|------|--------|----------|
| Build Android | `.github/workflows/android.yml` | `ubuntu-latest` | `app-release.apk` или `app-release.aab` |
| Build iOS | `.github/workflows/ios.yml` | `macos-latest` | `*.ipa` (без подписи) или подписанный IPA |

---

## Как это работает

### Автоматический запуск (push)

Каждый раз при push в `main`:
1. GitHub Actions автоматически запускает оба workflow параллельно.
2. По завершении артефакты (APK, IPA) доступны для скачивания.

### Ручной запуск (workflow_dispatch)

1. Откройте репозиторий на GitHub.
2. Перейдите во вкладку **Actions**.
3. Слева выберите **Build Android** или **Build iOS**.
4. Нажмите **Run workflow**.
5. При необходимости измените параметры:
   - **Flutter version** — версия SDK (по умолчанию — последняя стабильная)
   - **Build type** (только Android) — `apk` или `appbundle`

---

## Этапы сборки (Android)

```
Checkout → Remove stale .freezed → Flutter SDK → pub get → flutter create (android) → deep links → Java 17 → build_runner → build → upload
```

| Шаг | Команда | Описание |
|-----|---------|----------|
| Remove stale generated files | `find lib -name '*.freezed.dart' -delete` | Удаление старых сгенерированных файлов (если были закоммичены) |
| Install dependencies | `flutter pub get` | Загрузка пакетов из pubspec.yaml |
| Generate Android files | `flutter create --platforms=android .` | Создание android/ директории |
| Configure deep links | `bash scripts/configure_deep_links.sh` | Настройка intent-filter для `starlink://` scheme |
| Setup Java | `actions/setup-java@v4` (Zulu 17) | JDK для Gradle |
| Run build_runner | `dart run build_runner build --delete-conflicting-outputs` | Генерация .freezed.dart и .g.dart |
| Build APK | `flutter build apk --release` | Сборка релизного APK |
| Build AAB | `flutter build appbundle --release` | Сборка App Bundle для Google Play |

## Этапы сборки (iOS)

```
Checkout → Remove stale .freezed → Flutter SDK → pub get → flutter create (ios+android) → deep links → build_runner → [pod install | SPM] → build → create IPA → upload
```

| Шаг | Команда | Описание |
|-----|---------|----------|
| Remove stale generated files | `find lib -name '*.freezed.dart' -delete` | Удаление старых сгенерированных файлов |
| Install dependencies | `flutter pub get` | Загрузка пакетов из pubspec.yaml |
| Generate iOS files | `flutter create --platforms=ios,android .` | Создание ios/ и android/ |
| Configure deep links | `bash scripts/configure_deep_links.sh` | Настройка CFBundleURLSchemes для `starlink://` |
| Install CocoaPods (if needed) | `cd ios && pod install` | Запускается только если flutter create создал Podfile |
| Run build_runner | `dart run build_runner build --delete-conflicting-outputs` | Генерация .freezed.dart и .g.dart |
| Build iOS | `flutter build ios --release --no-codesign` | Сборка без подписи |
| Create IPA | `cp + zip` в Payload/ | Упаковка .ipa |

---

### Почему `flutter create .`?

Платформенные директории (`android/`, `ios/`) не хранятся в репозитории — они генерируются Flutter на лету при каждой сборке в CI. Это уменьшает размер репозитория и избегает конфликтов версий Flutter.

### CocoaPods vs Swift Package Manager

Flutter 3.47+ мигрирует с CocoaPods на Swift Package Manager (SPM). Workflow автоматически определяет, какой подход использовать:
- Если `flutter create` сгенерировал `ios/Podfile` → запускается `pod install`
- Если Podfile отсутствует (SPM) → шаг пропускается

**Важно**: `ios/Podfile` не хранится в репозитории — `.gitignore` исключает всю директорию `ios/`.

---

## Глубокие ссылки (Deep Links)

Приложение обрабатывает deep link `starlink://` для возврата из платёжной формы (3DS РСБ).

### Как это работает

1. Пользователь оплачивает картой через WebView (РСБ ECOMM).
2. После 3DS верификации банк перенаправляет на callback URL.
3. WebView перехватывает URL через `NavigationDelegate` и перенаправляет на экран результата.
4. Если банк открывает URL scheme напрямую (`starlink://payment/callback?...`), приложение открывается через deep link.

### Настройка в CI

Скрипт `scripts/configure_deep_links.sh` автоматически настраивает платформы после `flutter create`:
- **Android**: добавляет `intent-filter` в `AndroidManifest.xml` для схемы `starlink`
- **iOS**: добавляет `CFBundleURLSchemes` в `Info.plist`

### Локальная настройка

```bash
# После flutter create (или если платформенные файлы уже есть):
bash scripts/configure_deep_links.sh
```

---

## Скачивание артефактов

1. Откройте **Actions** в репозитории.
2. Кликните на нужный запуск workflow.
3. Внизу страницы, в разделе **Artifacts**, скачайте:
   - `android-apk` — файл `.apk` для установки на Android
   - `android-aab` — файл `.aab` для загрузки в Google Play Console
   - `ios-ipa` — файл `.ipa` (требует подписи для установки на устройство)

Артефакты хранятся **30 дней**.

---

## Установка APK на устройство

### Через ADB (Android Debug Bridge)

```bash
# Скачать артефакт и распаковать
# Подключить телефон по USB с включённой отладкой
adb install app-release.apk
```

### Прямо на телефоне

1. Скачать APK на телефон.
2. Открыть файл → разрешить установку из неизвестных источников.

---

## iOS: подпись кода (Code Signing)

Текущий CI-воркфлоу билдит iOS **без подписи** (`--no-codesign`). Это достаточно для проверки компиляции. Для установки на устройство и публикации в App Store требуется подпись.

### Подготовка (один раз)

#### 1. Аккаунт Apple Developer

Зарегистрируйтесь на [developer.apple.com](https://developer.apple.com/programs/) ($99/год). После подтверждения:

1. Войдите в [App Store Connect](https://appstoreconnect.apple.com/).
2. Запомните ваш **Team ID** (отображается в правом верхнем углу или в Membership).

#### 2. Регистрация App ID

1. Откройте [Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Нажмите **+** → выберите **App IDs** → **App**.
3. В поле **Description** введите: `Starlink Telecom Dashboard`.
4. В поле **Bundle ID** выберите **Explicit** и введите: `com.starlink.telecom` (должен совпадать с проектом).
5. В разделе **Capabilities** включите:
   - **Associated Domains** (для Universal Links, если понадобится)
6. Нажмите **Continue** → **Register**.

#### 3. Создание сертификата рассылки

Вариант A: через Xcode (рекомендуется)

```
Xcode → Settings → Accounts → + → Apple ID
选中 аккаунт → Manage Certificates → + → Apple Distribution
```

Вариант B: через портал

1. [Certificates → +](https://developer.apple.com/account/resources/certificates/list)
2. Тип: **Apple Distribution** (для App Store) или **Development** (для тестирования).
3. Следуйте инструкциям для создания CSR (Certificate Signing Request).
4. Скачайте сертификат и добавьте в Keychain Access.

Экспорт в .p12:

```
Keychain Access → правый клик по сертификату → Export → certificate.p12
Задайте пароль (запомните его — это IOS_CERTIFICATE_PASSWORD)
```

Кодируем для GitHub:

```bash
base64 -i certificate.p12 | pbcopy
# Результат вставьте в секрет IOS_CERTIFICATE_BASE64
```

#### 4. Создание Provisioning Profile

1. [Profiles → +](https://developer.apple.com/account/resources/profiles/list)
2. Тип: **App Store** (для публикации) или **Ad Hoc** (для тестирования на устройствах).
3. Выберите App ID из шага 2.
4. Выберите сертификат из шага 3.
5. Скачайте `.mobileprovision`.

```bash
base64 -i profile.mobileprovision | pbcopy
# Результат вставьте в секрет IOS_PROVISIONING_PROFILE_BASE64
```

#### 5. Локальная сборка с подписью (проверка)

```bash
# Генерируем платформенные файлы
flutter create --platforms=ios .
bash scripts/configure_deep_links.sh

# Устанавливаем профиль (если CocoaPods)
cd ios && pod install && cd ..

# Билд с экспортом
flutter build ipa \
  --release \
  --export-options-plist=ios/ExportOptions.plist

# Результат: build/ios/ipa/*.ipa
```

В `ExportOptions.plist` замените `${TEAM_ID}` на ваш реальный Team ID.

### Методы подписи в ExportOptions.plist

| method | Когда использовать |
|--------|-------------------|
| `app-store` | Публикация в App Store Connect |
| `ad-hoc` | Установка на конкретные устройства (UDID) |
| `development` | Отладка на зарегистрированных устройствах |
| `enterprise` | Внутренняя дистрибуция (Enterprise-программа) |

---

## APK vs AAB

| | APK | AAB (App Bundle) |
|--|-----|------------------|
| Назначение | Прямая установка на устройство | Загрузка в Google Play |
| Размер | Полный (все архитектуры) | Оптимизированный (Google сжимает) |
| Для тестирования | Да | Нет |
| Для публикации | Нет | Да |

По умолчанию workflow собирает **APK**. Для загрузки в Google Play запустите вручную с `build_type: appbundle`.

---

## Публикация в Google Play

### 1. Подготовка аккаунта

1. Зарегистрируйтесь на [Google Play Console](https://play.google.com/console) ($25 разовый платёж).
2. Пройдите верификацию: заполните данные разработчика, оплатите регистрационный взнос.
3. Создайте приложение: **Create app** → введите название, язык по умолчанию (русский), тип приложения (Приложение / App).
4. Запомните **Package Name**: он должен совпадать с `applicationId` в `android/app/build.gradle`.

### 2. Настройка applicationId и version

В `android/app/build.gradle` (генерируется `flutter create`, поэтому настройте через `--build-number`):

```bash
# Версия + код сборки задаются при сборке:
flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=1

# Каждая новая загрузка требует БОЛЬШЕГО build-number:
flutter build appbundle --release \
  --build-name=1.0.1 \
  --build-number=2
```

Либо обновите `pubspec.yaml`:

```yaml
version: 1.0.0+1   # формат: версия+build_number
```

### 3. Сборка AAB

Через CI (рекомендуется):

```
GitHub Actions → Build Android → Run workflow → build_type: appbundle
```

Локально:

```bash
flutter create --platforms=android .
bash scripts/configure_deep_links.sh
flutter build appbundle --release
# Результат: build/app/outputs/bundle/release/app-release.aab
```

### 4. Загрузка в Google Play Console

**Вариант A: через веб-интерфейс (ручная загрузка)**

1. Откройте [Google Play Console](https://play.google.com/console) → ваше приложение.
2. Перейдите в **Доставка** (Release) → **Сборки** (Production / Open testing / Closed testing).
3. Нажмите **Создать новый выпуск** (Create new release).
4. Загрузите `app-release.aab`.
5. Заполните **Сводку о выпуске** (Release notes) — что нового в этой версии.
6. Нажмите **Сохранить** → **Проверить выпуск**.
7. После успешной проверки — **Начать выпуск** (Start rollout).

**Вариант B: автоматическая загрузка через CI (Google Play Publisher API)**

1. В [Google Play Console → Настройки → Доступ к API](https://play.google.com/console/api) создайте OAuth-клиент для сервисного аккаунта.
2. Скачайте JSON-ключ сервисного аккаунта.
3. Добавьте в GitHub Secrets:
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — содержимое JSON-файла ключа
4. Добавьте шаг в `.github/workflows/android.yml` после сборки AAB:

```yaml
- name: Upload to Google Play
  if: github.event.inputs.build_type == 'appbundle'
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
    packageName: com.starlink.telecom
    releaseFiles: build/app/outputs/bundle/release/app-release.aab
    track: internal  # internal / alpha / beta / production
    status: completed
    whatsNewDirectory: distribution/whatsnew
    mappingFile: build/app/outputs/mapping/release/mapping.txt
```

### 5. Требования Google Play к материалам

Перед первым релизом подготовьте в Google Play Console:

| Материал | Требование |
|----------|------------|
| Иконка приложения | 512x512 PNG, 32-битный цвет |
| Скриншоты | Минимум 2, до 8. Размер зависит от устройства |
| Краткое описание | До 80 символов |
| Полное описание | До 4000 символов |
| Категория | Финансы / Утилиты |
| Возрастной рейтинг | Заполните анкету контент-рейтинга |
| Политика конфиденциальности | URL на страницу с политикой |
| Правила программы | Подтверждение соблюдения |

### 6. Цикл обновлений

```
Разработка → push в main → CI билдит AAB → Загрузка в Play Console → Тестирование → Релиз
```

Важно: каждый последующий `build_number` должен быть **строго больше** предыдущего. Google Play отклонит AAB с таким же или меньшим номером.

---

## Публикация в App Store

### 1. Подготовка аккаунта

Аккаунт Apple Developer ($99/год) должен быть уже создан (см. раздел iOS Code Signing).

1. Войдите в [App Store Connect](https://appstoreconnect.apple.com/).
2. Перейдите в **Мои приложения** → **+** → **Новое приложение**.
3. Заполните:
   - Название: `Starlink` (или ваше)
   - Основной язык: `Русский`
   - SKU: `starlink-telecom` (внутренний идентификатор)
   - Bundle ID: выберите зарегистрированный `com.starlink.telecom`

### 2. Требования к материалам

| Материал | Требование |
|----------|------------|
| Название | До 30 символов |
| Подзаголовок | До 30 символов |
| Ключевые слова | До 100 символов, через запятую |
| Описание | До 4000 символов |
| Скриншоты | 6.7" (iPhone) и/или 12.9" (iPad), минимум 3, максимум 10 |
| Иконка | 1024x1024 PNG (без альфа-канала) |
| Возрастной рейтинг | Заполните анкету в App Store Connect |
| Политика конфиденциальности | Обязательна, URL |

### 3. Сборка подписанного IPA

Локально (рекомендуется для первого релиза):

```bash
# Генерируем платформенные файлы
flutter create --platforms=ios .
bash scripts/configure_deep_links.sh

# CocoaPods (если нужен)
cd ios && pod install && cd ..

# Подготавливаем ExportOptions.plist
sed -i '' 's/\${TEAM_ID}/ВАШ_TEAM_ID/g' ios/ExportOptions.plist

# Меняем method на app-store для публикации
sed -i '' 's/method>automatic/method>app-store/' ios/ExportOptions.plist

# Билдим
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --export-options-plist=ios/ExportOptions.plist

# Результат: build/ios/ipa/*.ipa
```

### 4. Загрузка IPA через Xcode (рекомендуемый способ)

Apple требует загрузку через Xcode или Transporter — прямой API-доступ ограничен.

```
1. Скачайте IPA из CI-артефактов (или соберите локально)
2. Откройте Xcode
3. Xcode → Open → выберите файл IPA
4. Xcode автоматически откроет Organizer (или Window → Organizer)
5. В Organizer выберите ваше приложение → Distribution App
6. Нажмите Distribute App → App Store Connect → Upload
7. Следуйте инструкциям, выберите правильный Team и Provisioning Profile
8. После успешной загрузки перейдите в App Store Connect
```

### 5. Загрузка через Transporter (альтернатива)

```
1. Установите Transporter из Mac App Store
2. Перетащите .ipa в окно Transporter
3. Нажмите Deliver — файл загрузится в App Store Connect
```

### 6. Отправка на ревью

После загрузки IPA в App Store Connect:

1. Перейдите в ваше приложение → вкладка **TestFlight**.
2. Добавьте тестировщиков (внутренних или внешних) для бета-тестирования.
3. Когда готовы к релизу — перейдите в вкладку **Подготовка к отправке**.
4. Заполните все обязательные поля (скриншоты, описание, возрастной рейтинг, политика конфиденциальности).
5. Нажмите **Добавить сборку для ревью** — выберите загруженный IPA.
6. Нажмите **Отправить на ревью**.
7. Обычно ревью занимает 24-48 часов. Статус видно в App Store Connect.

### 7. Цикл обновлений

```
Разработка → push в main → CI билдит (no-codesign, проверка) →
Локально: сборка подписанного IPA → Xcode / Transporter → App Store Connect →
TestFlight (бета) → Ревью → App Store
```

Важно: каждый `build_number` должен быть **строго больше** предыдущего. App Store отклонит сборку с таким же или меньшим номером. Увеличивайте `version` в `pubspec.yaml` (`1.0.0+2`, `1.0.1+3` и т.д.).

---

## Управление версиями

Версия приложения задаётся в `pubspec.yaml`:

```yaml
version: 1.0.0+1   # MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Правила:
- `BUILD_NUMBER` (+N) должен быть уникальным для каждой сборки и монотонно возрастающим
- Google Play и App Store сравнивают **только** BUILD_NUMBER, а не строку версии
- При релизе увеличивайте PATCH (1.0.0 → 1.0.1) и ОБЯЗАТЕЛЬНО build_number (1 → 2)

---

## Автоматизация публикации (Fastlane)

Для полной автоматизации (CI → TestFlight / Google Play без ручных шагов) можно подключить [Fastlane](https://fastlane.tools/):

- `fastlane supply` — загрузка AAB в Google Play
- `fastlane deliver` — загрузка IPA в App Store Connect
- `fastlane pilot` — управление TestFlight

Это отдельный шаг настройки, который требует установки Ruby-окружения и создания `Fastfile`. Если потребуется — документация будет добавлена.

---

## Изменение версии Flutter

### Через workflow_dispatch

При ручном запуске укажите нужную версию в поле **Flutter version**.

### В коде workflow

Измените дефолтное значение в `.github/workflows/android.yml`:

```yaml
flutter-version: '3.27.4'  # пустая строка = последняя стабильная
```

И в `.github/workflows/ios.yml` аналогично.

---

## Отладка ошибок сборки

### 1. Ошибка freezed (missing implementations)

Симптом: `The non-abstract class 'X' is missing implementations for these members: _$X.toJson...`

Причина: в репозитории остались старые `.freezed.dart` файлы, не соответствующие текущему исходному коду.

Решение:
```bash
# Локально:
find lib -name '*.freezed.dart' -delete
find lib -name '*.g.dart' -delete
flutter pub run build_runner build --delete-conflicting-outputs

# Если файлы закоммичены в git:
git rm --cached 'lib/**/*.freezed.dart' 'lib/**/*.g.dart'
git commit -m 'chore: remove stale generated files'
```

CI автоматически удаляет stale файлы перед `build_runner`.

### 2. Ошибка `flutter create`

Если в репозитории появились файлы, конфликтующие с генерируемыми (например, свой `android/`), удалите их перед запуском CI.

### 3. Android: Gradle error

Обычно связан с версией Java или AGP. Проверьте, что `java-version: '17'` соответствует вашей версии `android/build.gradle`.

### 4. iOS: CocoaPods / SPM конфликт

Flutter 3.47+ мигрирует на Swift Package Manager. Если видите ошибку о CocoaPods:
- Убедитесь, что `ios/Podfile` **не** хранится в репозитории
- Проверьте `.gitignore`: директива `/ios/` должна игнорировать всю папку (без исключений)
- CI автоматически определяет, нужен ли `pod install`

### 5. iOS: Xcode version mismatch

`macos-latest` обновляется GitHub. Если сборка сломалась, можно pin-нуть Xcode:

```yaml
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '16.0'
```

---

## Структура generated-файлов

```
*.freezed.dart  — генерируется freezed (иммутабельные классы, copyWith, when/maybe)
*.g.dart       — генерируется json_serializable (fromJson/toJson)
```

Оба типа файлов **не хранятся в репозитории** (`.gitignore`: `*.freezed.dart`, `*.g.dart`).
Генерация происходит в CI через `build_runner` и локально через:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Полезные команды

```bash
# Локальная генерация кода
flutter pub run build_runner build --delete-conflicting-outputs

# Очистка сгенерированных файлов
find lib -name '*.freezed.dart' -delete && find lib -name '*.g.dart' -delete

# Локальная настройка deep links (после flutter create)
bash scripts/configure_deep_links.sh

# Посмотреть логи CI
gh run list --limit 5
gh run view --log
```