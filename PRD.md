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
7. Keep the experience strictly “you vs you”; never rank users against peers.

## 3. Supported platforms and identity

- Android and Flutter web in Chrome are the supported release targets. Other browsers are not intentionally blocked.
- Local scheduled reminders are Android-only. Chrome explicitly describes reminders as unavailable.
- First launch begins with a value-first welcome, then requires a trimmed 1–30-character Unicode display name without line breaks or control characters. It does not require a sample game interaction.
- Existing onboarded users without a valid name see the name prompt once without losing progress.
- The name remains local, is editable in Settings, and Home greets the user with `Hey, {name}` above the date.

## 4. Navigation and core flows

Compact layouts use bottom navigation; expanded Chrome layouts use a navigation rail. Calm Light is the default, with Calm Dark and High Contrast available in Settings.

### Today

- Shows the daily standardized workout, its five selected games, baseline status, current streak, and workout count. Participation XP is not a primary Home metric.
- Before a new daily workout, the user chooses exactly five different active games or generates a coverage-aware random set. Random selection favors games with fewer current-version official results and never duplicates a game.
- The selected order is locked once play begins and is persisted for safe resume.
- Each completed round is saved so an interrupted workout can resume safely.
- After baseline completion, recommends optional practice for the two least-trained or weakest-trending skills.

### Train

- Lists all 15 active games grouped by cognitive domain, with current difficulty, compatible best result, a replayable Tutorial action, and a transparent research-basis sheet.
- Standard mode contributes comparable data.
- Relaxed mode is untimed and excluded from performance trends.
- Challenge My Best mode compares only against compatible runs using the same rules version and difficulty.

### Insights

- Shows a combined, selectable multi-game training-level graph, per-game baseline progress, 15 separate charted game profiles, recent sessions, weekly review, workout calendar, and achievements.
- Never combines the games into a composite cognitive score.
- Always displays a skill level together with raw measures such as accuracy, span, or median response time.

## 5. Training tasks

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

### Interactive tutorials

- Every active game supplies versioned coaching metadata and two or three deterministic easy practice trials using its production board, controls, typed stimuli, timing, and animations.
- The first launch of any Standard, Relaxed, Challenge My Best, or official session must complete that game’s current-version tutorial before play begins.
- Exiting a required tutorial starts no game and records nothing. An interrupted daily workout remains on the same round.
- Tutorial completion persists immediately. A rules-version change requires the revised tutorial once.
- Replay is always available from Train and never changes tutorial state, history, scores, XP, missions, baselines, trends, best results, or difficulty.
- Competitive timers and scoring are absent. Incorrect answers explain the rule and retry the same trial. A tutorial-only helper hand points to the correct production control after 2.5 seconds of actionable inactivity or immediately after an error; passive phases explicitly coach the user to watch, remember, or withhold. Touch, keyboard, screen readers, high contrast, reduced motion, and 200% text are supported.

## 6. Scoring and comparability

- Each game has a versioned, game-specific scorer. A generic accuracy/pace score is prohibited.
- Every stored result includes a stable ID, completion timestamp, game and rules version, session kind, difficulty, duration, accuracy, raw metrics, and score components.
- Comparable trend sessions are Standard or official sessions with a timestamp and matching rules.
- A rules-version change starts a new comparison series without deleting earlier history.
- Challenge My Best additionally requires matching difficulty.
- Participation XP and the overall participation level must never be presented as cognitive performance.

Skill training levels range from 1.0 to 10.0. They combine the played difficulty with within-level task performance. They are an app-specific training indicator and are always accompanied by raw metrics.

## 7. Baseline and adaptation

Each game forms its own progressive baseline from three official results under its current rules version. Insights shows partial per-game progress and does not label a trend until that game also has three compatible post-baseline observations. Coverage-aware Random 5 helps distribute official practice, while manual selection leaves baseline coverage under the user’s control.

After each comparable session, difficulty reviews the latest three sessions at the same game, rules version, and difficulty:

- Increase by one level when at least two results meet the game-specific mastery band.
- Decrease by one level when at least two results meet the struggling band.
- Otherwise hold.
- Never change by more than one level at a time or leave the supported range.

Thresholds belong to versioned game configuration and require boundary tests.

## 8. Reviews and recommendations

### Session review

- Show the raw result for each trained skill.
- Show a metric-selectable graph using up to 30 current-rules Standard and official results. Challenge and Relaxed results may appear as a separate hollow current marker but do not join the trend line.
- Compare only with the latest scored result for the same game and rules version. Say “yesterday” only when it was the previous local calendar day; otherwise say “your last run.”
- Describe a match neutrally, and describe lower results as normal session variation rather than decline.
- Provide one deterministic, task-specific actionable tip.
- Explain when compatible data is insufficient.

### Weekly review

- Show workouts completed and consistency.
- Determine each skill direction from rolling medians, not a single-session change.
- Show strongest progress and the skill needing attention.
- Provide one deterministic next-week recommendation.
- Do not label a trend until there are at least three compatible post-baseline observations.

## 9. Storage, privacy, and migration

Drift game-session rows are the source of truth for dated history. History queries are indexed by game and completion time and must be bounded or paginated. Gameplay must not decode the full database or scan all historical rows.

Migration from the original product must preserve settings, onboarding, reminders, themes, streaks, XP, participation levels, achievements, workouts, daily summaries, and meaningful game results. Timestamped records are reconstructed where possible. Undated snapshot-only results remain eligible for historical best-result display but are excluded from time-based trends. A pre-migration state snapshot is retained until the new state saves successfully.

State also stores the nullable local display name and completed tutorial keys in `gameId:rulesVersion` form. Current-version historical play marks that tutorial complete during migration; older-version play does not.

Unrecognized legacy snapshot fields are ignored after migration and are not exposed in the product.

There are no accounts, backend, cloud synchronization, advertising SDKs, or product telemetry. On web, local data uses browser-managed storage; clearing site data removes it.

## 10. Accessibility

- Support screen readers with descriptive labels and live result feedback.
- Support 200% text scaling without clipped essential content.
- Provide visible focus, minimum 48×48 logical-pixel touch targets, and logical traversal order.
- Provide high-contrast themes and colour-independent game cues.
- Respect reduced-motion settings and avoid flashing content.
- Pause safely when the app becomes inactive and allow users to quit without corrupting saved progress.

## 11. Performance and release gates

Release candidates require:

- `flutter analyze`
- unit and widget tests
- Chrome web build and responsive/accessibility smoke test
- Android debug build
- Android integration flow
- manual screen-reader, large-text, high-contrast, reduced-motion, and colour-independence review
- Flutter profile-mode startup and gameplay review on the agreed reference device

Profile targets are a cold interactive startup under two seconds, input feedback on the next rendered frame, no recurring build or raster frame over 16.7 ms during ordinary 60 Hz gameplay, and no full-history decoding or database scan on a gameplay path.

Automated coverage includes every engine and scorer, seeded generation, rotation coverage, adaptation boundaries, comparison rules, per-game baselines and rolling trends, weekly recommendation, streaks, migration, all 15 game screens, pause/quit, reviews, Insights states, accessibility configurations, and restart/persistence.

## 12. Out of scope

This release does not include leaderboards, social competition, AI coaching, accounts, cloud sync, a backend, ads, age norms, diagnosis, clinical claims, or scored gameplay modifiers.
