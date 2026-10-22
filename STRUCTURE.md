# Project structure

The app is named Mess Pilot; its Dart package remains `clean_boilerplate`.

```text
lib/
├── config/
│   ├── route/app_router.dart       # AppRoutes and GoRouter
│   ├── theme/                      # Light/dark themes and custom colors
│   └── util/                       # Constants, dimensions, styles, Result
├── core/
│   ├── assets/                     # Generated asset/font references
│   ├── di/                         # Injectable/GetIt setup and generated registrations
│   ├── errors/                     # Exceptions, failures, safe user messages
│   ├── extensions/                 # Context/localization and UI helpers
│   ├── helpers/                    # Responsive helpers
│   ├── network/                    # ApiClient, Dio module, authentication refresh
│   ├── role/                       # Role derived from authenticated profile
│   ├── usecase/                    # Base use-case contracts
│   └── widgets/                    # Widgets shared across features
├── features/
│   ├── app_info/
│   ├── auth/
│   ├── cost/
│   ├── deposit/
│   ├── fund/
│   ├── home/
│   ├── meal/
│   ├── membership/
│   ├── notice/
│   ├── opinion/
│   ├── season/
│   ├── settings/
│   └── splash/
├── l10n/
│   ├── arb/                        # app_en.arb, app_bn.arb, app_ar.arb
│   └── gen/                        # Generated translations
├── firebase_options.dart           # FlutterFire configuration
└── main.dart                       # Startup, providers, router, theme and locale
```

Feature modules generally contain:

```text
feature/
├── data/
│   ├── datasources/{interfaces,remote,local}/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── screens/
    └── widgets/
```

Some features use direct API services (for example `membership/data/membership_api_service.dart`
and `opinion/data/opinion_api_service.dart`). The existing splash repository folder
is spelled `data/repositrories/`; check actual paths before adding imports.
`HomeLocalDataSourceImpl` retains its historical name but calls live APIs.
Other unregistered local sources provide demo fixtures.

## Supporting directories

- `assets/`: images, SVG flags, and fonts declared in `pubspec.yaml`.
- `test/`: unit, widget, routing, and layout regression tests.
- `web/`: HTML launch page and web icons; release output is `build/web/`.
- `android/`, `ios/`: native integration and launcher artwork.
- `.github/workflows/`: live and preview Firebase Hosting deployment.

## Layer boundaries and generated files

Presentation calls domain use cases; data implementations fulfill repository
contracts and map API models to entities. Repository operations use the custom
`Result` type in `config/util/result.dart`.

Generated files include `*.freezed.dart`, `*.g.dart`, `*.mocks.dart`,
`core/di/injection.config.dart`, `core/assets/assets.gen.dart`,
`core/assets/fonts.gen.dart`, and `l10n/gen/`. Regenerate instead of editing them.

Shared page layout belongs in `core/widgets/`; feature-specific widgets stay
with their feature. Follow [AGENTS.md](AGENTS.md) and [CLAUDE.md](CLAUDE.md), and
use the commands in [SETUP.md](SETUP.md) when adding registrations or models.
