import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/core/models/brain_models.dart';
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

    test('ignores retired mascot economy fields after decoding', () {
      final state = BrainState.decode(
        jsonEncode({
          'onboarded': true,
          'energy': 90,
          'tokens': 8,
          'mood': 'happy',
          'equipped': {'hat': 'Crown'},
          'difficulties': {'oddOneOut': 5},
        }),
      );

      final encoded = state.toJson();
      expect(encoded, isNot(contains('energy')));
      expect(encoded, isNot(contains('tokens')));
      expect(encoded, isNot(contains('mood')));
      expect(encoded, isNot(contains('equipped')));
      expect(state.difficulties[GameType.visualSearch.name], 5);
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
  });

  group('progressive baseline', () {
    test('requires three completed daily workouts', () {
      expect(baselineStatus(const []).remaining, 3);
      expect(
        baselineStatus([
          _summary('2026-01-01'),
          _summary('2026-01-02'),
        ]).remaining,
        1,
      );
      expect(
        baselineStatus([
          _summary('2026-01-01'),
          _summary('2026-01-02'),
          _summary('2026-01-03'),
        ]).isComplete,
        isTrue,
      );
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

    test('feedback recommends accuracy before speed', () {
      expect(
        sessionTip(_result(day: 1, normalized: 45, accuracy: .55)),
        contains('accuracy'),
      );
    });
  });
}

DailySummary _summary(String date) =>
    DailySummary(date: date, results: const [], skillRatings: const {});

GameResult _result({
  required int day,
  required double normalized,
  double accuracy = .9,
  GameMode mode = GameMode.official,
}) => GameResult(
  type: GameType.colorClash,
  mode: mode,
  score: normalized.round(),
  normalized: normalized,
  accuracy: accuracy,
  durationMs: 30000,
  difficulty: 4,
  completedAt: DateTime.utc(2026, 1, day),
  rulesVersion: 2,
);
