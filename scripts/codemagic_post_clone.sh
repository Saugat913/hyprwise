#!/usr/bin/env bash
set -e

echo "=== [Codemagic Post-Clone] 1. Generating .env configuration ==="
cat << EOF > .env
SERVER_URL=${SERVER_URL:-https://hyprwise.kandelsaugat913.workers.dev}
ENVIRONMENT=${ENVIRONMENT:-production}
REVENUECAT_APPLE_KEY=${REVENUECAT_APPLE_KEY:-}
REVENUECAT_GOOGLE_KEY=${REVENUECAT_GOOGLE_KEY:-goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy}
FIREBASE_IOS_API_KEY=${FIREBASE_IOS_API_KEY:-}
FIREBASE_ANDROID_API_KEY=${FIREBASE_ANDROID_API_KEY:-}
FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY:-}
APP_STORE_CONNECT_KEY_IDENTIFIER=${APP_STORE_CONNECT_KEY_IDENTIFIER:-VAF7GQY5U2}
APP_STORE_CONNECT_ISSUER_ID=${APP_STORE_CONNECT_ISSUER_ID:-1b2be7f4-cf12-440b-8e65-f0e39d6f6074}
EOF

echo "✓ Created .env successfully from Codemagic environment variables"

echo "=== [Codemagic Post-Clone] 2. Getting Flutter dependencies & configuring iOS ==="
flutter pub get
flutter build ios --config-only --no-codesign

echo "=== [Codemagic Post-Clone] 3. Installing CocoaPods dependencies ==="
cd ios && pod install --repo-update && cd ..

echo "=== [Codemagic Post-Clone] Project is fully configured for building! ==="
