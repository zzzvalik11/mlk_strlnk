#!/usr/bin/env bash
# ─── Настройка deep link (starlink://) для Android и iOS ───
# Запускается ПОСЛЕ `flutter create --platforms=... .`
# Используется в CI и локально при первой настройке.

set -euo pipefail

SCHEME="starlink"
HOST="payment-callback.starlink.app"

# Portable in-place sed: Linux использует sed -i, macOS — sed -i ''
sed_inplace() {
  if [[ "$OSTYPE" == darwin* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ══════════════════════════════════════════════════════════════
# Android: добавляем intent-filter в AndroidManifest.xml
# ══════════════════════════════════════════════════════════════
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  MANIFEST="android/app/src/main/AndroidManifest.xml"

  if ! grep -q "$SCHEME" "$MANIFEST" 2>/dev/null; then
    # Вставляем intent-filter перед закрывающим </activity>
    INTENT_FILTER='\            <!-- Deep link: starlink:// -->\n\            <intent-filter>\n\                <action android:name="android.intent.action.VIEW" />\n\                <category android:name="android.intent.category.DEFAULT" />\n\                <category android:name="android.intent.category.BROWSABLE" />\n\                <data android:scheme="'"$SCHEME"'" android:host="'"$HOST"'" />\n\            </intent-filter>'

    sed_inplace "s|</activity>|${INTENT_FILTER}\n        </activity>|" "$MANIFEST"
    echo "[Android] Deep link intent-filter добавлен в $MANIFEST"
  else
    echo "[Android] Deep link уже настроен"
  fi
else
  echo "[Android] Файл android/app/src/main/AndroidManifest.xml не найден — пропускаем"
fi

# ══════════════════════════════════════════════════════════════
# iOS: добавляем CFBundleURLSchemes в Info.plist
# ══════════════════════════════════════════════════════════════
if [ -f "ios/Runner/Info.plist" ]; then
  PLIST="ios/Runner/Info.plist"

  if ! grep -q "$SCHEME" "$PLIST" 2>/dev/null; then
    python3 -c "
import sys
with open('$PLIST', 'r') as f:
    content = f.read()

dection = '''
        <key>CFBundleURLTypes</key>
        <array>
                <dict>
                        <key>CFBundleURLSchemes</key>
                        <array>
                                <string>$SCHEME</string>
                        </array>
                        <key>CFBundleURLName</key>
                        <string>$HOST</string>
                </dict>
        </array>'''

content = content.rstrip()
if content.endswith('</dict>'):
    content = content[:-len('</dict>')] + dection + '\n</dict>'

with open('$PLIST', 'w') as f:
    f.write(content)
"
    echo "[iOS] CFBundleURLSchemes добавлен в $PLIST"
  else
    echo "[iOS] Deep link уже настроен"
  fi
else
  echo "[iOS] Файл ios/Runner/Info.plist не найден — пропускаем"
fi

echo ""
echo "Настройка deep link завершена."
echo "URL scheme: $SCHEME://"
echo "Callback host: $HOST"
