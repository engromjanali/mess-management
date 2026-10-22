# Mess Pilot setup

Run these commands from the Flutter project directory. SDK constraints are in
[pubspec.yaml](pubspec.yaml); toolchain references are in [VERSIONS.md](VERSIONS.md).

## First run

```sh
flutter doctor
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter devices
flutter run -d chrome --web-port=54302
```

The package name is `clean_boilerplate`. Keep package imports consistent with it.
The app uses handwritten Dio services, not Retrofit-generated services.

## Backend connection

Start the sibling Django backend separately. The app reads `API_BASE_URL` through
`String.fromEnvironment`, not a Flutter `.env` file.

```sh
# Local browser / iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical device, use the development computer's reachable LAN address.
The backend must listen on that interface and allow the requested host/origin.
Release defaults and demo-login flags are documented in [README.md](README.md#api-environments).

## Code generation

```sh
# One build after changing models, registrations, mocks, or asset declarations
dart run build_runner build --delete-conflicting-outputs

# Regenerate as files change
dart run build_runner watch --delete-conflicting-outputs

# Translations
flutter gen-l10n
```

Watch mode keeps the terminal occupied while waiting for changes. A successful
`wrote 0 outputs` message means no generated files needed updating. Press Ctrl+C
to stop watching, or use another terminal for Flutter commands.

Generated outputs include `*.freezed.dart`, `*.g.dart`, `*.mocks.dart`,
`lib/core/di/injection.config.dart`, `lib/core/assets/assets.gen.dart`, and
`lib/l10n/gen/`. Do not edit generated files manually.

## Assets and localization

1. Add assets under the directories declared in `pubspec.yaml`.
2. Run the build_runner command above to regenerate FlutterGen asset references.
3. Add translation keys at the end of all three `lib/l10n/arb/app_*.arb` files.
4. Run `flutter gen-l10n` and use `context.local.<key>` in widgets.
5. Check English, Bengali, Arabic/RTL, narrow layouts, and large text for overflow.

Changing `assets/images/logo.png` alone does not regenerate native launcher icons;
review the Android, iOS, and web artwork separately.

## Platforms

```sh
# Choose a listed Android emulator or iOS simulator ID
flutter devices
flutter run -d <device-id>
```

On macOS, install iOS dependencies from `ios/` with `pod install`, then return to
the project root. Use `ios/Runner.xcworkspace` for Xcode work.

Android map configuration reads `GOOGLE_MAPS_API_KEY` from a Gradle project property
or environment variable; see `android/app/build.gradle.kts`.

## Verification and release builds

```sh
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --concurrency=1
flutter test --coverage
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

Android release builds currently use the debug signing configuration. Configure
release signing before distributing through an app store. iOS distribution also
requires the project's signing/provisioning configuration.

## Troubleshooting

Use [FIX_VERSIONS.md](FIX_VERSIONS.md). Keep `pubspec.lock`; deleting it changes
resolved dependencies instead of reproducing the existing build.
