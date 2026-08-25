# Руководство по CI/CD — GitHub Actions

Автоматическая сборка Android (APK / AAB) и iOS (IPA) при каждом push в ветку `main`.

---

## Обзор

| Workflow | Файл | Runner | Результат |
|----------|------|--------|----------|
| Build Android | `.github/workflows/android.yml` | `ubuntu-latest` | `app-release.apk` или `app-release.aab` |
| Build iOS | `.github/workflows/ios.yml` | `macos-latest` | `Starlink.ipa` (без подписи) |

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

По умолчанию iOS-сборка **без подписи** (`--no-codesign`). IPA можно использовать для тестирования на симуляторе, но **не для установки на реальное устройство**.

### Для подписанного IPA (установка на iPhone)

Требуется аккаунт Apple Developer ($99/год) и сертификаты.

#### Шаг 1. Подготовка сертификата

```bash
# Экспорт .p12 из Keychain
security find-identity -v -p codesigning
# Экспорт сертификата в .p12 формат
```

#### Шаг 2. Создание Provisioning Profile

1. Зайти на [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Profiles → Create
3. Выбрать тип: **Ad Hoc** или **App Store**
4. Скачать файл `.mobileprovision`

#### Шаг 3. Настройка секретов GitHub

Добавьте в репозитории **Settings → Secrets and variables → Actions**:

| Secret | Описание |
|--------|----------|
| `IOS_CERTIFICATE_BASE64` | `base64 -i certificate.p12 | pbcopy` |
| `IOS_CERTIFICATE_PASSWORD` | Пароль от .p12 файла |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i profile.mobileprovision | pbcopy` |

#### Шаг 4. Раскомментировать шаги в ios.yml

В файле `.github/workflows/ios.yml` раскомментируйте блоки:
- `Install Apple Certificate`
- `Install Provisioning Profile`

И уберите `--no-codesign` из команды сборки.

---

## APK vs AAB — что выбрать?

| | APK | AAB (App Bundle) |
|--|-----|------------------|
| Назначение | Прямая установка на устройство | Загрузка в Google Play |
| Размер | Полный (все архитектуры) | Оптимизированный (Google сжимает) |
| Для тестирования | Да | Нет |
| Для публикации | Нет | Да |

По умолчанию workflow собирает **APK**. Для загрузки в Google Play запустите вручную с `build_type: appbundle`.

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