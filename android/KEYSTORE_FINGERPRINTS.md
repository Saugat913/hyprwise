# Hyprwise Android Keystore & Certificate Fingerprints

This file contains the SHA-1 and SHA-256 fingerprints for Hyprwise (`com.hypr.hyprwise`).
These values are required for Firebase Authentication (Google Sign-In), Google Cloud Console OAuth 2.0 client IDs, and Play App Signing.

---

## 1. Production / Upload Keystore (Release Builds)

- **Keystore File**: `android/app/upload-keystore.jks`
- **Keystore Type**: PKCS12
- **Key Alias**: `upload`
- **Validity**: 10,000 days (~27 years)
- **Distinguished Name (DName)**: `CN=Hyprwise, OU=Mobile, O=Hypr, L=Kathmandu, ST=Bagmati, C=NP`

### Fingerprints
- **SHA-1**:
  ```
  63:3F:03:75:50:5A:AC:60:33:04:4D:FB:99:EE:2C:13:AE:BB:73:99
  ```
- **SHA-256**:
  ```
  88:51:32:22:AB:85:92:0E:81:D5:1B:4C:D3:DE:4A:C3:03:53:19:A9:4F:73:0E:11:4B:35:2A:C3:F8:AD:86:DF
  ```

---

## 2. Debug Keystore (Local Development & Testing)

- **Keystore File**: `~/.android/debug.keystore`
- **Key Alias**: `androiddebugkey`
- **Password**: `android`

### Fingerprints
- **SHA-1**:
  ```
  42:05:6C:61:CD:D4:D9:D7:BA:60:F5:F4:3C:7A:AC:6F:AB:23:C5:E1
  ```
- **SHA-256**:
  ```
  83:FF:6A:E6:0A:57:C0:7F:50:11:CD:C3:5E:4A:32:FE:19:20:31:06:33:3D:F8:91:37:F9:BE:98:4A:8F:F1:38
  ```

---

## 3. How to Inspect Keystore Fingerprints

To regenerate or verify these fingerprints at any time via terminal:

```bash
# Upload Keystore
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload

# Debug Keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

---

## 4. Google Play App Signing (Post-Upload)

Once your `.aab` is uploaded to the Google Play Console, Google re-signs the app with their **Play App Signing key**.
You must also copy the Play App Signing SHA-1 and SHA-256 fingerprints from:
> **Google Play Console** $\rightarrow$ **Release** $\rightarrow$ **Setup** $\rightarrow$ **App Integrity** $\rightarrow$ **App signing key certificate**

and add them to **Firebase Console** under **Project Settings $\rightarrow$ Your apps $\rightarrow$ com.hypr.hyprwise**.
