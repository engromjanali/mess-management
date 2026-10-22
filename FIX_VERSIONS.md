# Dependency and generated-code troubleshooting

Use the constraints in [pubspec.yaml](pubspec.yaml) and the resolved versions in
[pubspec.lock](pubspec.lock). The old Freezed 2 / Retrofit 4 compatibility recipes
no longer apply; this app uses handwritten Dio services.

## Start with the actual failure

```sh
flutter --version
flutter doctor
flutter pub get
```

Read the first dependency solver error before changing constraints. Keep
`pubspec.lock` to reproduce the app's resolved packages.

## Missing or conflicting generated files

Stop any running build_runner watcher, then run:

```sh
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

If the generator's incremental state is inconsistent:

```sh
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

A watcher that reports `wrote 0 outputs` is waiting normally, not stuck. Stop it
with Ctrl+C when you need the terminal prompt.

## Stale platform build outputs

Use this only when the failure points to stale build artifacts:

```sh
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

Do not routinely delete the lockfile, repair the entire pub cache, or downgrade
packages to historical versions. Those actions can hide the original problem.

## Validate the result

```sh
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --concurrency=1
flutter build web --release
```

Also build the affected native target after changing Android/iOS configuration.
