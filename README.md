# BrainFlex

BrainFlex is an offline personal cognitive gym built with Flutter. It contains 15 research-informed tasks spanning interference control, calculation, visual and working memory, response inhibition, processing speed, cognitive flexibility, attention, associative memory, planning, dual-task control, and spatial reasoning.

Each daily workout contains five games. A deterministic three-workout cycle covers all 15 games once before reshuffling the next cycle. Every game builds its own baseline from three official results under the current rules version, so a complete baseline requires at least nine workouts.

BrainFlex does not claim to measure IQ, diagnose a condition, prevent cognitive decline, or prove improvement outside its trained tasks.

Every Train card includes a research-basis sheet naming the studied paradigm, population, source PMID, and important limitation. Evidence is described as research-informed rather than clinically proven because transfer beyond the trained or closely related task is often limited.

## Product behaviour

- Today provides five games from the current balanced rotation, baseline status, streaks, and practice recommendations.
- Train offers Standard, Relaxed, and Personal Best sessions.
- Insights provides 15 separate game profiles, history, rolling trends, weekly reviews, and achievements.
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
