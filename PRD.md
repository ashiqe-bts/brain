# BrainFlex — Personal Cognitive Gym

## 1. Product intent

BrainFlex is an offline personal training app for practising five specific cognitive tasks. It is designed for all ages in the sense that its instructions are universally understandable and its feedback is based on self-comparison rather than age norms.

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
- A daily workout contains one official round from each of the five skills.
- Each completed round is saved so an interrupted workout can resume safely.
- After baseline completion, recommends optional practice for the two least-trained or weakest-trending skills.

### Train

- Lists all five games with their skill, current difficulty, and compatible personal best.
- Standard mode contributes comparable data.
- Relaxed mode is untimed and excluded from performance trends.
- Personal Best mode compares only against compatible runs using the same rules version and difficulty.

### Insights

- Shows baseline progress, five separate skill profiles, recent sessions, weekly review, workout calendar, and achievements.
- Never combines the five skills into a composite cognitive score.
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

- Present an increasing sequence or set of highlighted tiles for recall.
- Measure maximum span, recall accuracy, exposure duration, and round progression.

### Reaction — Reflex Tap

- Use a monotonic stopwatch.
- Include one unmeasured warm-up trial followed by measured trials.
- Measure median latency and false starts.
- Explain that hardware and display differences can affect device-to-device comparisons.

### Visual Search

- Present a target followed by a distractor grid containing exactly one match.
- Systematically vary orientation, shape, fill, colour, and target position.
- Measure accuracy and median correct-search time.
- Shape, fill, and orientation must keep the task playable without colour perception.

## 5. Scoring and comparability

- Each game has a versioned, game-specific scorer. A generic accuracy/pace score is prohibited.
- Every stored result includes a stable ID, completion timestamp, game and rules version, session kind, difficulty, duration, accuracy, raw metrics, and score components.
- Comparable trend sessions are Standard or official sessions with a timestamp and matching rules.
- A rules-version change starts a new comparison series without deleting earlier history.
- Personal Best additionally requires matching difficulty.
- Participation XP and the overall participation level must never be presented as cognitive performance.

Skill training levels range from 1.0 to 10.0. They combine the played difficulty with within-level task performance. They are an app-specific training indicator and are always accompanied by raw metrics.

## 6. Baseline and adaptation

The first three completed daily workouts form the progressive baseline. Before completion, Insights shows `workout N of 3`, partial results, and a clear confidence limitation.

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

Retired character, mood, energy, cosmetic, token, boost, advertising, and reward fields are ignored after migration and are not exposed in the product.

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

Automated coverage includes every engine and scorer, seeded generation, adaptation boundaries, comparison rules, baseline and rolling trends, weekly recommendation, streaks, migration, all five game screens, pause/quit, reviews, Insights states, accessibility configurations, restart/persistence, and removal of retired product surfaces.

## 11. Out of scope

This release does not include additional games, leaderboards, social competition, AI coaching, accounts, cloud sync, a backend, ads, age norms, diagnosis, clinical claims, or scored gameplay modifiers.
