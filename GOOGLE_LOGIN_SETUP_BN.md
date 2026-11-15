# Google Login সম্পূর্ণ করার গাইড (Mess Pilot)

এই ডকুমেন্টে আছে — Google Login কাজ করার জন্য কী কী ডেটা লাগবে, Google Cloud Console থেকে সেগুলো কীভাবে নিতে হবে, এবং Android-এ debug / release / Play Store-এর SHA কীভাবে আলাদা হয়।

---

## ১. এই মুহূর্তে প্রজেক্টে কী আছে

| জিনিস | অবস্থা | কোথায় |
| --- | --- | --- |
| Backend Google verify endpoint | আছে | `POST /api/v1/auth/google` → `AuthManagement/views.py` |
| Backend token verify logic | আছে | `AuthManagement/google_auth.py` |
| Flutter native Google button | আছে | `google_sign_in_button_io.dart` |
| Flutter web Google button | আছে | `google_sign_in_button_web.dart` |
| Web OAuth client ID | আছে (hardcoded default) | `AppConstants.googleWebClientId` |
| Android OAuth client ID | backend `.env`-এ আছে (`...7voice...`) | `mm_backend/.env` |
| iOS OAuth client ID | **নেই** (empty) | `AppConstants.googleIosClientId` |
| iOS URL scheme (`REVERSED_CLIENT_ID`) | **নেই** | `ios/Runner/Info.plist` |
| Backend accepted client IDs | আছে, তবে iOS ID নেই | `GOOGLE_OAUTH_CLIENT_IDS` |
| Android debug SHA-1 | আছে | local debug keystore |
| Android release/upload keystore | **নেই** (release-এ debug signing ব্যবহার হচ্ছে) | `android/app/build.gradle.kts` |
| Play App Signing SHA | **নেই** (Play Console-এ অ্যাপ এখনো দেওয়া হলে নিতে হবে) | Play Console |

বর্তমানে ব্যবহৃত ID:

```text
Web client ID      : YOUR_GOOGLE_WEB_CLIENT_ID
Android client ID  : YOUR_GOOGLE_ANDROID_CLIENT_ID
Android package    : com.goraso.messpilot
iOS bundle ID      : com.goraso.messpilot
iOS team ID        : Q7U8S53NZ6
Web domain         : https://messpilot.goraso.com
Debug SHA-1        : A9:DF:F4:C6:D9:44:45:28:0C:BE:AA:E8:48:C8:5F:B8:33:56:0E:D5
Debug SHA-256      : 53:72:FE:18:40:A3:BC:F1:70:E6:A9:41:93:10:3F:A1:B2:98:AF:DE:67:4F:85:B7:81:83:19:D8:7B:5A:25:3C
```

> নোট: `web/.well-known/assetlinks.json`-এ যে SHA-256 আছে সেটা **App Links**-এর জন্য, Google Login-এর জন্য নয়। Google Login Android-এ **SHA-1** ব্যবহার করে।

---

## ২. মোট কী কী ডেটা দরকার (চেকলিস্ট)

### Google Cloud Console
- [ ] একটি Google Cloud Project (বর্তমানে `mess-management-2600a` ব্যবহার হচ্ছে)
- [ ] OAuth consent screen পূরণ করা
- [ ] **Web application** OAuth client (আছে) + Authorized JavaScript origins
- [ ] **Android** OAuth client: package name + SHA-1 (debug, upload, Play App Signing)
- [ ] **iOS** OAuth client: bundle ID + Team ID

### Android
- [ ] Debug keystore-এর SHA-1
- [ ] Release/upload keystore তৈরি + তার SHA-1
- [ ] Play Console-এর App Signing certificate SHA-1 (Play থেকে ইনস্টল হলে)
- [ ] (App Links-এর জন্য আলাদাভাবে SHA-256 → `assetlinks.json`)

### iOS
- [ ] iOS OAuth client ID
- [ ] `REVERSED_CLIENT_ID` (URL scheme)
- [ ] `Info.plist`-এ `CFBundleURLTypes` যোগ করা

### Web
- [ ] Authorized JavaScript origins: `https://messpilot.goraso.com`, `http://localhost:54302`, `http://127.0.0.1:54302`

### Backend
- [ ] `GOOGLE_OAUTH_CLIENT_IDS`-এ Web + Android + iOS — সব client ID কমা দিয়ে
- [ ] Vercel-এ একই env variable সেট করা

### Flutter build
- [ ] iOS build-এ `--dart-define=GOOGLE_IOS_CLIENT_ID=...`
- [ ] চাইলে Web/Server ID-ও `--dart-define` দিয়ে override

---

## ৩. Google Cloud Console থেকে ডেটা নেওয়ার ধাপ

1. https://console.cloud.google.com/ এ যান।
2. উপরের ড্রপডাউন থেকে সঠিক প্রজেক্ট সিলেক্ট করুন (`mess-management-2600a`)।
3. বাঁ দিকে **APIs & Services → OAuth consent screen** (নতুন UI-তে **Google Auth Platform**)।
4. নিচের তথ্য দিন:
   - App name: `Mess Pilot`
   - User support email
   - App logo (ঐচ্ছিক)
   - Authorized domains: `goraso.com`
   - Developer contact email
   - Privacy policy: `https://messpilot.goraso.com/privacy-policy`
   - Terms of service: `https://messpilot.goraso.com/terms-and-conditions`
   - Scopes: `openid`, `email`, `profile`
   - Publishing status: টেস্টের সময় **Testing** (Test users যোগ করুন), পাবলিক করার সময় **Publish app**
5. **APIs & Services → Credentials → Create Credentials → OAuth client ID**।
6. ধরন অনুযায়ী তথ্য দিন (নিচের সেকশনগুলো দেখুন)।
7. তৈরি হওয়ার পর **Client ID** কপি করুন। (Client secret শুধু web server flow-এ লাগে; এখানে লাগবে না।)

---

## ৪. Android: debug vs release vs Play Store — SHA আলাদা কেন?

Android-এ Google Sign-In (Credential Manager) কাজ করে **package name + signing certificate-এর SHA-1** মিলিয়ে। প্রতিটি আলাদা keystore = আলাদা SHA-1। তাই একই অ্যাপের একাধিক Android OAuth client বানাতে হয় — package একই, শুধু SHA-1 আলাদা।

তিনটি আলাদা SHA হতে পারে:

| কোনটি | কখন ব্যবহার হয় | কোথায় যোগ করবেন |
| --- | --- | --- |
| Debug SHA-1 | `flutter run` / debug APK | Android OAuth client (debug) |
| Upload/Release SHA-1 | নিজের release APK/AAB বা Play-তে upload | Android OAuth client (upload) |
| Play App Signing SHA-1 | Play Store থেকে ইনস্টল করা অ্যাপ | Android OAuth client (Play) |

> Play App Signing চালু থাকলে Play Google-এর নিজের key দিয়ে অ্যাপ re-sign করে। ফলে ফোনে যে অ্যাপ ইনস্টল হয় তার SHA-1 = **Play App Signing certificate SHA-1**, আপনার upload key নয়। তাই Google Login-এর জন্য Play-এর SHA-1 অবশ্যই যোগ করতে হবে।

### ৪.১ Debug SHA-1 বের করা (macOS)

```sh
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android \
  | grep -E "SHA1|SHA256"
```

এই প্রজেক্টের debug SHA-1:

```text
A9:DF:F4:C6:D9:44:45:28:0C:BE:AA:E8:48:C8:5F:B8:33:56:0E:D5
```

### ৪.২ Release/upload keystore তৈরি করা

```sh
keytool -genkeypair -v \
  -keystore ~/mess-pilot-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

তারপর SHA-1/SHA-256 দেখুন:

```sh
keytool -list -v -keystore ~/mess-pilot-upload.jks -alias upload
```

`android/key.properties` তৈরি করুন (git-এ commit করবেন না):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/YOUR_USER/mess-pilot-upload.jks
```

`android/app/build.gradle.kts`-এ release signing যোগ করুন:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

> বর্তমানে `build.gradle.kts`-এ `signingConfig = signingConfigs.getByName("debug")` আছে। এটা বদলাতে হবে, নাহলে release অ্যাপও debug key দিয়ে sign হবে।

### ৪.৩ Play App Signing SHA নেওয়া

1. https://play.google.com/console → আপনার অ্যাপ → **Test and release → App integrity**।
2. **App signing** ট্যাব → **App signing key certificate**।
3. সেখান থেকে **SHA-1** এবং **SHA-256** কপি করুন।
4. SHA-1 → Android OAuth client-এ যোগ করুন।
5. SHA-256 → `web/.well-known/assetlinks.json`-এ যোগ করুন (App Links-এর জন্য)।

### ৪.৪ Android OAuth client তৈরি/আপডেট

Google Cloud Console → **Credentials → Create Credentials → OAuth client ID → Android**:

- Package name: `com.goraso.messpilot`
- SHA-1: উপরের যেকোনো একটি

প্রতিটি SHA-1-এর জন্য আলাদা Android client বানান (একই package, ভিন্ন SHA)। Google একই package-এর একাধিক Android client সাপোর্ট করে।

কোনটা কোন ধরনের client, তা দেখতে Credentials লিস্টে client-এ ক্লিক করুন। বর্তমান `...7voice...` client-টি Android কিনা এবং তার SHA-1 debug SHA-1-এর সাথে মেলে কিনা যাচাই করুন।

---

## ৫. iOS সেটআপ

### ৫.১ iOS OAuth client তৈরি

Google Cloud Console → **Credentials → Create Credentials → OAuth client ID → iOS**:

- Bundle ID: `com.goraso.messpilot`
- App Store ID (ঐচ্ছিক)
- Team ID: `Q7U8S53NZ6`

তৈরি হওয়ার পর **Client ID** এবং **iOS URL scheme** (অর্থাৎ `REVERSED_CLIENT_ID`) কপি করুন।

### ৫.২ Info.plist-এ URL scheme যোগ করা

`ios/Runner/Info.plist`-এ যোগ করুন:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.139665999955-XXXXXXXXXXXX</string>
        </array>
    </dict>
</array>
```

`XXXXXXXXXXXX`-এর জায়গায় iOS client ID-এর reversed রূপ বসবে (Google Console-এ "iOS URL scheme" নামে দেখায়)।

### ৫.৩ Build-এ iOS client ID দেওয়া

```sh
flutter run -d <ios-device> \
  --dart-define=GOOGLE_IOS_CLIENT_ID=139665999955-XXXXXXXX.apps.googleusercontent.com
```

> বর্তমানে `AppConstants.googleIosClientId`-এর কোনো default নেই, তাই iOS-এ Google button চাপলে "not configured" দেখাবে।

---

## ৬. Web সেটআপ

Google Cloud Console → **Credentials → Web client** (বর্তমান `...jubvss...`) → Edit:

**Authorized JavaScript origins**-এ যোগ করুন:

```text
https://messpilot.goraso.com
http://localhost:54302
http://127.0.0.1:54302
```

> Flutter web dev server অন্য port ব্যবহার করলে সেই port-ও যোগ করতে হবে। Firebase Hosting-এর preview channel ব্যবহার করলে সেই preview domain-ও যোগ করুন।

Web client ID কোডে default হিসেবেই আছে। চাইলে override:

```sh
flutter build web --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```

---

## ৭. Backend সেটআপ

`mm_backend/.env` (এবং Vercel Environment Variables) — **সব platform-এর client ID কমা দিয়ে**:

```env
GOOGLE_OAUTH_CLIENT_IDS=YOUR_GOOGLE_WEB_CLIENT_ID,YOUR_GOOGLE_ANDROID_CLIENT_ID,YOUR_GOOGLE_IOS_CLIENT_ID
```

- প্রথমটি Web (web + Android-এর server audience)
- দ্বিতীয়টি Android (যাচাই করে নিন)
- তৃতীয়টি iOS (তৈরি করার পর যোগ করুন)

> গুরুত্বপূর্ণ: Android-এ `serverClientId` হিসেবে Web client ID পাঠানো হয়, তাই Android থেকে আসা token-এর `aud` সাধারণত **Web client ID** হয়। iOS token-এর `aud` **iOS client ID** হয়। নিরাপদ থাকতে সব কয়েকটি ID-ই backend-এ রাখুন। `google_auth.py` token-এর `aud` এই লিস্টে আছে কিনা যাচাই করে।

Vercel-এ সেট করা:

```sh
cd mm_backend
vercel env add GOOGLE_OAUTH_CLIENT_IDS production
```

তারপর redeploy করুন।

> মনে রাখবেন: backend এখন নতুন email দিয়েও Google login করলে **অটোমেটিক account তৈরি** করে দেয়। Google ফোন নম্বর দেয় না, তাই account-এ phone খালি (null) থাকে; user পরে Edit Profile থেকে নম্বর যোগ করতে পারবে।

---

## ৮. চালানোর কমান্ড

```sh
# Web
flutter run -d chrome --web-port=54302

# Android debug
flutter run -d <android-device>

# Android release (নিজের keystore দিয়ে sign করার পর)
flutter build appbundle --release

# iOS
flutter run -d <ios-device> \
  --dart-define=GOOGLE_IOS_CLIENT_ID=139665999955-XXXXXXXX.apps.googleusercontent.com
```

---

## ৯. যাচাই ও সমস্যা সমাধান

| সমস্যা / error | কারণ | সমাধান |
| --- | --- | --- |
| `Google sign-in is not configured` | client ID খালি | `--dart-define` দিন বা default সেট করুন |
| Android: `ApiException: 10` / `DEVELOPER_ERROR` | package বা SHA-1 মেলেনি | Android OAuth client-এ সঠিক SHA-1 যোগ করুন |
| Play থেকে ইনস্টলে login fail | Play App Signing SHA-1 যোগ করা নেই | Play Console-এর app signing SHA-1 যোগ করুন |
| Web: `redirect_uri_mismatch` / `origin mismatch` | origin অনুমোদিত নয় | Authorized JavaScript origins-এ domain/port যোগ করুন |
| Backend: `Google token was issued for a different application` | `aud` backend লিস্টে নেই | `GOOGLE_OAUTH_CLIENT_IDS`-এ client ID যোগ করুন |
| Backend: `Google sign-in is not configured` | env খালি | `.env`/Vercel-এ `GOOGLE_OAUTH_CLIENT_IDS` দিন |
| iOS: login শুরুতেই বন্ধ | URL scheme নেই | `Info.plist`-এ `CFBundleURLTypes` যোগ করুন |
| `No account found for this Google email` | পুরোনো backend এখনো auto-create করে না | backend আপডেট করে redeploy করুন |

Debug build-এ log দেখতে:

```sh
flutter run -d <android-device> --verbose
adb logcat | grep -i "google\|credential\|signin"
```

---

## ১০. নিরাপত্তা

- `key.properties`, `.jks`, `.keystore` কখনো git-এ commit করবেন না। `.gitignore`-এ আছে কিনা দেখুন।
- Client ID পাবলিক তথ্য — লুকানোর দরকার নেই। কিন্তু **keystore password** গোপন রাখুন।
- Client secret কোথাও mobile app-এ রাখবেন না।
- Vercel/GitHub-এ শুধু env variable হিসেবে মান রাখুন, কোডে নয়।
- Firebase-এ Google provider চালু করলে `google-services.json`-এ `oauth_client` entry যোগ হবে ও `GoogleService-Info.plist`-এ `CLIENT_ID` আসবে। বর্তমান backend-verify flow-তে এটা বাধ্যতামূলক নয়।

---

## ১১. দরকারি লিংক

- Google Cloud Console: https://console.cloud.google.com
- OAuth consent screen: https://console.cloud.google.com/apis/credentials/consent
- Credentials: https://console.cloud.google.com/apis/credentials
- Play Console App Integrity: https://play.google.com/console
- Google Sign-In (Flutter): https://pub.dev/packages/google_sign_in
- Credential Manager (Android): https://developer.android.com/identity/sign-in/credential-manager

---

## ১২. সংক্ষেপে যা করতে হবে

1. Google Cloud-এ OAuth consent screen সম্পূর্ণ করুন।
2. Web client-এ `https://messpilot.goraso.com` + localhost origin যোগ করুন।
3. Android OAuth client-এ debug SHA-1 যোগ করুন (এবং পরে upload ও Play App Signing SHA-1)।
4. iOS OAuth client তৈরি করুন → Client ID + reversed URL scheme নিন → `Info.plist`-এ যোগ করুন।
5. Backend `.env`/Vercel-এ সব client ID `GOOGLE_OAUTH_CLIENT_IDS`-এ দিন।
6. Release build-এর জন্য নিজের keystore দিয়ে signing config করুন, তারপর upload/Play SHA-1 যোগ করুন।
7. App Links-এর জন্য `assetlinks.json`-এ Play App Signing SHA-256 যোগ করুন।
8. প্রতিটি platform-এ (web/android/iOS) login টেস্ট করুন।
