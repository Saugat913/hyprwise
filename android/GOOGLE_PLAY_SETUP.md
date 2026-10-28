# Google Play Store Integration Guide — Hyprwise

This document provides step-by-step instructions to link the Google Play Developer Console with Hyprwise for automated deployments and RevenueCat in-app purchase verification.

---

## 1. Service Account Credentials

Your official Google Play service account:
- **Project ID**: `hyprwise`
- **Client Email**: `hyprwise@hyprwise.iam.gserviceaccount.com`
- **Private Key**: Configured in `android/hyprwise-play-service-account.json` (gitignored for security).

---

## 2. Granting Access in Google Play Console (1-Minute Setup)

For Google Play Developer API to accept uploads from this service account, it must be invited as an authorized user in your Google Play Console:

1. Log in to [Google Play Console](https://play.google.com/console).
2. In the left navigation menu, click **Users and permissions**.
3. Click **Invite new users** (top right).
4. Enter the email address:
   ```
   hyprwise@hyprwise.iam.gserviceaccount.com
   ```
5. Under **App permissions**, click **Add app** and select:
   - **`com.hypr.hyprwise`** (Hyprwise)
6. Check the following permissions:
   - **Release apps to testing tracks**
   - **Manage testing tracks and edit tester lists**
   - **Release to production, exclude devices, and use Play App Signing**
   - **View app information and download bulk reports (read-only)**
   *(Or simply grant Admin access to this service account).*
7. Click **Apply** -> **Invite user** -> **Send invite**.

> [!NOTE]
> Since this is a service account, no email acceptance is needed; permissions activate immediately.

---

## 3. Linking with RevenueCat (In-App Subscriptions)

To enable Hyprwise Pro subscription validation on Android:

1. Open [RevenueCat Dashboard](https://app.revenuecat.com).
2. Select your Hyprwise project -> **Project Settings** -> **Apps** -> Select **Google Play (Android)**.
3. Under **Service Account credentials JSON**, click **Upload JSON**.
4. Select `android/hyprwise-play-service-account.json`.
5. Click **Save Changes**.

---

## 4. Automated Publishing CLI

### A. Direct Play Store Upload
Upload your release `.aab` directly to Google Play:
```bash
# Upload to Internal Testing track
node scripts/upload_to_playstore.js --track=internal --build

# Upload to Closed Testing (Alpha)
node scripts/upload_to_playstore.js --track=alpha --build

# Upload to Production
node scripts/upload_to_playstore.js --track=production --build

# Verify API connection without uploading
node scripts/upload_to_playstore.js --check-only
```

### B. Integrated Release Script
The automated release script supports one-command version bump, git tag, and Play Store upload:
```bash
# Internal release with direct Play Store deployment
./scripts/release.sh --type=internal --push --upload

# Production release with direct Play Store deployment
./scripts/release.sh --type=production --push --upload
```
