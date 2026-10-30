# BrainFlex

BrainFlex is an Android-and-Chrome offline-first personal cognitive gym built with Flutter. It contains 15 research-informed tasks spanning interference control, calculation, visual and working memory, response inhibition, processing speed, cognitive flexibility, attention, associative memory, planning, dual-task control, and spatial reasoning.

Each daily workout contains five different games chosen by the user or generated as a coverage-aware random mix. Every game builds its own baseline from three official results under the current rules version.

BrainFlex does not claim to measure IQ, diagnose a condition, prevent cognitive decline, or prove improvement outside its trained tasks.

Every Train card includes a research-basis sheet naming the studied paradigm, population, source PMID, and important limitation. Evidence is described as research-informed rather than clinically proven because transfer beyond the trained or closely related task is often limited.

## Product behaviour

- First launch offers guest, Google, or email access, then asks for a display name and optional reminder; Home opens with a personal greeting.
- Today lets users select five different games or generate a balanced Random 5, then shows baseline status, streaks, and practice recommendations.
- Every game has a required production-equivalent tutorial on first play for its current rules version. Tutorials reuse the real board, controls, stimuli, timing, and animations, add a delayed helper hand, and can be replayed without affecting progress.
- The active catalog uses responsive 2.5D game stages, dimensional controls, custom-painted stimuli, and distinct per-game visual worlds without requiring a 3D engine or network assets.
- Train offers Standard, Relaxed, and Challenge My Best sessions.
- Every scored session ends with a metric-selectable progress graph, current/previous/baseline comparisons, and game-specific measures.
- Every completed round opens with a short party-popper celebration; finishing all five daily games adds a larger finale. Reduced-motion mode uses a static celebration instead.
- Insights provides a multi-game training-level chart, 15 separate charted game profiles, history, rolling trends, weekly reviews, and achievements.
- Standard and official sessions contribute to trends. Relaxed sessions are untimed and excluded.
- Challenge My Best requires the same game rules version and difficulty. Result feedback compares only with the latest compatible personal attempt.
- Participation XP remains compatible with existing data but is de-emphasized in the interface. Skill levels are shown separately with raw metrics.
- Calm Light, Calm Dark, and High Contrast themes share a playful, accessible Material 3 game language. Compact layouts use bottom navigation; wide Chrome layouts use a navigation rail.
- Gameplay remains local-first. Firebase Anonymous Auth protects guest cloud data, and optional Google or verified email accounts sync progress across devices. Device preferences remain local; there is no product telemetry, advertising, or paid gameplay advantage.

## Run locally

```sh
flutter pub get
flutter run -d chrome
# or
flutter run -d android
```

Without Firebase defines the app runs in safe offline-guest mode. To enable accounts, create a Firebase project, enable Anonymous, Google, and Email/Password Auth, create Firestore in `asia-south1`, and supply the generated Android/web values:

```sh
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_APP_CHECK_SITE_KEY=...
```

Install the Firebase and FlutterFire CLIs, run `flutterfire configure --platforms=android,web`, register Android SHA-1/SHA-256 fingerprints, enable Play Integrity and reCAPTCHA Enterprise App Check, then deploy with `firebase deploy --only firestore,functions`. Use `--dart-define=USE_FIREBASE_EMULATORS=true` with a `demo-` project configuration for local emulator work.

Android and Chrome are the supported targets. Daily reminders are available on Android; Chrome labels them unavailable. Other web browsers are not intentionally blocked, but are outside the support contract.

The app uses Drift code generation. After changing database tables, regenerate the generated code:

```sh
dart run build_runner build --force-jit
```

`--force-jit` avoids a Dart build-runner issue when dependencies use native build hooks.

## Quality gates

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
npm --prefix functions run lint
npm --prefix functions test
```

Performance targets for release review are a cold interactive start under two seconds on the agreed reference device, input feedback on the next rendered frame, and no recurring build or raster frame above 16.7 ms during normal 60 Hz play. These targets must be measured in Flutter profile mode on representative hardware.

## Data migration

The current schema migrates older installations non-destructively into an isolated local profile. Existing users are asked once for a display name. Settings, reminders, streaks, XP, achievements, workouts, summaries, and usable history are retained. Stable session IDs make cloud uploads idempotent, while undated legacy results remain local and excluded from time-based trends. A pre-migration snapshot is retained before the new state is saved successfully.
