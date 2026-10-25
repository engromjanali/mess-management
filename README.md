# Mess Pilot

Flutter app for managing mess membership, seasons, meals, deposits, shopping costs,
shared funds, notices, and opinions. The Django API lives in the sibling
`mm_backend` project.

The Dart package name is `mess_pilot`; use that name in package imports.

## Start locally

Use Flutter satisfying the constraints in [pubspec.yaml](pubspec.yaml).

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run -d chrome --web-port=54302
```

For device IDs, run `flutter devices`. See [SETUP.md](SETUP.md) for platform setup,
watch mode, testing, and release commands.

## API environments

[AppConstants](lib/config/util/app_constants.dart) reads `API_BASE_URL` at build time.
Debug and profile builds default to `http://10.0.2.2:8000` on Android (emulator)
and `http://127.0.0.1:8000` on other platforms. Release builds default to
`https://mm-backend-kappa.vercel.app`. Local HTTP is allowed in Android debug/profile builds.
Restart the app fully after changing these settings.

```sh
# Android emulator reaching the development computer
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Release against a different backend
flutter build web --release --dart-define=API_BASE_URL=https://your-backend.example.com
```

A physical phone needs a reachable development computer address, with Django
listening on that interface. The Flutter app does not load API settings from `.env`.
Build-time definitions are public app configuration; do not put secrets in them.

The demo credential button is enabled by default only in debug builds. Use
`--dart-define=ENABLE_DEMO_LOGIN=true` only for an intentional demo build.

## Architecture and behavior

- Features generally separate `data`, `domain`, and `presentation` layers.
- BLoC/Cubit manages state; GetIt/Injectable registers dependencies.
- Dio requests pass through [ApiClient](lib/core/network/api_client.dart), including
  shared token refresh, one retry for expired authentication, and log redaction.
- Repositories use the project's [Result](lib/config/util/result.dart) abstraction.
- Freezed, JSON Serializable, Injectable, FlutterGen, and Mockito generate code.
- English, Bengali, and Arabic translations live in `lib/l10n/arb/`.
- Roles come from the authenticated server profile. Manager and acting-manager
  actions are also checked by the backend.
- Shared widgets belong in `lib/core/widgets/`. `AppPageScrollView` keeps desktop
  footers full width and at the bottom when content is short.
- Active Home totals come from the backend, including the caller's `my_stats`.
  Unregistered local demo sources are separate from the app's remote registrations.

See [STRUCTURE.md](STRUCTURE.md), [AGENTS.md](AGENTS.md), and [CLAUDE.md](CLAUDE.md)
for paths and project conventions.

## Verify changes

```sh
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --concurrency=1
flutter build web --release
```

The analysis command tolerates existing warning/info diagnostics; errors still fail.
Use [FIX_VERSIONS.md](FIX_VERSIONS.md) for dependency troubleshooting and
[VERSIONS.md](VERSIONS.md) for the current toolchain references.

## Web deployment

The workflows in [.github/workflows](.github/workflows) generate code, analyze,
build Flutter web, and deploy `build/web` to Firebase Hosting.

- Pushes to `version-2.0` deploy the live site; manual dispatch is also supported.
- Pull requests from the same repository receive preview deployments.
- Both workflows require the repository secret
  `FIREBASE_SERVICE_ACCOUNT_MESS_MANAGEMENT_2600A`.
- [firebase.json](firebase.json) rewrites application routes to `/index.html`.
- Customize the launch page in [web/index.html](web/index.html); deployment uses
  the generated `build/web/index.html`.

Deploy backend changes providing `my_stats` and `/api/v1/user/notices/<id>` before
releasing the updated frontend. Backend API and deployment notes are in
`mm_backend/POSTMAN_API_EXAMPLES.md` and `mm_backend/VERCEL_DEPLOYMENT.md`.
