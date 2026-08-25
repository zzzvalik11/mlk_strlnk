#!/usr/bin/env python3
"""Generate architecture PDF for Starlink external service integrations."""

import sys, os

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.lib.colors import HexColor
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, Image,
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily
from reportlab.lib import colors

# ── Fonts (built-in, no CJK needed) ────────────────
BODY_FONT = 'Helvetica'
HEAD_FONT = 'Helvetica-Bold'
MONO_FONT = 'Courier'
C = {
    'page_bg':       HexColor('#f3f3f1'),
    'card_bg':       HexColor('#e9e8e4'),
    'header_fill':   HexColor('#716540'),
    'border':        HexColor('#c5bea8'),
    'accent':        HexColor('#887129'),
    'accent2':       HexColor('#4290aa'),
    'text':          HexColor('#252422'),
    'muted':         HexColor('#7f7d75'),
    'white':         colors.white,
    'success':       HexColor('#4a9965'),
    'warning':       HexColor('#ac8c4b'),
    'error':         HexColor('#894b46'),
    'info':          HexColor('#426b93'),
}

# ── Styles ─────────────────────────────────────────────

s_h1 = ParagraphStyle('h1', fontName=HEAD_FONT, fontSize=22, leading=28, textColor=C['text'], spaceAfter=10*mm, spaceBefore=4*mm)
s_h2 = ParagraphStyle('h2', fontName=HEAD_FONT, fontSize=16, leading=22, textColor=C['accent'], spaceAfter=6*mm, spaceBefore=8*mm)
s_h3 = ParagraphStyle('h3', fontName=HEAD_FONT, fontSize=13, leading=18, textColor=C['text'], spaceAfter=4*mm, spaceBefore=5*mm)
s_body = ParagraphStyle('body', fontName=BODY_FONT, fontSize=10, leading=16, textColor=C['text'], alignment=TA_JUSTIFY, spaceAfter=3*mm)
s_body_sm = ParagraphStyle('body_sm', fontName=BODY_FONT, fontSize=9, leading=14, textColor=C['text'], alignment=TA_JUSTIFY, spaceAfter=2*mm)
s_muted = ParagraphStyle('muted', fontName=BODY_FONT, fontSize=9, leading=13, textColor=C['muted'], spaceAfter=2*mm)
s_code = ParagraphStyle('code', fontName=MONO_FONT, fontSize=8.5, leading=13, textColor=HexColor('#3d3d3d'), backColor=HexColor('#f0efe9'), leftIndent=6, rightIndent=6, spaceBefore=2*mm, spaceAfter=3*mm, borderPadding=4)
s_bullet = ParagraphStyle('bullet', fontName=BODY_FONT, fontSize=10, leading=16, textColor=C['text'], leftIndent=12, bulletIndent=0, spaceAfter=2*mm)
s_table_head = ParagraphStyle('th', fontName=HEAD_FONT, fontSize=8.5, leading=12, textColor=C['white'], alignment=TA_CENTER)
s_table_cell = ParagraphStyle('tc', fontName=BODY_FONT, fontSize=8.5, leading=12, textColor=C['text'])
s_table_cell_c = ParagraphStyle('tcc', fontName=BODY_FONT, fontSize=8.5, leading=12, textColor=C['text'], alignment=TA_CENTER)
s_cover_title = ParagraphStyle('ct', fontName=HEAD_FONT, fontSize=32, leading=38, textColor=C['white'], alignment=TA_CENTER)
s_cover_sub = ParagraphStyle('cs', fontName=BODY_FONT, fontSize=14, leading=20, textColor=HexColor('#d4d0c8'), alignment=TA_CENTER)

PAGE_W, PAGE_H = A4
MARGIN = 22*mm
CONTENT_W = PAGE_W - 2*MARGIN

# ── Helpers ────────────────────────────────────────────
def h1(t): return Paragraph(t, s_h1)
def h2(t): return Paragraph(t, s_h2)
def h3(t): return Paragraph(t, s_h3)
def p(t): return Paragraph(t, s_body)
def ps(t): return Paragraph(t, s_body_sm)
def muted(t): return Paragraph(t, s_muted)
def code(t): return Paragraph(t, s_code)
def bullet(t): return Paragraph(t, s_bullet, bulletText=chr(8226))

def divider(): return HRFlowable(width='100%', thickness=0.5, color=C['border'], spaceBefore=4*mm, spaceAfter=4*mm)

def make_table(headers, rows, col_widths=None):
    """Create styled table."""
    hdr = [Paragraph(h, s_table_head) for h in headers]
    data = [hdr]
    for row in rows:
        data.append([Paragraph(str(c), s_table_cell) if i == 0 else Paragraph(str(c), s_table_cell_c) for i, c in enumerate(row)])
    if col_widths is None:
        col_widths = [CONTENT_W / len(headers)] * len(headers)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), C['header_fill']),
        ('TEXTCOLOR', (0, 0), (-1, 0), C['white']),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.4, C['border']),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            style_cmds.append(('BACKGROUND', (0, i), (-1, i), C['card_bg']))
    t.setStyle(TableStyle(style_cmds))
    return t

def flow_box(items, bg=C['card_bg']):
    """Wrap items in a colored box."""
    tbl = Table([[items]], colWidths=[CONTENT_W - 8*mm])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), bg),
        ('BOX', (0, 0), (-1, -1), 0.5, C['border']),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    return tbl

# ── Build Document ─────────────────────────────────────
OUTPUT = '/home/z/my-project/mlk_strlnk/docs/architecture_integration.pdf'
os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)

doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=MARGIN, rightMargin=MARGIN,
    topMargin=20*mm, bottomMargin=20*mm,
    title='Starlink - Architecture Integration',
    author='Z.ai',
    subject='External service integration architecture',
)

story = []

# ═══════════════════════════════════════════════════════
#  COVER
# ═══════════════════════════════════════════════════════
story.append(Spacer(1, 80*mm))
story.append(Paragraph('Starlink', ParagraphStyle('ct2', fontName=HEAD_FONT, fontSize=36, leading=42, textColor=C['accent'], alignment=TA_CENTER)))
story.append(Spacer(1, 4*mm))
story.append(Paragraph('Architecture Integration', ParagraphStyle('cs2', fontName=BODY_FONT, fontSize=18, leading=24, textColor=C['text'], alignment=TA_CENTER)))
story.append(Spacer(1, 8*mm))
story.append(HRFlowable(width='40%', thickness=1.5, color=C['accent'], spaceBefore=0, spaceAfter=8*mm, hAlign='CENTER'))
story.append(Paragraph('Payment Gateways | Push Notifications | SMS Gateway | Billing (BSS)', ParagraphStyle('tags', fontName=BODY_FONT, fontSize=10, leading=15, textColor=C['muted'], alignment=TA_CENTER)))
story.append(Spacer(1, 40*mm))
story.append(Paragraph('v2.0  |  August 2025', ParagraphStyle('ver', fontName=BODY_FONT, fontSize=10, leading=14, textColor=C['muted'], alignment=TA_CENTER)))
story.append(PageBreak())

# ═══════════════════════════════════════════════════════
#  1. OVERVIEW
# ═══════════════════════════════════════════════════════
story.append(h1('1. Overview'))
story.append(p(
    'This document describes the architecture for integrating five external services into the Starlink mobile app backend. '
    'The Flutter application communicates exclusively with a single backend API, which acts as an orchestrator between the mobile client '
    'and external providers: payment gateways (Payme, Click, Uzum), SBP (fast bank transfers), Firebase Cloud Messaging for push notifications, '
    'Eskiz SMS gateway for OTP delivery, and the telecom BSS (Business Support System) for billing operations. '
    'This design ensures that sensitive credentials, cryptographic keys, and provider-specific logic remain server-side, '
    'while the mobile app works with a unified, predictable REST API.'
))
story.append(p(
    'The key architectural principle is that the backend serves as a facade. The Flutter app never communicates directly with Payme, Click, '
    'Uzum, Firebase, Eskiz, or the BSS. All integrations are encapsulated within backend service modules, each responsible for a single '
    'external provider. This separation allows independent scaling, testing, and replacement of any integration without affecting '
    'the mobile client. The backend receives requests via the existing REST API, translates them into provider-specific calls, '
    'and returns normalized responses to the app.'
))

story.append(h2('1.1 System Diagram'))
story.append(p(
    'The following diagram illustrates the high-level data flow between the Flutter application, the backend API server, '
    'and the five categories of external services. All mobile traffic flows through HTTPS to the backend, '
    'which fans out to the appropriate providers. External services call back into the backend via webhooks '
    '(payment gateways) or server-to-server APIs (BSS, FCM, Eskiz).'
))

# ASCII diagram as code block
diagram = """
  +-----------+       HTTPS        +------------------+
  |  Flutter   | <===============> |   Backend API    |
  |    App     |    REST / JSON   |   (orchestrator) |
  +-----------+                  +--------+---------+
                                          |
              +-------+-------+------+-------+-------+
              |       |       |      |       |       |
              v       v       v      v       v       v
         +------+------+ +----+ +----+ +---+ +-----+ +-----+
         | Payme API  | |Click| |Uzum| |SBP| | FCM | |Eskiz|
         | (payments)  | |    | |    | |   | |(push)| |(SMS)|
         +------+------+ +----+ +----+ +---+ +-----+ +-----+
                                    |
                              +-----+-----+
                              |  BSS API   |
                              | (billing)  |
                              +------------+"""
story.append(code(diagram))

story.append(h2('1.2 Technology Stack'))
story.append(make_table(
    ['Layer', 'Technology', 'Role'],
    [
        ['Mobile', 'Flutter 3.x / Dart 3.13+', 'Client application, FCM token management'],
        ['Backend', 'Node.js / Express or NestJS', 'REST API, orchestration, webhook handling'],
        ['Database', 'PostgreSQL', 'Users, transactions, devices, payment sessions'],
        ['Cache', 'Redis', 'OTP codes, rate limits, session state'],
        ['Queue', 'Bull / RabbitMQ', 'Async push delivery, SMS retries'],
        ['Payments', 'Payme, Click, Uzum SDK', 'Payment processing, tokenization'],
        ['Push', 'Firebase Cloud Messaging', 'Push notifications to mobile devices'],
        ['SMS', 'Eskiz (eskiz.uz)', 'OTP delivery, service notifications'],
        ['Billing', 'BSS REST API', 'Balance, invoices, service management'],
    ],
    [CONTENT_W*0.15, CONTENT_W*0.30, CONTENT_W*0.55],
))

# ═══════════════════════════════════════════════════════
#  2. PAYMENT GATEWAYS
# ═══════════════════════════════════════════════════════
story.append(h1('2. Payment Gateways'))
story.append(p(
    'The payment integration supports three major Uzbekistan payment providers: Payme (payme.uz), Click (click.uz), '
    'and Uzum Pay (uzum.uz). Each provider offers slightly different capabilities: Payme supports both card payments and SBP '
    'transfers, Click focuses on card payments with recurring billing support, and Uzum provides installment payments (6/12/24 months) '
    'in addition to standard card processing. The backend abstracts these differences behind a unified payment interface.'
))

story.append(h2('2.1 Payment Flow'))
story.append(p(
    'The payment process follows a redirect-based pattern. When the user initiates a payment in the app, the Flutter client sends a '
    'POST /api/payments/create request with the amount, payment method, and optional description. The backend creates a payment '
    'session in its database, then calls the selected provider API to create a payment transaction. The provider returns a payment URL, '
    'which the backend sends back to the app. The app opens this URL in an in-app WebView. After the user completes or cancels '
    'the payment, the WebView closes and the app polls POST /api/payments/{paymentId}/status until it receives a terminal state '
    '(success, failed, or expired).'
))

steps = [
    '<b>1.</b> App calls <font color="#887129">POST /api/payments/create</font> with {amount, method, description}',
    '<b>2.</b> Backend creates payment record in DB (status: pending)',
    '<b>3.</b> Backend calls provider API (Payme/Click/Uzum) to create transaction',
    '<b>4.</b> Provider returns payment URL',
    '<b>5.</b> Backend saves URL, returns {paymentId, paymentUrl, expiresAt} to app',
    '<b>6.</b> App opens paymentUrl in WebView',
    '<b>7.</b> User completes payment in WebView',
    '<b>8.</b> Provider sends webhook to backend (POST /api/payments/webhook/{provider})',
    '<b>9.</b> Backend verifies webhook signature, updates DB, registers payment in BSS',
    '<b>10.</b> Backend sends push notification to user (payment success/failure)',
    '<b>11.</b> App polls GET /api/payments/{paymentId}/status, receives terminal state',
    '<b>12.</b> App updates UI, shows new balance',
]
for s in steps:
    story.append(bullet(s))

story.append(h2('2.2 Provider Comparison'))
story.append(make_table(
    ['Feature', 'Payme', 'Click', 'Uzum'],
    [
        ['Card payment', 'Yes', 'Yes', 'Yes'],
        ['SBP transfer', 'Yes', 'Yes', 'No'],
        ['Installments', 'No', 'No', '6/12/24 months'],
        ['Recurring', 'Yes (subscribe)', 'Yes (auto-pay)', 'No'],
        ['Min amount', '1 000 UZS', '1 000 UZS', '10 000 UZS'],
        ['Max amount', '15 000 000 UZS', '15 000 000 UZS', '30 000 000 UZS'],
        ['Webhook', 'Yes', 'Yes', 'Yes'],
        ['Refund API', 'Yes', 'Yes', 'Yes'],
        ['Tokenization', 'Yes (cards)', 'Yes (cards)', 'Yes (cards)'],
        ['Settlement', 'T+0', 'T+1', 'T+1'],
    ],
    [CONTENT_W*0.20, CONTENT_W*0.26, CONTENT_W*0.27, CONTENT_W*0.27],
))

story.append(h2('2.3 Security Considerations'))
story.append(p(
    'Payment security requires strict separation of concerns. Provider API keys (Payme ID/secret, Click merchant credentials, '
    'Uzum keys) are stored in backend environment variables and never exposed to the mobile client. All webhook callbacks '
    'are verified using provider-specific signatures: Payme uses SHA-1 HMAC of the request body with the merchant secret, '
    'Click uses a preparatory request/response signature exchange, and Uzum uses JWT-based authentication on webhooks. '
    'The backend validates the webhook signature before processing any payment status update, preventing spoofed callbacks.'
))
story.append(p(
    'Payment session URLs are single-use and expire after a configurable timeout (default: 30 minutes). The backend assigns each '
    'payment a unique paymentId (UUID v4) and stores the mapping between this ID, the provider transaction ID, and the user account. '
    'Idempotency is ensured by checking the paymentId on every webhook callback: duplicate notifications for the same paymentId '
    'are acknowledged but not reprocessed. All payment operations are logged in an immutable audit table for reconciliation.'
))

# ═══════════════════════════════════════════════════════
#  3. SBP (FAST BANK TRANSFERS)
# ═══════════════════════════════════════════════════════
story.append(h1('3. SBP (Fast Bank Transfers)'))
story.append(p(
    'The SBP (Fast Payment System) integration in the context of Uzbekistan is implemented through Payme and Click bank transfer '
    'capabilities. Unlike card payments, SBP allows users to pay directly from their bank mobile app (Kapitalbank, Uzcard, Humo, etc.) '
    'without entering card details. The payment flow is identical to the card payment flow: the app calls POST /api/payments/create '
    'with method=sbp, receives a payment URL, and opens it in WebView. The URL redirects to the Payme SBP page where the user selects '
    'their bank and confirms the payment in the bank app.'
))
story.append(p(
    'From the backend perspective, SBP does not require a separate integration module. It uses the existing Payme or Click payment '
    'module with a different payment type parameter. The provider handles the bank selection and transfer execution. The backend '
    'only needs to specify the payment_type as "sbp" when creating the transaction with Payme. Webhook handling and status polling '
    'remain identical to card payments. The Transaction entity in the database records the paymentMethod field as "sbp" for '
    'filtering and analytics purposes.'
))

story.append(flow_box([
    Paragraph('<b>SBP Flow Summary:</b> App requests method=sbp -> Backend calls Payme with type=sbp -> '
                  'Payme returns bank selection URL -> User selects bank in WebView -> Bank app opens -> '
                  'User confirms -> Webhook to backend -> Push to app', s_body_sm),
]))

# ═══════════════════════════════════════════════════════
#  4. PUSH NOTIFICATIONS (FCM)
# ═══════════════════════════════════════════════════════
story.append(h1('4. Push Notifications (FCM)'))
story.append(p(
    'Push notifications are delivered through Firebase Cloud Messaging (FCM). The integration requires a Firebase project '
    'configured with server key and the google-services.json / GoogleService-Info.plist files added to the Flutter app. '
    'On first launch after login, the app obtains an FCM device token and sends it to the backend via POST /api/devices/register. '
    'The backend stores this token in the database, linked to the user account. When an event occurs that requires notification '
    '(payment success, balance low, service expiring, support reply), the backend sends a push message through the FCM HTTP v1 API.'
))

story.append(h2('4.1 Token Lifecycle'))
story.append(p(
    'FCM device tokens are long-lived but can be invalidated by the user (clearing app data, reinstalling), by Firebase (token refresh), '
    'or by the OS (battery optimization). The app must handle token refresh by listening to the onTokenRefresh callback in the '
    'Firebase messaging plugin and re-registering the new token with the backend. The backend supports multiple devices per user '
    '(phone + tablet), so adding a new token does not invalidate previous ones. On logout, the app calls POST /api/devices/unregister '
    'to remove the token, preventing notifications from being sent to a logged-out device.'
))

story.append(h2('4.2 Notification Categories'))
story.append(p(
    'Users can control which notification categories they receive through the notification preferences API (GET/PUT /api/notifications/preferences). '
    'Each category can be independently enabled or disabled. When the backend prepares to send a push notification, it checks the user\'s '
    'preferences and suppresses the notification if the category is disabled. This check happens at send time, ensuring real-time '
    'preference changes take effect immediately. The following table lists all supported notification categories.'
))
story.append(make_table(
    ['Category', 'Trigger', 'Data in Push'],
    [
        ['paymentSuccess', 'Payment webhook received (status=success)', 'amount, method, newBalance'],
        ['paymentFailed', 'Payment webhook received (status=failed)', 'amount, errorMessage'],
        ['balanceLow', 'BSS reports balance below threshold', 'amount, paidUntil'],
        ['serviceExpiring', 'Service expires within 3 days', 'serviceName, expiryDate'],
        ['newsAndPromo', 'New news article published', 'title, summary'],
        ['supportReply', 'Support ticket receives reply', 'ticketId, subject'],
    ],
    [CONTENT_W*0.22, CONTENT_W*0.38, CONTENT_W*0.40],
))

story.append(h2('4.3 Flutter Implementation'))
story.append(p(
    'On the Flutter side, the app uses the firebase_messaging package. The main.dart initializes Firebase and requests notification '
    'permissions. A background message handler is registered for handling notifications when the app is terminated. The foreground '
    'handler updates the in-app notification badge count and optionally shows a local notification using the flutter_local_notifications '
    'package for richer display. The FCM token is obtained via FirebaseMessaging.instance.getToken() and sent to the backend '
    'immediately after successful login. The onTokenRefresh stream listener handles token updates automatically.'
))

# ═══════════════════════════════════════════════════════
#  5. SMS GATEWAY (ESKIZ)
# ═══════════════════════════════════════════════════════
story.append(h1('5. SMS Gateway (Eskiz)'))
story.append(p(
    'The SMS integration uses Eskiz (eskiz.uz), a popular SMS aggregation service in Uzbekistan that provides HTTP API access to '
    'multiple mobile operators (Uzmobile, Ucell, Beeline, Mobiuz). The primary use case is OTP (One-Time Password) delivery for '
    'two-factor authentication. When the user requests a login via SMS, the app calls POST /api/auth/request-otp with the phone number. '
    'The backend generates a random 6-digit code, stores it in Redis with a 3-minute TTL and a maximum of 3 verification attempts, '
    'then sends it via the Eskiz API. The user enters the code in the app, which submits it to POST /api/auth/verify-otp. '
    'The backend compares the code against the Redis value and returns a JWT token on success.'
))

story.append(h2('5.1 Rate Limiting and Anti-Abuse'))
story.append(p(
    'SMS delivery is rate-limited to prevent abuse and control costs. The backend enforces a per-phone-number rate limit of 1 OTP '
    'request per 60 seconds and a maximum of 5 requests per hour. These limits are implemented using Redis counters with TTL. '
    'If the rate limit is exceeded, the API returns HTTP 429 with a retryAfter field indicating seconds until the next allowed request. '
    'The OTP code itself is valid for 3 minutes and allows up to 3 verification attempts. After 3 failed attempts, the code is '
    'invalidated and the user must request a new one. All OTP requests and verification attempts are logged for fraud analysis.'
))

story.append(h2('5.2 Eskiz API Details'))
story.append(make_table(
    ['Parameter', 'Value'],
    [
        ['Base URL', 'https://notify.eskiz.uz/api'],
        ['Auth method', 'Bearer token (login/email -> token API)'],
        ['Send endpoint', 'POST /message/sms/send'],
        ['Token refresh', 'POST /auth/refresh (every 20 days)'],
        ['Batch send', 'POST /message/sms/send-batch'],
        ['Callback URL', 'Configurable per message'],
        ['Encoding', 'UTF-8, GSM 7-bit auto-detect'],
    ],
    [CONTENT_W*0.30, CONTENT_W*0.70],
))

# ═══════════════════════════════════════════════════════
#  6. BILLING (BSS)
# ═══════════════════════════════════════════════════════
story.append(h1('6. Billing System (BSS)'))
story.append(p(
    'The Business Support System (BSS) is the telecom operator\'s core system that manages subscriber accounts, service provisioning, '
    'rating, billing, and invoicing. The backend API communicates with the BSS via its REST API to perform real-time balance queries, '
    'service activation and deactivation, invoice generation, and payment registration. From the Flutter app\'s perspective, all BSS '
    'interactions are transparent: the app calls the usual /api/account/profile, /api/billing/invoice, or /api/transactions endpoints, '
    'and the backend translates these into BSS API calls.'
))

story.append(h2('6.1 BSS Integration Points'))
story.append(make_table(
    ['App Endpoint', 'BSS Operation', 'Direction'],
    [
        ['GET /api/account/profile', 'GetSubscriber + GetBalance + GetServices', 'Backend -> BSS'],
        ['GET /api/billing/invoice', 'GetCurrentInvoice', 'Backend -> BSS'],
        ['GET /api/billing/invoice/history', 'GetInvoiceHistory', 'Backend -> BSS'],
        ['POST /api/billing/services/{id}/activate', 'ActivateService', 'Backend -> BSS'],
        ['POST /api/billing/services/{id}/deactivate', 'DeactivateService', 'Backend -> BSS'],
        ['GET /api/transactions', 'GetTransactionHistory', 'Backend -> BSS'],
        ['Webhook /payments/webhook/{provider}', 'RegisterPayment', 'Backend -> BSS'],
    ],
    [CONTENT_W*0.35, CONTENT_W*0.40, CONTENT_W*0.25],
))

story.append(h2('6.2 Invoice Management'))
story.append(p(
    'The BSS generates monthly invoices for each subscriber. The invoice contains a breakdown of all active services with their '
    'daily rates, the number of days used in the billing period, the calculated cost for each service, applicable discounts, and the '
    'total amount due. The backend exposes this data through GET /api/billing/invoice (current period) and GET /api/billing/invoice/history '
    '(past periods with pagination). Invoice status transitions are managed by the BSS: pending -> paid (when payment webhook is received) '
    '-> overdue (after due date). The backend synchronizes invoice status from BSS on each request to ensure consistency.'
))

story.append(h2('6.3 Service Management'))
story.append(p(
    'Service activation and deactivation are requested through dedicated endpoints (POST /api/billing/services/{id}/activate and '
    '/deactivate). The backend forwards these requests to the BSS, which validates the request (e.g., checking if the service is '
    'compatible with the current tariff, if there are no outstanding debts, or if the service is already active). The BSS responds '
    'with success or a specific error code. The backend maps BSS error codes to HTTP status codes: 200 for success, 409 for conflicts '
    '(already active), and 422 for validation errors. Service changes take effect immediately in the BSS and are reflected '
    'in the next GET /api/account/profile call.'
))

# ═══════════════════════════════════════════════════════
#  7. API ENDPOINTS SUMMARY
# ═══════════════════════════════════════════════════════
story.append(h1('7. New API Endpoints Summary'))
story.append(p(
    'The following table summarizes all new endpoints added to the API specification (api.yaml v2.0) to support the five '
    'external service integrations. Existing endpoints (/auth/login, /account/profile, /transactions, /news, /support) remain '
    'unchanged in their request/response format, though some now have enriched behavior (e.g., transactions now include paymentMethod '
    'and providerTransactionId fields).'
))
story.append(make_table(
    ['Method', 'Endpoint', 'Purpose', 'Ext. Service'],
    [
        ['POST', '/auth/request-otp', 'Send SMS with OTP code', 'Eskiz'],
        ['POST', '/auth/verify-otp', 'Verify OTP, return JWT', 'Eskiz'],
        ['POST', '/payments/create', 'Create payment session', 'Payme/Click/Uzum'],
        ['GET', '/payments/{id}/status', 'Poll payment status', 'Payme/Click/Uzum'],
        ['POST', '/payments/webhook/{p}', 'Provider callback', 'Payme/Click/Uzum'],
        ['POST', '/devices/register', 'Register FCM token', 'Firebase'],
        ['POST', '/devices/unregister', 'Remove FCM token', 'Firebase'],
        ['GET', '/notifications/preferences', 'Get push settings', 'Firebase'],
        ['PUT', '/notifications/preferences', 'Update push settings', 'Firebase'],
        ['GET', '/billing/invoice', 'Current invoice from BSS', 'BSS'],
        ['GET', '/billing/invoice/history', 'Past invoices', 'BSS'],
        ['POST', '/billing/services/{id}/activate', 'Activate service', 'BSS'],
        ['POST', '/billing/services/{id}/deactivate', 'Deactivate service', 'BSS'],
    ],
    [CONTENT_W*0.08, CONTENT_W*0.32, CONTENT_W*0.32, CONTENT_W*0.28],
))

# ═══════════════════════════════════════════════════════
#  8. BACKEND MODULE STRUCTURE
# ═══════════════════════════════════════════════════════
story.append(h1('8. Backend Module Structure'))
story.append(p(
    'The backend should be organized into dedicated service modules, each encapsulating a single external integration. '
    'This modular architecture allows independent development, testing, and deployment of each integration. Each module exposes '
    'a consistent interface (create, getStatus, handleWebhook) that the API routes layer delegates to. The following structure '
    'is recommended for the Node.js/NestJS backend implementation.'
))

story.append(code(
    'src/<br/>'
    '  modules/<br/>'
    '    auth/                  # login, OTP request/verify<br/>'
    '    payment/<br/>'
    '      payment.service.ts  # unified payment interface<br/>'
    '      providers/<br/>'
    '        payme.service.ts   # Payme API wrapper<br/>'
    '        click.service.ts   # Click API wrapper<br/>'
    '        uzum.service.ts   # Uzum API wrapper<br/>'
    '      payment.controller.ts<br/>'
    '      payment.webhook.controller.ts<br/>'
    '    push/<br/>'
    '      fcm.service.ts      # Firebase Cloud Messaging<br/>'
    '      device.controller.ts<br/>'
    '    sms/<br/>'
    '      eskiz.service.ts    # Eskiz SMS gateway<br/>'
    '    billing/<br/>'
    '      bss.service.ts      # BSS API wrapper<br/>'
    '      invoice.controller.ts<br/>'
    '      service.controller.ts<br/>'
    '    account/               # existing profile logic<br/>'
    '    transaction/           # existing transaction logic<br/>'
    '  common/<br/>'
    '    config/                # env vars, provider credentials<br/>'
    '    database/              # PostgreSQL, TypeORM/Prisma<br/>'
    '    redis/                 # OTP cache, rate limits<br/>'
    '    queue/                 # Bull job queue'
))

# ═══════════════════════════════════════════════════════
#  9. IMPLEMENTATION PRIORITY
# ═══════════════════════════════════════════════════════
story.append(h1('9. Implementation Priority'))
story.append(p(
    'The recommended implementation order follows the dependency graph and business value. Payment integration should be '
    'implemented first since it directly enables revenue collection. Push notifications come second as they enhance the payment '
    'experience (users receive instant confirmation) and improve engagement. SMS/OTP is third, adding a second authentication '
    'factor. Billing integration is fourth, providing real invoice data instead of mock values. SBP is last because it builds '
    'on top of the existing Payme integration with minimal additional effort.'
))
story.append(make_table(
    ['Priority', 'Integration', 'Effort', 'Dependencies'],
    [
        ['P0 (Week 1-2)', 'Payme payment gateway', 'High', 'BSS payment registration'],
        ['P0 (Week 2-3)', 'Click payment gateway', 'Medium', 'Payment module from P0'],
        ['P1 (Week 3-4)', 'FCM push notifications', 'Medium', 'Firebase project setup'],
        ['P1 (Week 4-5)', 'Eskiz SMS / OTP', 'Low', 'Redis for rate limiting'],
        ['P2 (Week 5-6)', 'BSS billing integration', 'High', 'BSS API access, data mapping'],
        ['P2 (Week 6)', 'Uzum payment gateway', 'Medium', 'Payment module from P0'],
        ['P3 (Week 6)', 'SBP via Payme', 'Low', 'Payme module from P0'],
    ],
    [CONTENT_W*0.18, CONTENT_W*0.30, CONTENT_W*0.15, CONTENT_W*0.37],
))

# ── Build ────────────────────────────────────────────
doc.build(story)
print(f'PDF generated: {OUTPUT}')
