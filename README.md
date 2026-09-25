# BrainFlex

BrainFlex is an offline personal cognitive gym built with Flutter. It helps people practise and measure their own performance in five tasks:

- Focus — Color Clash
- Calculation — Math Blitz
- Memory — Memory Tiles
- Reaction — Reflex Tap
- Visual search — Visual Search

The first three completed daily workouts form a progressive personal baseline. After that, BrainFlex shows compatible per-skill trends, weekly reviews, and suggested practice. It compares each user only with their own sessions under matching rules and conditions.

BrainFlex does not claim to measure IQ, diagnose a condition, prevent cognitive decline, or prove improvement outside its trained tasks.

## Product behaviour

- Today provides one standardized round for every skill, baseline status, streaks, and practice recommendations.
- Train offers Standard, Relaxed, and Personal Best sessions.
- Insights provides five separate skill profiles, history, rolling trends, weekly reviews, and achievements.
- Standard and official sessions contribute to trends. Relaxed sessions are untimed and excluded.
- Personal Best comparisons require the same game rules version and difficulty.
- XP and the overall training level measure participation only. Skill levels are shown separately with raw metrics.
- All data stays on the device. There are no accounts, cloud sync, product telemetry, advertising, or paid gameplay advantages.

## Run locally

```sh
flutter pub get
flutter run -d chrome
# or
flutter run -d android
```

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
flutter build ios --simulator --no-codesign
```

Performance targets for release review are a cold interactive start under two seconds on the agreed reference device, input feedback on the next rendered frame, and no recurring build or raster frame above 16.7 ms during normal 60 Hz play. These targets must be measured in Flutter profile mode on representative hardware.

## Data migration

The current schema migrates older installations non-destructively. Settings, reminders, themes, streaks, XP, participation levels, achievements, workouts, daily summaries, and usable session history are retained. Dated sessions move to Drift as the history source of truth; undated legacy results remain available for personal-best history but are excluded from time-based trends. A pre-migration snapshot is retained before the new state is saved successfully.

The untracked `assets/rive/` directory is intentionally outside this migration and must not be removed automatically.
