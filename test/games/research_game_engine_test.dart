import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/games/research_game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final researchGames = activeGames.where(
    (game) => game != GameType.colorClash && game != GameType.mathBlitz,
  );

  test('every research game creates a playable deterministic trial', () {
    for (final game in researchGames) {
      final first = ResearchGameEngine(seed: 42, type: game, difficulty: 4);
      final second = ResearchGameEngine(seed: 42, type: game, difficulty: 4);

      final trial = first.nextTrial();
      final repeated = second.nextTrial();

      expect(trial.options.length, greaterThanOrEqualTo(2), reason: game.name);
      expect(
        trial.correctIndex,
        inInclusiveRange(0, trial.options.length - 1),
        reason: game.name,
      );
      expect(repeated.prompt, trial.prompt, reason: game.name);
      expect(repeated.options, trial.options, reason: game.name);
      expect(repeated.correctIndex, trial.correctIndex, reason: game.name);
      expect(trial.visual, isA<ResearchVisual>(), reason: game.name);
      expect(repeated.visual.runtimeType, trial.visual.runtimeType);
    }
  });

  test('n-back eventually presents both match and non-match trials', () {
    final engine = ResearchGameEngine(
      seed: 7,
      type: GameType.nBackNavigator,
      difficulty: 5,
    );

    final trials = List.generate(30, (_) => engine.nextTrial());
    expect(trials.map((trial) => trial.correctIndex).toSet(), {0, 1});
  });

  test('signal stop includes go and stop conditions', () {
    final engine = ResearchGameEngine(
      seed: 11,
      type: GameType.signalStop,
      difficulty: 3,
    );

    final conditions = List.generate(
      30,
      (_) => engine.nextTrial().condition,
    ).toSet();
    expect(conditions, containsAll(<String>{'go', 'stop'}));
  });

  test('memory visual payload preserves the generated zero-based grid', () {
    final trial = ResearchGameEngine(
      seed: 12,
      type: GameType.memoryTiles,
      difficulty: 4,
    ).nextTrial();
    final visual = trial.visual as MemoryGridVisual;
    final promptCells = trial.prompt.split(',').map(int.parse).toSet();
    final cueCells = trial.cue.split(',').map(int.parse).toSet();

    expect(visual.before.map((cell) => cell + 1).toSet(), promptCells);
    expect(visual.after.map((cell) => cell + 1).toSet(), cueCells);
  });

  test('object tracking asks for final positions, not visible identities', () {
    final trial = ResearchGameEngine(
      seed: 8,
      type: GameType.objectTracker,
      difficulty: 7,
    ).nextTrial();

    expect(trial.movement.toSet(), hasLength(6));
    expect(trial.movement.every((slot) => slot >= 0 && slot < 6), isTrue);
    expect(
      trial.options[trial.correctIndex],
      matches(RegExp(r'^[A-F](?:-[A-F])+$')),
    );
  });

  test('tower planner never offers a self-move', () {
    final engine = ResearchGameEngine(
      seed: 9,
      type: GameType.towerPlanner,
      difficulty: 8,
    );

    for (var turn = 0; turn < 20; turn++) {
      final trial = engine.nextTrial();
      for (final option in trial.options) {
        final move = RegExp(r'(\d) → (\d)').firstMatch(option)!;
        expect(move.group(1), isNot(move.group(2)));
      }
      engine.acceptAnswer(trial, trial.correctIndex);
    }
    expect(engine.towerSolvedTrials, greaterThan(0));
    expect(engine.towerExcessMoves, 0);
  });

  test('pair link includes delayed retrieval trials', () {
    final engine = ResearchGameEngine(
      seed: 10,
      type: GameType.pairLink,
      difficulty: 4,
    );

    final trials = List.generate(6, (_) => engine.nextTrial());
    expect(trials.map((trial) => trial.condition), contains('delayed'));
    expect(
      trials.where((trial) => trial.condition == 'delayed'),
      everyElement(predicate<ResearchTrial>((trial) => trial.exposureMs == 0)),
    );
  });
}
