# Toolchain and dependencies

This document describes repository configuration as of 23 October 2026; it is not
a list of the latest available package releases. Use [pubspec.yaml](pubspec.yaml)
for constraints and [pubspec.lock](pubspec.lock) for exact resolved Dart packages.

## SDK requirements

| Component | Repository configuration |
|---|---|
| Dart | `^3.13.0` |
| Flutter | `>=3.47.0` |
| Android Gradle Plugin | `9.1.0` |
| Gradle wrapper | `9.3.1` |
| Kotlin Android plugin | `2.4.0` |
| Google Services plugin | `4.5.0` |
| Android Java/Kotlin target | JVM `17` |
| Android minimum SDK | `24` |

Native versions come from [settings.gradle.kts](android/settings.gradle.kts),
[the wrapper properties](android/gradle/wrapper/gradle-wrapper.properties), and
[app/build.gradle.kts](android/app/build.gradle.kts). Compile/target SDK and NDK
versions are supplied by Flutter in the app configuration.

## Main Dart constraints

| Package | Constraint |
|---|---|
| flutter_bloc | `^9.1.1` |
| bloc | `^9.2.1` |
| hydrated_bloc | `^11.0.0` |
| get_it | `^9.3.0` |
| injectable | `^3.0.0` |
| go_router | `^18.1.1` |
| dio | `^5.11.1` |
| freezed_annotation | `^3.1.0` |
| freezed | `^4.0.3` |
| json_annotation | `^4.12.0` |
| json_serializable | `^6.15.2` |
| injectable_generator | `^3.1.3` |
| build_runner | `^2.16.1` |
| flutter_gen_runner | `^5.13.0+1` |
| mockito | `^5.8.1` |
| firebase_core | `^5.0.0` |

Runtime annotation and generator packages do not necessarily share a major
version. Preserve the resolved set unless intentionally upgrading it. Retrofit
and dartz examples from the original boilerplate do not describe this app.

For upgrades, inspect `flutter pub outdated`, update related constraints together,
regenerate code, and run analysis/tests plus builds for the affected platforms.
See [FIX_VERSIONS.md](FIX_VERSIONS.md) for recovery steps.
