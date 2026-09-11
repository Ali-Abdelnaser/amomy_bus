# Amomy Bus — Authentication & Identity Setup (Day 2B)

## 1. Overview & Architectural Principles

The Amomy Passenger App provides cross-platform identity management for both **Android** and **iOS** passengers. 
Authentication is structured under **Clean Architecture** with complete separation of presentation, domain, and data layers:

- **State Management**: [AuthBloc](file:///d:/Flutter_Projects/amomy_bus/lib/features/auth/presentation/bloc/auth_bloc.dart) managing distinct state transitions (`AuthInitial`, `AuthLoading`, `Unauthenticated`, `EmailVerificationRequired`, `ProfileCompletionRequired`, `Authenticated`, `AuthFailureState`).
- **Auth Methods**:
  1. **Email + Password**: Full registration with metadata (`full_name`, `phone`, `gender`, `date_of_birth`), triggering Supabase `handle_new_user()` to create profile, wallet, and assign the `passenger` role.
  2. **Native Google Sign-In**: Native SDK login exchanging OpenID Connect `idToken` via `signInWithIdToken`. Followed by profile completeness verification for missing fields (`CompleteProfilePage`).
- **No Phone OTP**: Email verification code is used exclusively.

---

## 2. Project Package & Bundle Identifiers

Both platforms are aligned to the official package namespace:

| Platform | Property | Configured Value |
| :--- | :--- | :--- |
| **Android** | `namespace` / `applicationId` | `com.aliabdelnaser.amomy` |
| **iOS** | `PRODUCT_BUNDLE_IDENTIFIER` | `com.aliabdelnaser.amomy` |
| **iOS Tests** | `PRODUCT_BUNDLE_IDENTIFIER` | `com.aliabdelnaser.amomy.RunnerTests` |
| **Android minSdk** | `minSdkVersion` | 21 (Flutter default) |
| **Android compile/target** | `compileSdkVersion` / `targetSdkVersion` | Latest Flutter stable |
| **iOS Deployment Target**| `IPHONEOS_DEPLOYMENT_TARGET` | 13.0 |

---

## 3. Keystore Fingerprints (Active Environment)

From the local Android debug keystore:

* **Debug SHA-1**:
  ```
  72:AF:04:4E:E5:61:80:FD:B9:CF:7F:BB:3B:52:3E:DC:5D:3B:2D:E5
  ```
* **Debug SHA-256**:
  ```
  26:46:24:08:7D:0B:E0:56:14:CF:0A:49:9D:4D:05:A3:6C:7D:7D:4D:47:3B:90:54:6C:B7:CF:95:03:01:59:6F
  ```

*(Note for production: When creating the Google Play upload keystore or enabling Play App Signing, extract the release SHA-1/SHA-256 and register them in Google Cloud Console).*

---

## 4. Supabase Email Template Configuration (Mandatory Action)

The passenger application uses a **6-digit verification code UX** ([AppOtpField](file:///d:/Flutter_Projects/amomy_bus/lib/core/widgets/app_text_field.dart#L182)) via `supabase.auth.verifyOTP(email: ..., token: ..., type: OtpType.signup)` instead of requiring the passenger to click a redirect link.

### Owner Dashboard Setup:
1. Open [Supabase Dashboard](https://supabase.com/dashboard/project/vexqglrlwfallmjfhisv) → **Authentication** → **Email Templates**.
2. Under **Confirm signup**:
   Replace the default link button with the OTP Token code:
   ```html
   <h2>Welcome to Amomy Bus</h2>
   <p>Your verification code is:</p>
   <h1 style="font-size: 32px; letter-spacing: 6px; color: #01589F; font-family: monospace;">{{ .Token }}</h1>
   <p>Enter this 6-digit code in the application to activate your account. This code expires shortly.</p>
   ```
3. Under **Reset Password**:
   Configure the recovery link to redirect to:
   ```
   {{ .SiteURL }}/login-callback?token_hash={{ .TokenHash }}&type=recovery
   ```
   or include `{{ .Token }}` if recovery code entry is preferred.

---

## 5. Google Sign-In Architecture (Android + iOS)

```
[Flutter UI: GoogleSignInButton]
           ↓
[GoogleSignIn.instance.authenticate()]
           ↓
[GoogleSignInAccount & GoogleSignInAuthentication]
           ↓ (extracts idToken)
[supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)]
           ↓
[Supabase Auth User Created / Restored]
           ↓
[Database Trigger: public.handle_new_user()]
   → Creates public.profiles
   → Creates public.wallets (cash_points: 0, subscription_points: 0)
   → Inserts public.user_roles (role: 'passenger')
           ↓
[AuthBloc Profile Completeness Evaluation]
   → If phone/gender/date_of_birth is missing → route to /complete-profile
   → Else → route to /home
```

### Google Cloud Console OAuth Setup:
1. Create a project in [Google Cloud Console](https://console.cloud.google.com/).
2. Create **Web application** client ID:
   - Name: `Amomy Supabase Web Client`
   - Authorized redirect URIs: `https://vexqglrlwfallmjfhisv.supabase.co/auth/v1/callback`
   - **Client ID**: Used as `GOOGLE_WEB_CLIENT_ID` in Flutter `--dart-define` and configured in Supabase.
   - **Client Secret**: Configured **strictly** in Supabase dashboard. NEVER placed in Flutter code.
3. Create **Android** client ID:
   - Package name: `com.aliabdelnaser.amomy`
   - SHA-1 certificate fingerprint: `AF:0E:E4:D5:54:C9:8E:B3:94:7D:98:70:37:E0:65:D8:1D:66:24:82` (or machine debug keystore SHA-1)
   - *(Note: Android uses package name + SHA-1 fingerprint registration; no Dart client ID is needed on Android)*.
4. Create **iOS** client ID:
   - Bundle ID: `com.aliabdelnaser.amomy`
   - **Client ID**: `133458950988-t4vgheihpqper0v884pv1vmckeknqdcg.apps.googleusercontent.com`
   - **Reversed Client ID URL Scheme**: `com.googleusercontent.apps.133458950988-t4vgheihpqper0v884pv1vmckeknqdcg`
   - Configured directly into `ios/Runner/Info.plist` under `CFBundleURLSchemes` and `GIDClientID`.

### Running with Public OAuth Client IDs:
Pass the public IDs via `--dart-define`:
```bash
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
```

### Supabase Google Provider Setup:
1. Open [Supabase Dashboard](https://supabase.com/dashboard/project/vexqglrlwfallmjfhisv) → **Authentication** → **Providers** → **Google**.
2. Enable Google.
3. Paste:
   - **Client ID**: (Web Application Client ID)
   - **Client Secret**: (Web Application Client Secret)
4. Enable **Skip nonce check** for native mobile SDK tokens (`signInWithIdToken`).
5. Save.

---

## 6. Deep Linking & Redirect URLs

### Configured Schemes:
- **Android Intent Filter** ([android/app/src/main/AndroidManifest.xml](file:///d:/Flutter_Projects/amomy_bus/android/app/src/main/AndroidManifest.xml)):
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="com.aliabdelnaser.amomy" android:host="login-callback" />
  </intent-filter>
  ```

- **iOS URL Types** ([ios/Runner/Info.plist](file:///d:/Flutter_Projects/amomy_bus/ios/Runner/Info.plist)):
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>com.aliabdelnaser.amomy</string>
          </array>
      </dict>
  </array>
  ```

### Supabase Redirect URLs:
Add the following URL to **Authentication** → **URL Configuration** → **Redirect URLs**:
```
com.aliabdelnaser.amomy://login-callback
```

---

## 7. Account Collision & Identity Linking

If a passenger originally creates an account with email + password (`commuter@example.com`), and later taps **Continue with Google** using the exact same email:
1. Supabase Auth identifies the matching verified email address according to project settings.
2. The identities are unified under the existing `auth.users.id`.
3. The existing profile, wallet points balance, and roles are preserved.
4. No duplicate database rows or conflicting wallet balances are created.

---

## 8. Critical Security Invariants

* **No Secrets in Flutter**:
  - `service_role` key is **NEVER** placed in the mobile application.
  - Google Client Secret is **NEVER** placed in the mobile application.
  - Only the public anon key (`SUPABASE_ANON_KEY`) is bundled into the client.
* **Database Privilege Isolation**:
  - Direct updates to `wallets` or `user_roles` are blocked by RLS.
  - Profile updates allow users to edit only their own `full_name`, `phone`, `gender`, `date_of_birth`, and `avatar_url` ([profiles_update_unified](file:///d:/Flutter_Projects/amomy_bus/supabase/migrations/20260911040000_backend_phase1_final_hardening.sql#L123)).
