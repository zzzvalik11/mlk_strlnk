# Архитектура интеграции со сторонними сервисами

> Версия: 3.0.0 | Дата: 2025-08-25

## Обзор

Мобильное приложение **Starlink** (личный кабинет абонента телеком-оператора) взаимодействует
с внешними сторонними сервисами исключительно через собственный бэкенд-прокси. Приложение
(Flutter) **напрямую не обращается** ни к одному внешнему сервису — все вызовы идут через
единую точку входа `/api`. Это обеспечивает безопасность (API-ключи и секреты хранятся
только на сервере), унификацию обработки ошибок и независимость от изменений в сторонних
API.

Бэкенд выступает **оркестратором**: принимает запросы от приложения, нормализует их,
направляет в нужный сторонний сервис, обрабатывает ответ и возвращает стандартизированный
результат клиенту.

```
┌──────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  Flutter App  │ ──API──▶│  Backend (proxy)  │ ──REST──▶│  Биллинг (BSS)   │
│              │         │  /api/*          │         │  starlink-api    │
│  Dio + JWT   │         │                  │         └──────────────────┘
└──────────────┘         │  ┌─────────────┐ │
                          │  │   Orchestr.  │ │ ──HTTP POST──▶ RSB ECOMM
                          │  └─────────────┘ │   (Платёжный шлюз)
                          │  ┌─────────────┐ │ ──REST───────▶ СБП API (Сбербанк)
                          │  │  Notification│ │ ──HTTP────────▶ Devino Telecom (SMS)
                          │  │   Scheduler  │ │ ──FCM─────────▶ Firebase Cloud Messaging
                          │  └─────────────┘ │
                          └──────────────────┘
```

---

## 1. Платёжный шлюз — Банк Русский Стандарт (RSB ECOMM)

### 1.1 Назначение

Приём платежей банковскими картами (Visa, MasterCard, МИР) за услуги связи.
Поддерживаются разовые платежи (SMS), двухстадийные (DMS), рекуррентные (автоплатежи)
и оплата через СБП на стороне банка.

### 1.2 Спецификация

- **Документ**: `rsb_ecomm_api_ru.pdf` (версия 3.0.17)
- **Протокол**: HTTP POST (form-urlencoded) → SSL
- **Аутентификация**: SSL-сертификат клиента + IP-адрес сервера
- **Тестовый URL**: `https://testsecurepay2.rsb.ru:9443/ecomm2/MerchantHandler`
- **Боевой URL**: `https://securepay2.rsb.ru/ecomm2/MerchantHandler`
- **Платёжная страница**: `https://securepay2.rsb.ru/ecomm2/ClientHandler?trans_id=<trans_id>`

### 1.3 Схема интеграции

Используется **схема 3.1** — ввод карточных данных на стороне Банка. Это значит,
что приложение не получает и не хранит номер карты — клиент вводит реквизиты на
платёжной странице РСБ, проходя 3D Secure при необходимости.

#### Поток оплаты (SMS — одностадийная):

```
1. App ──POST /api/payments/create──▶ Backend
2. Backend ──command=v&amount=...&currency=643──▶ RSB ECOMM
3. RSB ──TRANSACTION_ID: <trans_id>──▶ Backend
4. Backend ──{ paymentUrl: "https://...ClientHandler?trans_id=..." }──▶ App
5. App ──WebView (платёжная страница РСБ)──▶ Клиент вводит карту + 3DS
6. РSB ──POST redirect──▶ Backend RETURN_URL
7. Backend ──command=c&trans_id=<id>──▶ RSB (статус)
8. Backend ──обновляет Биллинг + отправляет Push──▶ FCM
9. App ──polling GET /api/payments/{id}/status──▶ Backend
```

### 1.4 Используемые команды РСБ

| Команда | Описание | Когда используется |
|---------|----------|-------------------|
| `-v` | Регистрация SMS-транзакции (одностадийная) | Основной метод оплаты картой |
| `-c` | Запрос статуса транзакции | После возврата клиента с платёжной страницы |
| `-t` | Выполнение/Расчёт DMS | Двухстадийная оплата (блокировка → списание) |
| `-r` | Отмена транзакции | До закрытия бизнес дня, полная сумма |
| `-k` | Возврат средств | Полный или частичный, после закрытия бизнес дня |
| `-z` | Сохранение карты + SMS платёж | Регистрация автоплатежа (рекарринг) |
| `-e` | Оплата по сохранённой карте (SMS) | Повторное списание автоплатежа |
| `-x` | Удаление шаблона рекарринга | Отключение автоплатежа |
| `-b` | Закрытие бизнес дня | Раз в сутки (cron) |

### 1.5 Ключевые параметры запросов

**Регистрация SMS-транзакции (`command=v`):**

| Параметр | Тип | Обяз. | Описание |
|----------|------|-------|----------|
| `command` | string | Да | Значение `v` |
| `amount` | number | Да | Сумма в копейках (последние 2 цифры — копейки) |
| `currency` | string | Да | Код валюты ISO 4217 (643 — рубль) |
| `client_ip_addr` | string | Да | IP-адрес клиента (приложение передаёт, бэкенд пробрасывает) |
| `description` | string | Нет | Описание платежа (макс. 125 символов, UTF-8) |
| `mrch_transaction_id` | string | Нет | Идентификатор заказа в системе партнёра (UUID, URL-safe) |
| `language` | string | Нет | Язык платёжной страницы (`ru` / `en`) |
| `server_version` | string | Нет | `2.0` для получения расширенных деталей |
| `email_client` | string | Нет | Email клиента (для риск-менеджмента) |
| `phone_client` | string | Нет | Телефон клиента (для риск-менеджмента) |

### 1.6 Ответы и статусы

**Поля ответа на запрос статуса (`command=c`):**

| Поле | Описание |
|------|----------|
| `RESULT` | `OK` / `FAILED` / `CREATED` / `PENDING` / `REVERSED` / `TIMEOUT` |
| `RESULT_PS` | `FINISHED` / `ACTIVE` / `CANCELLED` |
| `RESULT_CODE` | 3-значный код (000 — успех) |
| `3DSECURE` | `AUTHENTICATED` / `FAILED` / `NOTPARTICIPATED` / `ATTEMPTED` |
| `RRN` | Номер поисковой ссылки (RRN) |
| `APPROVAL_CODE` | Код подтверждения от платёжной системы |
| `CARD_NUMBER` | Маскированный номер карты (5***2372) |
| `MRCH_TRANSACTION_ID` | Идентификатор заказа партнёра |

### 1.7 Маппинг статусов РСБ → API приложения

| РСБ RESULT + RESULT_PS | Статус в api.yaml | Описание для пользователя |
|-------------------------|-------------------|------------------------|
| `OK` + `FINISHED` | `success` | Оплата прошла успешно |
| `OK` + `ACTIVE` | `pending` | Транзакция создана, ожидает завершения |
| `CREATED` | `created` | Транзакция зарегистрирована |
| `PENDING` | `pending` | Выполнение продолжается |
| `FAILED` / DECLINED | `failed` | Ошибка оплаты |
| `REVERSED` / `AUTOREVERSED` | `refunded` | Операция отменена |
| (timeout, не обновлённая) | `expired` | Время ожидания истекло (10 мин) |

---

## 2. Система быстрых платежей (СБП)

### 2.1 Назначение

Оплата услуг связи через Систему быстрых платежей (НСПК). Клиент сканирует QR-код
или переходит по платёжной ссылке в банковское приложение для подтверждения платежа.

### 2.2 Спецификация

- **Документ**: `openapi_sbp.json` (версия 1.0.0)
- **Протокол**: REST JSON API
- **Провайдер**: Сбербанк (агрегатор СБП)
- **Эндпоинты**:
  - `POST /api/v1/create` — создание платежа
  - `GET /api/v1/status/{order_id}` — статус платежа
  - `GET /api/v1/cancel/{order_id}` — отмена платежа
  - `POST /api/v1/refund/{order_id}` — возврат (полный/частичный)
  - `POST /api/v1/callback` — коллбэк от Сбербанка

### 2.3 Схема интеграции

СБП работает через промежуточный сервис Сбербанка. Наш бэкенд вызывает его API,
получает платёжную ссылку и QR-код, которые передаются в приложение. Приложение
отображает QR-код или открывает ссылку в банковском приложении клиента.

```
1. App ──POST /api/payments/create (method=sbp)──▶ Backend
2. Backend ──POST /api/v1/create { amount, account }──▶ СБП API (Сбербанк)
3. СБП ──{ qrcode_link, qr_url, order_id, status }──▶ Backend
4. Backend ──{ paymentUrl: qrcode_link, paymentId }──▶ App
5. App ──показывает QR / открывает банковское приложение──▶ Клиент платит
6. СБП ──POST /api/v1/callback──▶ Backend (уведомление об оплате)
7. Backend ──обновляет Биллинг + отправляет Push──▶ FCM
8. App ──polling GET /api/payments/{id}/status──▶ Backend
```

### 2.4 Модели данных СБП

**Запрос создания платежа (`PaymentCreateRequest`):**

| Поле | Тип | Обяз. | Описание |
|------|------|-------|----------|
| `amount` | number | Да | Сумма в рублях (не в копейках!) |
| `account` | string | Да | Номер лицевого счёта (макс. 6 символов) |
| `phone` | string | Нет | Телефон плательщика |
| `email` | string | Нет | Email плательщика |
| `paymentStat` | string | Нет | Источник платежа (по умолчанию `sbpStat`) |

**Ответ создания платежа (`PaymentCreateResponse`):**

| Поле | Тип | Описание |
|------|------|----------|
| `success` | boolean | Успешность операции |
| `sbp_id` | integer | ID записи в таблице PAY_SBP_LOG2 |
| `rq_uid` | string | Уникальный идентификатор запроса |
| `order_id` | string | ID заказа в Сбербанке |
| `qrcode_link` | string | Платёжная ссылка для QR-кода |
| `qr_url` | string | URL формы оплаты |
| `amount` | string | Сумма платежа |
| `status` | PaymentState | Статус (CREATED, PAID, и т.д.) |

**Статусы платежа СБП (`PaymentState`):**

| Статус | Описание |
|--------|----------|
| `CREATED` | Платёж создан, ожидает оплаты |
| `ON_PAYMENT` | Платёж в процессе |
| `AUTHORIZED` | Авторизован, но не завершён |
| `CONFIRMED` | Подтверждён |
| `PAID` | Оплачен |
| `DECLINED` | Отклонён |
| `REVERSED` | Отменён |
| `REVOKED` | Аннулирован |
| `REFUNDED` | Возврат выполнен |
| `EXPIRED` | Срок действия истёк |

### 2.5 Маппинг статусов СБП → API приложения

| СБП Status | Статус в api.yaml | Действие |
|------------|-------------------|----------|
| `CREATED` / `ON_PAYMENT` | `pending` | Показать QR, ждать оплаты |
| `PAID` | `success` | Обновить баланс, отправить Push |
| `DECLINED` | `failed` | Показать ошибку |
| `REVERSED` / `REVOKED` | `refunded` | Оплата отменена |
| `REFUNDED` | `refunded` | Возврат выполнен |
| `EXPIRED` | `expired` | Ссылка/QR просрочены |

### 2.6 Возвраты СБП

Возврат выполняется через `POST /api/v1/refund/{order_id}`. Если `amount` не указан —
возвращается полная сумма. СБП через Сбербанк поддерживает как полные, так и
частичные возвраты.

---

## 3. Push-уведомления — Firebase Cloud Messaging (FCM)

### 3.1 Назначение

Мгновенные уведомления пользователю об успешном платеже, низком балансе,
истечении услуги, ответе техподдержки и других событиях.

### 3.2 Спецификация

- **Провайдер**: Google Firebase Cloud Messaging
- **Протокол**: HTTP v1 API (Firebase Admin SDK)
- **Аутентификация**: Service Account JSON (на бэкенде)
- **Регистрация устройства**: через наш бэкенд `/api/devices/register`

### 3.3 Схема интеграции

```
                        ┌──────────────────┐
                        │  FCM Server      │
                        │  (Google)        │
                        └────────▲─────────┘
                                 │ HTTP v1
                                 │ (multicast)
┌──────────────┐         ┌────────┴─────────┐
│  Flutter App  │ ──token─▶│  Backend         │
│  (FCM plugin) │         │  ┌─────────────┐ │
└──────▲───────┘         │  │  Push       │ │
       │ Push           │  │  Dispatcher  │ │
       │                 │  └─────────────┘ │
└───────┘                 └──────────────────┘
```

### 3.4 Жизненный цикл

1. **Регистрация**. Приложение получает FCM-токен при запуске и отправляет его
   на бэкенд через `POST /api/devices/register`. Бэкенд сохраняет привязку
   `user_id → fcm_token → platform` в БД.

2. **Отправка**. При наступлении события (платёж, баланс, тикет) бэкенд формирует
   payload и отправляет через Firebase Admin SDK (HTTP v1 API). Поддерживаются
   как отдельные сообщения, так и multicast-рассылки.

3. **Обработка в приложении**. Firebase messaging plugin получает push,
   показывает уведомление в трее (foreground service) или как системное
   уведомление (background). При тапе — навигация на соответствующий экран.

4. **Отвязка**. При выходе из аккаунта приложение вызывает
   `POST /api/devices/unregister`.

### 3.5 Категории уведомлений

| Категория | Триггер | payload.type |
|-----------|---------|---------------|
| Успешный платёж | Webhook от РСБ / Callback от СБП | `payment_success` |
| Ошибка платежа | Webhook / polling | `payment_failed` |
| Низкий баланс | Проверка в биллинге (cron) | `balance_low` |
| Услуга истекает | Проверка в биллинге (cron) | `service_expiring` |
| Ответ поддержки | Обновление тикета | `support_reply` |
| Новости и акции | Публикация новости | `news` |

### 3.6 Payload push-уведомления

```json
{
  "notification": {
    "title": "Оплата прошла успешно",
    "body": "Списано 500 р. Баланс: 1 500 р.",
    "sound": "default"
  },
  "data": {
    "type": "payment_success",
    "paymentId": "pay_a1b2c3d4",
    "amount": 50000,
    "newBalance": 150000,
    "screen": "/payment"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "payments",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  },
  "token": "dGhpcyBpcyBhIGZha2UgdG9rZW4="
}
```

### 3.7 Настройки уведомлений

Пользователь управляет категориями через `GET/PUT /api/notifications/preferences`.
Бэкенд проверяет предпочтения перед отправкой каждого push.

---

## 4. SMS — Devino Telecom

### 4.1 Назначение

Отправка SMS-сообщений абонентам: OTP-коды для авторизации, уведомления об
операциях, информационные рассылки.

### 4.2 Спецификация

- **Провайдер**: Devino Telecom
- **Протокол**: REST JSON API
- **Базовый URL**: `https://api.devino.tel`
- **Аутентификация**: HTTP Basic Auth (`Authorization: Basic base64(login:password)`)

### 4.3 Эндпоинты Devino

| Метод | URL | Описание |
|-------|-----|----------|
| `POST` | `/sms/send` | Отправка SMS |
| `GET` | `/sms/status/{id}` | Статус отправки |
| `GET` | `/sms/balance` | Остаток средств |

### 4.4 Отправка SMS

**Запрос:**
```
POST /sms/send
Authorization: Basic <base64(login:password)>
Content-Type: application/json

{
  "messages": [{
    "phone": "79001234567",
    "text": "Ваш код: 482916. Действует 3 мин.",
    "sender": "Starlink"
  }]
}
```

**Ответ:**
```json
{
  "status": "ok",
  "messages": [{
    "id": "msg_001",
    "phone": "79001234567",
    "status": "queued"
  }]
}
```

### 4.5 Сценарии использования

| Сценарий | Триггер | Шаблон |
|----------|---------|----------|
| OTP при авторизации | `POST /api/auth/request-otp` | «Код: {code}. Действует {ttl} мин.» |
| Уведомление об оплате | Webhook от РСБ/СБП | «Оплата {amount} р. Баланс: {balance} р.» |
| Низкий баланс | Cron-проверка биллинга | «Баланс {amount} р. Пополните счёт.» |
| Уведомление оператору | Создание тикета поддержки | «Новое обращение: {subject}» |

### 4.6 Ограничения и безопасность

- **Rate limit**: 1 SMS на номер в 60 секунд (для OTP)
- **Максимум попыток OTP**: 3 (после — требуется повторный запрос)
- **Срок действия OTP**: 180 секунд (3 минуты)
- **Маскировка логина Devino**: хранится в переменных окружения бэкенда
- **Формат телефона**: `7XXXXXXXXXX` (11 цифр, без `+`)

---

## 5. Биллинг — Starlink BSS API

### 5.1 Назначение

Основная бизнес-система оператора связи. Управляет абонентами, счетами, услугами,
тарифами, транзакциями, пакетами и рассылкой уведомлений.

### 5.2 Спецификация

- **Документ**: `openapi.json` (версия 1.0.0)
- **Протокол**: REST JSON API
- **Аутентификация**: JWT Bearer Token (получается через `POST /api/v1/auth/token`)
- **Формат ответов**: `{ success: bool, data: ..., message: str, code: int }`

### 5.3 Эндпоинты биллинга (используемые приложением)

| Метод | Эндпоинт | Описание | Маппинг в api.yaml |
|-------|----------|----------|---------------------|
| `POST` | `/api/v1/auth/token` | Авторизация (PIN + пароль) | `POST /auth/login` |
| `POST` | `/api/v1/auth/logout` | Выход из системы | `POST /auth/logout` |
| `GET` | `/api/v1/subscriber` | Данные абонента | `GET /account/profile` |
| `GET` | `/api/v1/subscriber/accounts` | Список счетов | Входит в профиль |
| `GET` | `/api/v1/subscriber/accounts/{id}` | Конкретный счёт | Входит в профиль |
| `PATCH` | `/api/v1/subscriber/accounts/{id}` | Обновление счёта (suspend/promised-pay) | `PATCH /account/{id}` |
| `GET` | `/api/v1/subscriber/accounts/{id}/services` | Активные услуги | `GET /account/profile` (вложено) |
| `PATCH` | `/api/v1/subscriber/accounts/{id}/services/{sid}` | Смена тарифа, приостановка | `PATCH /billing/services/{id}` |
| `GET` | `/api/v1/subscriber/accounts/{id}/services/{sid}/tariffs` | Доступные тарифы | `GET /billing/services/{id}/tariffs` |
| `GET` | `/api/v1/subscriber/accounts/{id}/services/{sid}/additional-services` | Доп. услуги | `GET /billing/services/{id}/additional` |
| `PATCH` | `.../additional-services/{asid}` | Подключение/отключение доп. услуги | `PATCH /billing/additional/{id}` |
| `POST` | `/api/v1/subscriber/accounts/{id}/transactions` | История транзакций | `GET /transactions` |
| `GET` | `/api/v1/subscriber/accounts/{id}/pay-link` | Ссылка на оплату | `GET /payments/pay-link` |
| `GET` | `/api/v1/subscriber/accounts/{id}/auto-payment-link` | Автоплатёж ссылка | `GET /payments/auto-pay-link` |
| `GET` | `/api/v1/subscriber/accounts/{id}/auto-payment-off` | Отключить автоплатёж | `POST /payments/auto-pay-off` |
| `GET` | `/api/v1/resources/promised-pay-terms` | Условия обещанного платежа | `GET /billing/promised-pay` |
| `POST` | `/api/v1/subscriber/shop` | Заказ услуги | `POST /billing/shop` |
| `POST` | `/api/v1/support/send-email` | Обращение в поддержку | `POST /support` |
| `GET` | `/api/v1/notifications/send` | Отправить push | (внутренний, бэкенд) |
| `GET` | `/api/v1/bundles` | Пакеты услуг | `GET /billing/bundles` |
| `GET` | `/api/v1/bundles/{id}` | Детали пакета | `GET /billing/bundles/{id}` |
| `GET` | `/api/v1/tariff-types` | Типы тарифов | `GET /billing/tariff-types` |

### 5.4 Ключевые модели данных биллинга

**Авторизация (`AuthRequest`):**

| Поле | Тип | Описание |
|------|------|----------|
| `username` | string | ПИН-код (6 цифр) |
| `password` | string | Пароль (мин. 4 символа) |

**Обновление счёта (`AccountUpdateRequest`):**

| Поле | Тип | Описание |
|------|------|----------|
| `action` | string | `suspend` / `unsuspend` / `promised-pay` |
| `date_start` | string | Дата начала (для suspend) |
| `date_end` | string | Дата окончания (для suspend) |

**Изменение услуги (`ChangeServiceRequest`):**

| Поле | Тип | Описание |
|------|------|----------|
| `action` | string | `change-tariff` / `suspend` / `unsuspend` |
| `tariffId` | integer | Новый ID тарифа (для change-tariff) |
| `date_start` | string | Дата начала |
| `date_end` | string | Дата окончания |

**Доп. услуга (`AdditionalServiceActionRequest`):**

| Поле | Тип | Описание |
|------|------|----------|
| `action` | integer | `0` = отключить, `1` = подключить |

**Транзакции (`TransactionsRequest`):**

| Поле | Тип | Описание |
|------|------|----------|
| `start_date` | string | Начало периода (YYYY-MM-DD) |
| `end_date` | string | Конец периода (YYYY-MM-DD) |

---

## 6. Общая схема взаимодействия

### 6.1 Карта эндпоинтов приложения (api.yaml)

Приложение обращается к своему бэкенду по следующим маршрутам. Каждый маршрут
проксируется в один или несколько внешних сервисов.

```
Приложение (Flutter)                Бэкенд (/api)               Внешние сервисы
─────────────────                ──────────────               ────────────────

POST /auth/login         ──────▶  Биллинг /auth/token     ──────▶  BSS
POST /auth/request-otp   ──────▶  Devino /sms/send       ──────▶  Devino Telecom
POST /auth/verify-otp    ──────▶  (внутренняя проверка)              
GET  /account/profile    ──────▶  BSS /subscriber         ──────▶  Биллинг
POST /payments/create    ──────▶  RSB (command=v) ИЛИ     ──────▶  РСБ / СБП
                                 СБП /api/v1/create
GET  /payments/{id}/status─────▶  RSB (command=c) ИЛИ     ──────▶  РСБ / СБП
                                 СБП /api/v1/status/{id}
POST /payments/webhook/{p} ◀────  (от шлюза/СБП)         ◀─────  РСБ / Сбербанк
GET  /transactions        ──────▶  BSS /accounts/{id}/transactions ─▶  Биллинг
POST /devices/register   ──────▶  (сохранение в БД)                    
POST /devices/unregister ──────▶  (удаление из БД)                    
GET  /notifications/prefs ──────▶  (из БД / Биллинга)                 
PUT  /notifications/prefs ──────▶  (сохранение в БД)                 
GET  /billing/invoice      ──────▶  BSS /subscriber         ──────▶  Биллинг
POST /billing/services/{id}/activate ─▶  BSS /services/{id} ──────▶  Биллинг
POST /support             ──────▶  BSS /support/send-email ──────▶  Биллинг + Devino
```

### 6.2 Обработка платежей (оркестрация)

Бэкенд выступает координатором при оплате:

1. **Создание записи** в локальной БД со статусом `pending`.
2. **Вызов платёжного сервиса** (РСБ или СБП) в зависимости от `method`.
3. **Возврат URL** для WebView (РСБ) или QR-кода (СБП) в приложение.
4. **Получение webhook/callback** от платёжного сервиса.
5. **Обновление записи** в локальной БД.
6. **Вызов биллинга** для начисления средств на счёт абонента.
7. **Отправка Push** через FCM об успешном платеже.
8. **Отправка SMS** (опционально) через Devino.

### 6.3 Обработка ошибок

Приложение не получает прямой доступ к ошибкам внешних сервисов. Бэкенд
нормализует их в стандартный формат:

```json
{
  "error": "payment_failed",
  "message": "Платёжный шлюз временно недоступен. Попробуйте позже."
}
```

| Внешний сервис | Тип ошибки | HTTP-код в api.yaml | Сообщение для пользователя |
|----------------|-------------|---------------------|--------------------------|
| РСБ ECOMM | Таймаут (10 мин) | 408 / `expired` | «Время ожидания истекло» |
| РСБ ECOMM | DECLINED | 422 / `failed` | «Банк отклонил операцию» |
| РСБ ECOMM | RESULT_CODE != 000 | 502 / `failed` | «Ошибка платёжного шлюза» |
| СБП | DECLINED | 422 / `failed` | «Платёж отклонён» |
| СБП | EXPIRED | 410 / `expired` | «Срок действия ссылки истёк» |
| Devino | Недостаточно средств | 503 / `error` | «Сервис уведомлений недоступен» |
| Биллинг | Таймаут | 504 / `error` | «Сервис временно недоступен» |
| Биллинг | Неверные данные | 422 / `validation_error` | «Проверьте введённые данные» |

---

## 7. Безопасность

### 7.1 Хранение секретов

Все ключи и секреты хранятся **исключительно на бэкенде** в переменных окружения:

| Секрет | Где используется | Переменная окружения |
|--------|-----------------|----------------------|
| Merchant ID РСБ | Заголовок запросов РСБ | `RSB_MERCHANT_ID` |
| SSL-сертификат РСБ | mTLS к РСБ ECOMM | `RSB_SSL_CERT_PATH`, `RSB_SSL_KEY_PATH` |
| СБП API URL | Вызовы СБП API | `SBP_API_BASE_URL` |
| СБП API Key | Заголовок запросов СБП | `SBP_API_KEY` |
| Devino login:password | Basic Auth | `DEVINO_LOGIN`, `DEVINO_PASSWORD` |
| FCM Service Account | Firebase Admin SDK | `GOOGLE_APPLICATION_CREDENTIALS` |
| Биллинг JWT secret | Подпись токенов биллинга | `BILLING_JWT_SECRET` |

### 7.2 Защита на уровне приложения

- JWT-токен хранится в `flutter_secure_storage`
- Все запросы идут через `ApiClient` с автоматической подстановкой `Authorization: Bearer <token>`
- URL-кодировка `trans_id` при редиректе на `ClientHandler` (символы `+`, `=`, `/` → `%XX`)
- WebView для платёжной страницы РСБ с валидацией URL (только домен `rsb.ru`)

### 7.3 Валидация webhook/callback

- **РСБ ECOMM**: Проверка по IP-адресу источника (Банк предоставляет список IP)
- **СБП**: Проверка HMAC-подписи в теле callback (ключ предоставляется Сбербанком)
- **Devino**: Не требуется (исходящие только)

---

## 8. Требования к бэкенду

### 8.1 Стек

- Язык: Python (FastAPI) или Node.js (NestJS/Express)
- HTTP-клиент: `httpx` / `axios` с поддержкой mTLS
- БД: PostgreSQL (учётные записи, FCM-токены, платёжные сессии)
- Очередь: Redis + Bull/Celery (для асинхронной отправки push/sms)
- Cron: Планировщик задач (закрытие бизнес-дня РСБ, проверка балансов)

### 8.2 Критические фоновые задачи

| Задача | Периичность | Что делает |
|--------|-------------|-------------|
| Закрытие бизнес-дня РСБ | 1 раз в сутки (23:50) | `command=b` в РСБ ECOMM |
| Проверка низкого баланса | 1 раз в сутки (09:00) | Запрос в Биллинг → Push/SMS |
| Проверка истекающих услуг | 1 раз в сутки (09:00) | Запрос в Биллинг → Push/SMS |
| Очистка устаревших токенов | 1 раз в неделю | Удаление неактивных FCM-токенов |
| Синхронизация статусов | Каждые 5 мин | Polling СБП/РСБ по зависшим платежам |
