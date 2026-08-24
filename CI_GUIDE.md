# Руководство по CI/CD — GitHub Actions

Автоматическая сборка Android (APK / AAB) и iOS (IPA) при каждом push в ветку `main`.

---

## Обзор

| Workflow | Файл | Runner | Результат |
|----------|------|--------|-----------|
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
   - **Flutter version** — версия SDK (по умолчанию `3.27.4`)
   - **Build type** (только Android) — `apk` или `appbundle`

---

## Этапы сборки (Android)

```
Checkout → Java 17 → Flutter SDK → pub get → flutter create → build_runner → build → upload
```

| Шаг | Команда | Описание |
|-----|---------|----------|
| Install dependencies | `flutter pub get` | Загрузка пакетов из pubspec.yaml |
| Generate Android files | `flutter create --platforms=android .` | Создание android/ директории |
| Run build_runner | `dart run build_runner build --delete-conflicting-outputs` | Генерация .freezed.dart и .g.dart |
| Build APK | `flutter build apk --release` | Сборка релизного APK |
| Build AAB | `flutter build appbundle --release` | Сборка App Bundle для Google Play |

### Почему `flutter create .`?

Директории `android/` и `ios/` не коммитятся в репозиторий (они генерируются Flutter). CI создаёт их на лету перед сборкой.

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
| Для тестирования | ✅ Да | ❌ Нет |
| Для публикации | ❌ Нет | ✅ Да |

По умолчанию workflow собирает **APK**. Для загрузки в Google Play запустите вручную с `build_type: appbundle`.

---

## Изменение версии Flutter

### Через workflow_dispatch

При ручном запуске укажите нужную версию в поле **Flutter version**.

### В коде workflow

Измените дефолтное значение в `.github/workflows/android.yml`:

```yaml
flutter-version: '3.27.4'  # ← здесь
```

И в `.github/workflows/ios.yml` аналогично.

---

## Отладка ошибок сборки

### 1. Ошибка `build_runner` (нет .freezed.dart)

```bash
# Локально проверить:
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Ошибка `flutter create`

Если в репозитории появились файлы, конфликтующие с генерируемыми (например, свой `android/`), удалите их перед запуском CI.

### 3. Android: Gradle error

Обычно связан с версией Java или AGP. Проверьте, что `java-version: '17'` соответствует вашей версии `android/build.gradle`.

### 4. iOS: Xcode version mismatch

macos-latest обновляется GitHub. Если сборка сломалась, можно pin-нуть Xcode:

```yaml
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '15.4'
```

---

## Полезные команды

```bash
# Запустить только Android workflow локально через act (необязательно)
brew install act
act push -W .github/workflows/android.yml

# Проверить синтаксис YAML
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/android.yml'))"

# Посмотреть логи последнего запуска
gh run list --limit 5
gh run view --log
```
