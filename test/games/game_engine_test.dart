import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/features/games/game_engine.dart';

void main() {
  test('color trials are deterministic and balanced', () {
    final first = GameTrialFactory(42).colorTrials(20);
    final second = GameTrialFactory(42).colorTrials(20);

    expect(first, second);
    expect(first.where((trial) => trial.isCongruent), hasLength(10));
  });

  test('false math trials never show the actual answer', () {
    final trials = GameTrialFactory(7).mathTrials(5, count: 100);
    final falseTrials = trials.where((trial) => !trial.isCorrect);

    expect(falseTrials, isNotEmpty);
    expect(falseTrials.every((trial) => trial.shown != trial.actual), isTrue);
  });

  test(
    'visual search has exactly one target and deterministic distractors',
    () {
      final trial = GameTrialFactory(12).visualSearch(6, itemCount: 24);

      expect(trial.items.where((glyph) => glyph == trial.target), hasLength(1));
      expect(trial.targetIndex, inInclusiveRange(0, 23));
      expect(GameTrialFactory(12).visualSearch(6, itemCount: 24), trial);
    },
  );

  test('median response time is stable for odd and even samples', () {
    expect(medianMilliseconds([900, 300, 600]), 600);
    expect(medianMilliseconds([100, 300, 500, 700]), 400);
    expect(medianMilliseconds(const []), 0);
  });
}
