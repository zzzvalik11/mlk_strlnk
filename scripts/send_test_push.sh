#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Send a test FCM push notification from the command line.
#
# Usage:
#   bash scripts/send_test_push.sh <DEVICE_TOKEN> [title] [body]
#
# DEVICE_TOKEN — printed in console at app start:
#                  [FCM] Device token: xxx...
#   or run:  adb shell logcat | grep FCM
#
# FCM_SERVER_KEY — set in .env or pass as env var.
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# --- Config ---
DEVICE_TOKEN="${1:?Usage: $0 <DEVICE_TOKEN> [title] [body]}"
TITLE="${2:-Test notification}"
BODY="${3:-Hello from Starlink!}"

# Load .env if present
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FCM_SERVER_KEY=""
if [ -f "$PROJECT_ROOT/.env" ]; then
  FCM_SERVER_KEY=$(grep '^FCM_SERVER_KEY=' "$PROJECT_ROOT/.env" | cut -d'=' -f2-)
fi

if [ -z "$FCM_SERVER_KEY" ]; then
  echo "ERROR: FCM_SERVER_KEY not set. Add it to .env:"
  echo "  FCM_SERVER_KEY=AAAA..."
  echo ""
  echo "Get it from: Firebase Console -> Project Settings -> Cloud Messaging -> Server key"
  exit 1
fi

echo "Sending push to: ${DEVICE_TOKEN:0:20}..."
echo "Title: $TITLE"
echo "Body:  $BODY"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=$FCM_SERVER_KEY" \
  -d '{
    "to": "'$DEVICE_TOKEN'",
    "notification": {
      "title": "'$TITLE'",
      "body": "'$BODY'",
      "sound": "default"
    },
    "priority": "high",
    "android": {
      "priority": "high"
    },
    "apns": {
      "payload": {
        "aps": { "sound": "default" }
      }
    }
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_RESP=$(echo "$RESPONSE" | sed '$d')

echo "HTTP $HTTP_CODE"
echo "$BODY_RESP" | python3 -m json.tool 2>/dev/null || echo "$BODY_RESP"

case "$HTTP_CODE" in
  200) echo "OK — notification sent!" ;;
  401) echo "ERROR — invalid server key" ;;
  404) echo "ERROR — invalid device token" ;;
  *)   echo "See response above" ;;
esac
