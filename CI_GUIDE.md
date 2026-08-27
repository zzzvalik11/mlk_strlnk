# Руководство по CI/CD — GitHub Actions

Автоматическая сборка Android (APK / AAB) и iOS (IPA) при каждом push в ветку `main`.

---

## Обзор

| Workflow | Файл | Runner | Результат |
|----------|------|--------|----------|
| Build Android | `.github/workflows/android.yml` | `ubuntu-latest` | `app-release.apk` или `app-release.aab` |
| Build iOS | `.github/workflows/ios.yml` | `macos-latest` | `*.ipa` (без подписи) |

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
| Remove stale generated files | `find lib -name '*.freezed.dart' -delete` | Удаление старых сгенерированных файлов |
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

### Настройка в CI

Скрипт `scripts/configure_deep_links.sh` автоматически настраивает платформы после `flutter create`:
- **Android**: добавляет `intent-filter` в `AndroidManifest.xml` для схемы `starlink`
- **iOS**: добавляет `CFBundleURLSchemes` в `Info.plist`

### Локальная настройка

```bash
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
adb install app-release.apk
```

### Прямо на телефоне

1. Скачать APK на телефон.
2. Открыть файл → разрешить установку из неизвестных источников.

---

## iOS: подпись кода (Code Signing)

Текущий CI-воркфлоу билдит iOS **без подписи** (`--no-codesign`). Это достаточно для проверки компиляции. Для установки на устройство и публикации потребуется подпись.

> Подробная инструкция по настройке подписи и публикации — в [**DEPLOYMENT_GUIDE.md**](./DEPLOYMENT_GUIDE.md).

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

## Управление версиями

Версия приложения задаётся в `pubspec.yaml`:

```yaml
version: 1.0.0+1   # MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Правила:
- `BUILD_NUMBER` (+N) должен быть уникальным для каждой сборки и монотонно возрастающим
- Google Play и App Store сравнивают **только** BUILD_NUMBER
- При релизе увеличивайте PATCH и ОБЯЗАТЕЛЬНО build_number

---

## Отладка ошибок сборки

### 1. Ошибка freezed (missing implementations)

Симптом: `The non-abstract class 'X' is missing implementations for these members: _$X.toJson...`

Причина: в репозитории остались старые `.freezed.dart` файлы.

Решение:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

CI автоматически удаляет stale файлы перед `build_runner`.

### 2. Ошибка `flutter create`

Если в репозитории появились файлы, конфликтующие с генерируемыми, удалите их перед запуском CI.

### 3. Android: Gradle error

Проверьте, что `java-version: '17'` соответствует вашей версии `android/build.gradle`.

### 4. iOS: CocoaPods / SPM конфликт

- Убедитесь, что `ios/Podfile` **не** хранится в репозитории
- Проверьте `.gitignore`: директива `/ios/` должна игнорировать всю папку
- CI автоматически определяет, нужен ли `pod install`

### 5. iOS: Xcode version mismatch

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

---

## Полезные команды

```bash
# Локальная генерация кода
flutter pub run build_runner build --delete-conflicting-outputs

# Очистка сгенерированных файлов
find lib -name '*.freezed.dart' -delete && find lib -name '*.g.dart' -delete

# Локальная настройка deep links
bash scripts/configure_deep_links.sh

# Посмотреть логи CI
gh run list --limit 5
gh run view --log
```

---

## См. также

- [**DEPLOYMENT_GUIDE.md**](./DEPLOYMENT_GUIDE.md) — публикация в Google Play и App Store, Fastlane, материалы для сторов
- [**ARCHITECTURE.md**](./ARCHITECTURE.md) — интеграция с РСБ, СБП, FCM, Devino
- [**api.yaml**](./api.yaml) — OpenAPI 3.0.3 спецификация (42 эндпоинта)
