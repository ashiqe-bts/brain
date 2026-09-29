import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/training/game_catalog.dart';
import 'package:brainflex/core/training/training_analytics.dart';

void main() {
  group('legacy result migration', () {
    test('maps odd one out records to visual search', () {
      final result = GameResult.fromJson({
        'type': 'oddOneOut',
        'mode': 'classic',
        'score': 12,
        'normalized': 72.0,
        'accuracy': .8,
        'durationMs': 30000,
        'difficulty': 3,
      });

      expect(result.type, GameType.visualSearch);
      expect(result.mode, GameMode.standard);
      expect(result.isLegacy, isTrue);
    });

    test('preserves odd one out difficulty as visual search difficulty', () {
      final migrated = migrateDifficulties({'oddOneOut': 6});

      expect(migrated[GameType.visualSearch.name], 6);
      expect(migrated, isNot(contains('oddOneOut')));
    });
  });

  group('research-informed game catalog', () {
    test('contains fifteen active and two archived games', () {
      expect(activeGames, hasLength(15));
      expect(activeGames.toSet(), hasLength(15));
      expect(archivedGames, {GameType.reflexTap, GameType.visualSearch});
      expect(activeGames, isNot(contains(GameType.reflexTap)));
      expect(activeGames, isNot(contains(GameType.visualSearch)));
    });

    test('three consecutive workouts cover every active game once', () {
      final rounds = [
        dailyOrderForWorkout(0),
        dailyOrderForWorkout(1),
        dailyOrderForWorkout(2),
      ];

      expect(rounds.every((round) => round.length == 5), isTrue);
      expect(rounds.expand((round) => round).toSet(), activeGames.toSet());
      expect(rounds.expand((round) => round), hasLength(15));
    });

    test('rotation is stable for the same workout number', () {
      expect(dailyOrderForWorkout(7), dailyOrderForWorkout(7));
    });

    test('every active game has a transparent research note', () {
      for (final game in activeGames) {
        final definition = gameDefinition(game);
        expect(definition.instructions, isNotEmpty, reason: game.name);
        expect(definition.evidence.summary, isNotEmpty, reason: game.name);
        expect(definition.evidence.population, isNotEmpty, reason: game.name);
        expect(definition.evidence.limitation, isNotEmpty, reason: game.name);
        expect(definition.evidence.reference, contains('PMID'));
        expect(definition.supportedModes, contains(GameMode.official));
        expect(definition.minimumDifficulty, 1);
        expect(definition.maximumDifficulty, 10);
        expect(definition.rawMetricFormatter(const {}), isA<String>());
        expect(definition.tutorial.steps, isNotEmpty, reason: game.name);
        expect(
          definition.tutorial.steps.every(
            (step) =>
                step.isWaitStep ||
                (step.options.length >= 2 &&
                    step.correctIndex >= 0 &&
                    step.correctIndex < step.options.length),
          ),
          isTrue,
          reason: game.name,
        );
      }
    });
  });

  group('game scoring', () {
    test('uses skill-specific metrics instead of one shared formula', () {
      final focus = scoreGame(
        type: GameType.colorClash,
        difficulty: 3,
        accuracy: .9,
        medianResponseMs: 700,
      );
      final reaction = scoreGame(
        type: GameType.reflexTap,
        difficulty: 3,
        accuracy: .9,
        medianResponseMs: 700,
      );

      expect(focus, greaterThan(reaction));
      expect(focus, inInclusiveRange(0, 100));
      expect(reaction, inInclusiveRange(0, 100));
    });

    test('training level combines difficulty and within-level score', () {
      expect(trainingLevel(difficulty: 4, score: 50), 3.5);
      expect(trainingLevel(difficulty: 10, score: 100), 10);
    });

    test('exposes versioned score components and typed raw metrics', () {
      final score = scoreGameDetails(
        type: GameType.reflexTap,
        difficulty: 3,
        accuracy: .8,
        medianResponseMs: 300,
        falseStarts: 1,
      );
      final result = _result(day: 1, normalized: score.normalized).copyWith();

      expect(score.accuracyContribution, greaterThan(0));
      expect(score.paceContribution, greaterThan(0));
      expect(score.penalty, 6);
      expect(result.rawMetrics, isA<FocusMetrics>());
      expect(result.comparableSeries().accepts(result), isTrue);
    });
  });

  group('per-game baseline', () {
    test('requires three current official results for every active game', () {
      final history = <GameResult>[];
      for (var repetition = 0; repetition < 3; repetition++) {
        for (final game in activeGames) {
          history.add(
            _result(
              day: repetition + 1,
              normalized: 80,
              type: game,
              rulesVersion: game.rulesVersion,
            ),
          );
        }
      }

      final status = baselineStatus(history);
      expect(status.completedRounds, 45);
      expect(status.requiredRounds, 45);
      expect(status.isComplete, isTrue);
      expect(status.forGame(GameType.colorClash).isComplete, isTrue);

      final incomplete = baselineStatus(history.take(44));
      expect(incomplete.completedRounds, 44);
      expect(incomplete.isComplete, isFalse);
    });

    test('ignores relaxed and older-rule results', () {
      final game = GameType.colorClash;
      final status = baselineStatus([
        _result(
          day: 1,
          normalized: 80,
          type: game,
          mode: GameMode.relaxed,
          rulesVersion: game.rulesVersion,
        ),
        _result(
          day: 2,
          normalized: 80,
          type: game,
          rulesVersion: game.rulesVersion - 1,
        ),
      ]);

      expect(status.forGame(game).completed, 0);
      expect(status.isComplete, isFalse);
    });
  });

  group('daily summary compatibility', () {
    test('round-trips dynamic per-game ratings', () {
      final summary = DailySummary(
        date: '2026-01-01',
        results: const [],
        gameRatings: const {
          GameType.signalStop: 3.2,
          GameType.logicSeries: 4.1,
        },
      );

      final decoded = DailySummary.fromJson(summary.toJson());
      expect(decoded.gameRatings[GameType.signalStop], 3.2);
      expect(decoded.gameRatings[GameType.logicSeries], 4.1);
    });

    test('decodes older summaries without dynamic ratings', () {
      final decoded = DailySummary.fromJson({
        'date': '2025-12-01',
        'results': <Object>[],
      });

      expect(decoded.gameRatings, isEmpty);
    });
  });

  group('local profile compatibility', () {
    test('round-trips display name and versioned tutorial completion', () {
      final state = BrainState(
        onboarded: true,
        displayName: 'Asha',
        completedTutorials: {
          GameType.colorClash.tutorialKey,
          GameType.signalStop.tutorialKey,
        },
      );

      final decoded = BrainState.decode(state.encode());

      expect(decoded.displayName, 'Asha');
      expect(decoded.completedTutorials, state.completedTutorials);
    });

    test('decodes older state without profile or tutorials', () {
      final decoded = BrainState.decode('{"onboarded":true}');

      expect(decoded.displayName, isNull);
      expect(decoded.completedTutorials, isEmpty);
    });

    test('validates and normalizes local display names', () {
      expect(normalizeDisplayName('  Asha  '), 'Asha');
      expect(displayNameError('  '), isNotNull);
      expect(displayNameError('Asha\nPatel'), isNotNull);
      expect(displayNameError(List.filled(31, 'a').join()), isNotNull);
      expect(displayNameError('Renée'), isNull);
    });
  });

  group('adaptive difficulty', () {
    test('moves at most one step after two mastered results', () {
      expect(adaptDifficulty(4, [88, 91, 70]), 5);
      expect(adaptDifficulty(10, [90, 92, 95]), 10);
    });

    test('drops after two struggling results and otherwise holds', () {
      expect(adaptDifficulty(4, [42, 58, 75]), 3);
      expect(adaptDifficulty(4, [42, 72, 75]), 4);
      expect(adaptDifficulty(1, [20, 30, 80]), 1);
    });

    test('supports versioned game-specific mastery bands', () {
      expect(
        adaptDifficulty(4, [82, 83, 70], masteryScore: 82, struggleScore: 55),
        5,
      );
    });
  });

  group('skill trends and reviews', () {
    test('requires three post-baseline observations before naming a trend', () {
      final sessions = List.generate(
        5,
        (index) => _result(day: index + 1, normalized: 60 + index * 5),
      );

      expect(
        skillTrend(GameType.colorClash, sessions).direction,
        TrendDirection.insufficient,
      );
    });

    test('uses rolling medians and ignores relaxed sessions', () {
      final sessions = [
        ...List.generate(3, (index) => _result(day: index + 1, normalized: 55)),
        ...List.generate(3, (index) => _result(day: index + 4, normalized: 90)),
        _result(day: 7, normalized: 1, mode: GameMode.relaxed),
      ];

      final trend = skillTrend(GameType.colorClash, sessions);

      expect(trend.direction, TrendDirection.improving);
      expect(trend.delta, greaterThan(.2));
      expect(trend.samples, 6);
    });

    test('ignores results from an older rules version', () {
      final current = _result(
        day: 2,
        normalized: 80,
        rulesVersion: GameType.colorClash.rulesVersion,
      );
      final older = _result(
        day: 1,
        normalized: 100,
        rulesVersion: GameType.colorClash.rulesVersion - 1,
      );

      final trend = skillTrend(GameType.colorClash, [older, current]);
      expect(trend.samples, 1);
      expect(trend.currentLevel, trainingLevel(difficulty: 4, score: 80));
      expect(skillTrend(GameType.colorClash, [older]).samples, 0);
    });

    test('feedback recommends accuracy before speed', () {
      expect(
        sessionTip(_result(day: 1, normalized: 45, accuracy: .55)),
        contains('accuracy'),
      );
    });

    test('session comparison uses baseline median and previous attempt', () {
      final baseline = [
        _result(day: 1, normalized: 50),
        _result(day: 2, normalized: 60),
        _result(day: 3, normalized: 70),
      ];
      final current = _result(day: 4, normalized: 90);

      final comparison = sessionComparison(
        result: current,
        history: [...baseline, current],
        daily: [
          _summary('2026-01-01', results: [baseline[0]]),
          _summary('2026-01-02', results: [baseline[1]]),
          _summary('2026-01-03', results: [baseline[2]]),
        ],
      );

      expect(comparison.baselineDelta, closeTo(.3, .001));
      expect(comparison.previousDelta, closeTo(.2, .001));
      expect(comparison.previousCompletedAt, DateTime.utc(2026, 1, 3));
      expect(
        selfComparisonMessage(comparison, currentAt: current.completedAt!),
        'Better than yesterday by 0.2 levels.',
      );
    });

    test('session comparison explains insufficient compatible data', () {
      final current = _result(day: 2, normalized: 70);

      final comparison = sessionComparison(
        result: current,
        history: [current],
        daily: [
          _summary('2026-01-02', results: [current]),
        ],
      );

      expect(comparison.baselineDelta, isNull);
      expect(comparison.previousDelta, isNull);
      expect(comparison.previousCompletedAt, isNull);
      expect(
        selfComparisonMessage(comparison, currentAt: current.completedAt!),
        'This is your personal starting point.',
      );
    });

    test('latest scored comparison includes challenge mode only', () {
      final standard = _result(day: 1, normalized: 50);
      final challenge = _result(
        day: 2,
        normalized: 80,
        mode: GameMode.personalBest,
      );
      final relaxed = _result(day: 3, normalized: 100, mode: GameMode.relaxed);
      final current = _result(day: 4, normalized: 90);

      final comparison = sessionComparison(
        result: current,
        history: [standard, challenge, relaxed, current],
        daily: const [],
      );

      expect(comparison.previousCompletedAt, challenge.completedAt);
      expect(comparison.previousDelta, closeTo(.1, .001));
    });

    test('self comparison distinguishes last run, matches, and variation', () {
      expect(
        selfComparisonMessage(
          const SessionComparison(previousDelta: .3, previousCompletedAt: null),
          currentAt: DateTime(2026, 1, 10),
        ),
        'Better than your last run by 0.3 levels.',
      );
      expect(
        selfComparisonMessage(
          SessionComparison(
            previousDelta: .01,
            previousCompletedAt: DateTime(2026, 1, 9),
          ),
          currentAt: DateTime(2026, 1, 10),
        ),
        'Matched yesterday.',
      );
      expect(
        selfComparisonMessage(
          SessionComparison(
            previousDelta: -.4,
            previousCompletedAt: DateTime(2026, 1, 5),
          ),
          currentAt: DateTime(2026, 1, 10),
        ),
        '0.4 levels below your last run. One session naturally varies.',
      );
    });
  });
}

DailySummary _summary(String date, {List<GameResult> results = const []}) =>
    DailySummary(date: date, results: results, skillRatings: const {});

GameResult _result({
  required int day,
  required double normalized,
  double accuracy = .9,
  GameMode mode = GameMode.official,
  GameType type = GameType.colorClash,
  int? rulesVersion,
}) => GameResult(
  type: type,
  mode: mode,
  score: normalized.round(),
  normalized: normalized,
  accuracy: accuracy,
  durationMs: 30000,
  difficulty: 4,
  completedAt: DateTime.utc(2026, 1, day),
  rulesVersion: rulesVersion ?? type.rulesVersion,
);
