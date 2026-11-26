# Hyprwise Infrastructure & CI/CD Setup Requirements

This document provides the single, exhaustive guide for setting up all credentials, environment variables, secrets, and services required to run the **Hyprwise Flutter App**, **Cloudflare Workers Backend**, **Codemagic CI/CD Automation**, and **Discord Build Notifications**.

---

## Architecture Overview

```
                                      ┌────────────────────────────────────────────────────────┐
                                      │                      Codemagic CI/CD                   │
                                      │  (Groups: android_signing, google_play,                │
                                      │   app_store_credentials, app_config)                   │
                                      └──────────────┬─────────────────────────┬───────────────┘
                                                     │                         │
                                    Builds AAB & IPA │                         │ Build Finished Webhook
                                                     │                         │ (POST /api/builds/notify)
                                                     ▼                         ▼
                              ┌───────────────────────────────┐     ┌──────────────────────────┐
                              │  Google Play & TestFlight     │     │ Cloudflare Worker Server │
                              │  - Play Internal Track (AAB)  │     │ - /admin Dashboard       │
                              │  - TestFlight Release (IPA)   │     │ - D1 Database            │
                              └───────────────────────────────┘     └──────────┬───────────────┘
                                                                               │
                                                                               │ Rich Embed Webhook
                                                                               ▼
                                                                    ┌──────────────────────────┐
                                                                    │   Discord Build Channel  │
                                                                    │   (#hyprwise-builds)     │
                                                                    └──────────────────────────┘
```

---

## Part 1: Codemagic CI/CD (Application Settings)

In the **Codemagic Web Console** (`https://codemagic.io`):
1. Navigate to your app: **Hyprwise**.
2. Click **Application settings** $\rightarrow$ **Environment variables**.
3. Create the following **4 Group Names** with their corresponding variables.

---

### Group 1: `android_signing`
Used by `internal-testing` and `production-release` workflows to sign the release `.aab` bundles.

| Variable Key | Type / Secure? | How to Obtain / Description |
|---|---|---|
| `FCI_KEYSTORE` | Secret (Checked) | Base64 representation of your Android `.jks` release keystore file. <br/>Generate on Linux/macOS: `base64 -w 0 upload-keystore.jks` |
| `FCI_KEYSTORE_PASSWORD` | Secret (Checked) | The master password used when creating the keystore file. |
| `FCI_KEY_ALIAS` | Standard Text | The alias identifier of the signing key (e.g., `upload` or `hyprwise_key`). |
| `FCI_KEY_PASSWORD` | Secret (Checked) | The password specifically protecting the key alias. |

---

### Group 2: `google_play`
Used to deploy release builds automatically to the Google Play Console tracks.

| Variable Key | Type / Secure? | How to Obtain / Description |
|---|---|---|
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Secret (Checked) | The entire content of your Google Cloud Service Account JSON key that has permissions to publish to Google Play. <br/>(Obtained from Google Cloud Console $\rightarrow$ Service Accounts $\rightarrow$ Keys $\rightarrow$ JSON). |

---

### Group 3: `app_store_credentials`
Used by the `ios-testflight` workflow for automatic iOS Code Signing and App Store Connect publishing.

| Variable Key | Type / Secure? | How to Obtain / Description |
|---|---|---|
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Standard Text | 10-character Key ID from App Store Connect (e.g., `D3ABC12345`). |
| `APP_STORE_CONNECT_ISSUER_ID` | Standard Text | UUID Issuer ID from App Store Connect (e.g., `57246542-96fe-1a63-e053-0824d011072a`). |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Secret (Checked) | The full text of the downloaded `.p8` private key file, including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`. |

---

### Group 4: `app_config`
Injected dynamically into `.env` at build time for both Android and iOS apps.

| Variable Key | Type / Secure? | Example Value / Description |
|---|---|---|
| `SERVER_URL` | Standard Text | `https://hyprwise.kandelsaugat913.workers.dev` (or your custom domain `https://api.hyprwise.app`) |
| `REVENUECAT_GOOGLE_KEY` | Standard Text | RevenueCat Google Play API Key (starts with `goog_`, e.g. `goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy`) |
| `REVENUECAT_APPLE_KEY` | Standard Text | RevenueCat Apple App Store API Key (starts with `appl_`) |
| `BUILD_WEBHOOK_SECRET` | Secret (Optional) | Optional secret token if you want to protect `POST /api/builds/notify`. |

---

## Part 2: Cloudflare Worker Backend Server

The backend runs in `server/` on Cloudflare Workers with D1 Database.

### 1. Public Variables (`server/wrangler.toml`)
These are committed in the repository configuration:

```toml
[vars]
HOST = "0.0.0.0"
PORT = "3000"
FIREBASE_PROJECT_ID = "tilvane"
FIREBASE_CLIENT_EMAIL = "firebase-adminsdk-fbsvc@tilvane.iam.gserviceaccount.com"
GOOGLE_PROJECT_ID = "projects/218890071998"
GOOGLE_PROJECT_NUMBER = "218890071998"
REVENUECAT_WEBHOOK_AUTH = "hyprwise_webhook_secret_2026"
```

### 2. Encrypted Secrets (Set via Wrangler CLI or Cloudflare Dashboard)
Run these commands in the `/home/saugat/projects/finance_tracker/server` directory to set the secrets:

#### A. Discord Webhook URL (For Real-Time CI/CD Notifications)
```bash
cd server
npx wrangler secret put DISCORD_WEBHOOK_URL
# When prompted, paste: https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

#### B. Google Gemini API Key (For AI Intelligence & OCR Bill Scanner)
```bash
cd server
npx wrangler secret put GEMINI_API_KEY
# When prompted, paste your API key from Google AI Studio (https://aistudio.google.com/)
```

#### C. RevenueCat Secret Key (Optional Server Verification)
```bash
cd server
npx wrangler secret put REVENUECAT_SECRET_KEY
# When prompted, paste your RevenueCat v1 Secret API key (sk_...)
```

#### D. Build Webhook Secret (Optional Authentication)
```bash
cd server
npx wrangler secret put BUILD_WEBHOOK_SECRET
# (Only needed if you configured BUILD_WEBHOOK_SECRET in Codemagic app_config)
```

---

## Part 3: Discord Webhook Setup Guide

To receive automated, color-coded build notifications with direct links to Codemagic builds:

1. Open **Discord** and navigate to your target server.
2. Select or create a channel (e.g. `#hyprwise-builds` or `#ci-cd`).
3. Click the channel **Settings (Gear icon)** $\rightarrow$ **Integrations** $\rightarrow$ **Webhooks**.
4. Click **New Webhook**.
   - Name: `Hyprwise CI/CD`
   - Avatar: (Upload app logo from `assets/icons/app_icon.png`)
5. Click **Copy Webhook URL**.
6. Set this URL as `DISCORD_WEBHOOK_URL` in Cloudflare Workers (see Part 2 above).

### Sample Discord Embed Output:
- 🟢 **Success**: `🚀 Hyprwise Build #102 Succeeded`
  - Workflow: `Hyprwise TestFlight (App Store Connect)`
  - Branch: `dev`
  - Commit: `5108c99` (clickable link to GitHub)
  - Codemagic: `[View Logs & Artifacts]` (clickable direct link to build)
- 🔴 **Failure**: `❌ Hyprwise Build #103 Failed`
  - Instantly alerts with direct link to view build logs.

---

## Part 4: App Store Connect (iOS TestFlight Setup)

### 1. Generate App Store Connect API Key
1. Go to [App Store Connect](https://appstoreconnect.apple.com/) $\rightarrow$ **Users and Access**.
2. Click the **Integrations** tab (or **Keys**).
3. Under **App Store Connect API**, click the **+** button to generate an API Key.
   - Name: `Codemagic CI Key`
   - Access: **App Manager** or **Admin**.
4. Note down:
   - **Issuer ID** (at the top of the page) $\rightarrow$ Codemagic: `APP_STORE_CONNECT_ISSUER_ID`
   - **Key ID** $\rightarrow$ Codemagic: `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - Download the `.p8` private key file $\rightarrow$ Codemagic: `APP_STORE_CONNECT_PRIVATE_KEY`
   *(⚠️ Note: The `.p8` file can only be downloaded once from Apple!)*

### 2. Apple Bundle Identifier & App Record
1. In [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list), ensure the Identifier `com.hypr.hyprwise` exists with:
   - **Sign In with Apple** enabled.
2. In App Store Connect, ensure the App record for **Hyprwise** exists with Bundle ID `com.hypr.hyprwise`.

---

## Part 5: Google Play Console (Android Publishing Setup)

### 1. Google Cloud Service Account
1. Open the [Google Cloud Console](https://console.cloud.google.com/) linked to your Play Console.
2. Go to **IAM & Admin** $\rightarrow$ **Service Accounts** $\rightarrow$ **Create Service Account**.
   - Name: `codemagic-publisher`
3. Grant Role: **Service Account User**.
4. Under **Keys**, click **Add Key** $\rightarrow$ **Create new key** $\rightarrow$ **JSON**.
5. Save this JSON file $\rightarrow$ Codemagic: `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`.

### 2. Link Service Account in Google Play Console
1. Open [Google Play Console](https://play.google.com/console).
2. Go to **Setup** $\rightarrow$ **API access**.
3. Under **Service accounts**, find the newly created service account and click **Manage permissions**.
4. Grant permissions:
   - **Releases**: Manage production releases, Manage testing track releases.
   - **App information**: View app information.

### 3. Generate Android Keystore (If not already created)
```bash
keytool -genkey -v -keystore hyprwise-upload-key.jks \
  -alias hyprwise_upload \
  -keyalg RSA -keysize 2048 -validity 10000
```
Encode for Codemagic:
```bash
base64 -w 0 hyprwise-upload-key.jks
```

---

## Part 6: RevenueCat Configuration

### 1. RevenueCat Dashboard Settings
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com/).
2. Create project: **Hyprwise**.
3. Under **Project Settings** $\rightarrow$ **Apps**:
   - Add **Google Play** app $\rightarrow$ Copy Public API Key (`goog_...`).
   - Add **App Store** app $\rightarrow$ Copy Public API Key (`appl_...`).
4. Under **Entitlements**:
   - Create entitlement: `hyprwise_pro` (exact identifier).
5. Under **Offerings**:
   - Create offering: `default` with monthly and annual packages.
6. Under **Integrations** $\rightarrow$ **Webhooks**:
   - Webhook URL: `https://<YOUR_SERVER_URL>/api/revenuecat/webhook`
   - Authorization Header: `hyprwise_webhook_secret_2026`

---

## Part 7: Pre-Flight Verification Checklist

Before pushing commits to trigger builds, verify each item:

- [ ] **Codemagic**: All 4 groups created (`android_signing`, `google_play`, `app_store_credentials`, `app_config`).
- [ ] **Codemagic**: `SERVER_URL` matches your active Cloudflare Worker domain.
- [ ] **Cloudflare Worker**: `DISCORD_WEBHOOK_URL` secret is set via `wrangler secret put`.
- [ ] **Cloudflare Worker**: `GEMINI_API_KEY` secret is set via `wrangler secret put`.
- [ ] **App Store Connect**: API Key created with `.p8` pasted into Codemagic.
- [ ] **Google Play Console**: Service account linked and granted release permissions.
- [ ] **RevenueCat**: `hyprwise_pro` entitlement configured and keys added to Codemagic `app_config`.

---

*Document maintained for Hyprwise (`com.hypr.hyprwise`). Follows AGENTS.md single source of truth guidelines.*
