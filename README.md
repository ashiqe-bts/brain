# BrainFlex

BrainFlex is a playful, offline-first daily brain trainer for Android and iOS. It includes a custom animated Brain Buddy, five mini-games, a seeded daily workout, practice modes, XP and levels, streaks, missions, achievements, local reminders, cosmetic customization, progress reports, and safe local Demo Ad flows.

## Run

```sh
flutter pub get
flutter run -d chrome
# or
flutter run -d android
```

The app uses Drift code generation. After editing database tables, regenerate with:

```sh
dart run build_runner build --force-jit
```

`--force-jit` avoids a Dart 3.10 build-runner issue when dependencies use native build hooks.

## Validation

```sh
flutter analyze
flutter build web
flutter build apk --debug
flutter build ios --simulator --no-codesign
```

All player data stays on-device. Chrome stores progress in browser-managed IndexedDB through Drift's WebAssembly backend. The MVP does not include accounts, analytics, a backend, or a production advertising SDK.
