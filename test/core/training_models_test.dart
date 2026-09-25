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
}

DailySummary _summary(String date) =>
    DailySummary(date: date, results: const [], skillRatings: const {});
