# BrainFlex — Personal Cognitive Gym

## 1. Product intent

BrainFlex is an offline personal training app for practising 15 research-informed cognitive tasks. It is designed for all ages in the sense that its instructions are broadly understandable and its feedback is based on self-comparison rather than age norms.

The product promise is deliberately narrow: BrainFlex helps users practise and measure performance in the tasks included in the app. It must not claim to measure IQ, diagnose or prevent a medical condition, or establish improvement in general real-world cognition.

## 2. Product principles

1. Show raw performance before interpretation.
2. Compare like with like: the same task, rules version, difficulty, and scored conditions.
3. Treat small fluctuations as normal, not as improvement or decline.
4. Keep participation rewards separate from cognitive performance.
5. Keep all personal information on the device.
6. Make every task usable without relying on colour alone.

## 3. Navigation and core flows

### Today

- Shows the daily standardized workout, baseline status, current streak, workout count, and participation XP.
- A daily workout contains five official rounds from a deterministic three-workout rotation that covers every active game once per cycle.
- Each completed round is saved so an interrupted workout can resume safely.
- After baseline completion, recommends optional practice for the two least-trained or weakest-trending skills.

### Train

- Lists all 15 active games grouped by cognitive domain, with current difficulty, compatible personal best, and a transparent research-basis sheet.
- Standard mode contributes comparable data.
- Relaxed mode is untimed and excluded from performance trends.
- Personal Best mode compares only against compatible runs using the same rules version and difficulty.

### Insights

- Shows per-game baseline progress, 15 separate game profiles, recent sessions, weekly review, workout calendar, and achievements.
- Never combines the games into a composite cognitive score.
- Always displays a skill level together with raw measures such as accuracy, span, or median response time.

## 4. Training tasks

### Focus — Color Clash

- Present balanced congruent and incongruent colour-word trials.
- Measure accuracy and median correct-response time.
- Feedback must include text or iconography and must not depend on colour alone.

### Calculation — Math Blitz

- Use age-neutral arithmetic with difficulty-based operation and operand ranges.
- Incorrect choices must be plausible and may never equal the correct answer.
- Measure accuracy and median correct-response time.

### Memory — Memory Tiles

- Present a tile pattern briefly, change exactly one tile, and ask the user to identify the change.
- Measure change-detection accuracy, capacity, and exposure duration.

### Additional active tasks

- Signal Stop trains response inhibition with variable go/stop trials.
- Peripheral Focus combines central identification with peripheral localization.
- N-Back Navigator trains working-memory updating from one- to three-back.
- Rule Switch measures accuracy and switch cost across changing classification rules.
- Arrow Guard uses congruent and incongruent flanker trials.
- Pair Link trains abstract paired-associate recall.
- Symbol Sprint uses a changing symbol-number substitution key.
- Object Tracker trains distributed attention across moving targets.
- Tower Planner uses constrained minimum-move planning problems.
- Dual Task Dash requires simultaneous counting and classification.
- Logic Series uses adaptive inductive sequences.
- Spatial Rotation compares rotated and mirrored abstract shapes.

Reflex Tap and the earlier Visual Search task are archived. Their stored results remain readable but they are excluded from active workouts, adaptation, missions, and recommendations.

## 5. Scoring and comparability

- Each game has a versioned, game-specific scorer. A generic accuracy/pace score is prohibited.
- Every stored result includes a stable ID, completion timestamp, game and rules version, session kind, difficulty, duration, accuracy, raw metrics, and score components.
- Comparable trend sessions are Standard or official sessions with a timestamp and matching rules.
- A rules-version change starts a new comparison series without deleting earlier history.
- Personal Best additionally requires matching difficulty.
- Participation XP and the overall participation level must never be presented as cognitive performance.

Skill training levels range from 1.0 to 10.0. They combine the played difficulty with within-level task performance. They are an app-specific training indicator and are always accompanied by raw metrics.

## 6. Baseline and adaptation

Each game forms its own progressive baseline from three official results under its current rules version. A balanced rotation can complete all 15 baselines after nine workouts. Insights shows partial per-game progress and does not label a trend until that game also has three compatible post-baseline observations.

After each comparable session, difficulty reviews the latest three sessions at the same game, rules version, and difficulty:

- Increase by one level when at least two results meet the game-specific mastery band.
- Decrease by one level when at least two results meet the struggling band.
- Otherwise hold.
- Never change by more than one level at a time or leave the supported range.

Thresholds belong to versioned game configuration and require boundary tests.

## 7. Reviews and recommendations

### Session review

- Show the raw result for each trained skill.
- Show change from baseline and the previous compatible attempt when available.
- Provide one deterministic, task-specific actionable tip.
- Explain when compatible data is insufficient.

### Weekly review

- Show workouts completed and consistency.
- Determine each skill direction from rolling medians, not a single-session change.
- Show strongest progress and the skill needing attention.
- Provide one deterministic next-week recommendation.
- Do not label a trend until there are at least three compatible post-baseline observations.

## 8. Storage, privacy, and migration

Drift game-session rows are the source of truth for dated history. History queries are indexed by game and completion time and must be bounded or paginated. Gameplay must not decode the full database or scan all historical rows.

Migration from the original product must preserve settings, onboarding, reminders, themes, streaks, XP, participation levels, achievements, workouts, daily summaries, and meaningful game results. Timestamped records are reconstructed where possible. Undated snapshot-only results remain eligible for historical personal-best display but are excluded from time-based trends. A pre-migration state snapshot is retained until the new state saves successfully.

Unrecognized legacy snapshot fields are ignored after migration and are not exposed in the product.

There are no accounts, backend, cloud synchronization, advertising SDKs, or product telemetry. On web, local data uses browser-managed storage; clearing site data removes it.

## 9. Accessibility

- Support screen readers with descriptive labels and live result feedback.
- Support 200% text scaling without clipped essential content.
- Provide visible focus, minimum 44×44 logical-pixel touch targets, and logical traversal order.
- Provide high-contrast themes and colour-independent game cues.
- Respect reduced-motion settings and avoid flashing content.
- Pause safely when the app becomes inactive and allow users to quit without corrupting saved progress.

## 10. Performance and release gates

Release candidates require:

- `flutter analyze`
- unit and widget tests
- web build
- Android debug build
- iOS simulator build
- manual screen-reader, large-text, high-contrast, reduced-motion, and colour-independence review
- Flutter profile-mode startup and gameplay review on the agreed reference device

Profile targets are a cold interactive startup under two seconds, input feedback on the next rendered frame, no recurring build or raster frame over 16.7 ms during ordinary 60 Hz gameplay, and no full-history decoding or database scan on a gameplay path.

Automated coverage includes every engine and scorer, seeded generation, rotation coverage, adaptation boundaries, comparison rules, per-game baselines and rolling trends, weekly recommendation, streaks, migration, all 15 game screens, pause/quit, reviews, Insights states, accessibility configurations, and restart/persistence.

## 11. Out of scope

This release does not include leaderboards, social competition, AI coaching, accounts, cloud sync, a backend, ads, age norms, diagnosis, clinical claims, or scored gameplay modifiers.
