#!/usr/bin/env bash
set -e

echo "=== [Codemagic Post-Clone] 1. Dynamically injecting system environment variables into .env ==="

# Initialize or clean .env
rm -f .env
touch .env

# Export all current system environment variables safely into .env
while IFS= read -r -d '' var; do
  key="${var%%=*}"
  val="${var#*=}"
  # Include valid variable identifiers and single-line values
  if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [[ ! "$val" =~ $'\n' ]]; then
    # Exclude internal shell functions and terminal escape codes
    if [[ ! "$key" =~ ^(BASH_FUNC_|LS_COLORS|TERMCAP|LESSOPEN|LESSCLOSE) ]]; then
      echo "$key=$val" >> .env
    fi
  fi
done < <(env -0)

# Ensure essential defaults if not already present in the environment
if ! grep -q "^SERVER_URL=" .env || [ -z "$SERVER_URL" ]; then
  echo "SERVER_URL=https://hyprwise.kandelsaugat913.workers.dev" >> .env
fi
if ! grep -q "^ENVIRONMENT=" .env || [ -z "$ENVIRONMENT" ]; then
  echo "ENVIRONMENT=production" >> .env
fi
if ! grep -q "^REVENUECAT_GOOGLE_KEY=" .env && [ -z "$REVENUECAT_GOOGLE_KEY" ]; then
  echo "REVENUECAT_GOOGLE_KEY=goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy" >> .env
fi
if ! grep -q "^APP_STORE_CONNECT_KEY_IDENTIFIER=" .env && [ -z "$APP_STORE_CONNECT_KEY_IDENTIFIER" ]; then
  echo "APP_STORE_CONNECT_KEY_IDENTIFIER=VAF7GQY5U2" >> .env
fi
if ! grep -q "^APP_STORE_CONNECT_ISSUER_ID=" .env && [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
  echo "APP_STORE_CONNECT_ISSUER_ID=1b2be7f4-cf12-440b-8e65-f0e39d6f6074" >> .env
fi

echo "✓ Successfully exported $(wc -l < .env) environment variables into .env"

echo "=== [Codemagic Post-Clone] 2. Getting Flutter dependencies & configuring iOS ==="
flutter pub get
flutter build ios --config-only --no-codesign

echo "=== [Codemagic Post-Clone] 3. Installing CocoaPods dependencies ==="
cd ios && pod install --repo-update && cd ..

echo "=== [Codemagic Post-Clone] Project is fully configured for building! ==="
