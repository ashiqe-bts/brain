import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';

void main() {
  late AppDatabase database;
  late BrainRepository repository;
  late BrainCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BrainRepository(database);
    cubit = BrainCubit(
      repository,
      BrainState(
        difficulties: {for (final game in GameType.values) game.name: 4},
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  test('difficulty changes only after three comparable sessions', () async {
    await cubit.recordResult(_result(1, 90));
    await cubit.recordResult(_result(2, 92));
    expect(cubit.data.difficulties[GameType.colorClash.name], 4);

    await cubit.recordResult(_result(3, 70));
    expect(cubit.data.difficulties[GameType.colorClash.name], 5);
  });

  test('relaxed sessions do not change difficulty or earn xp', () async {
    final beforeXp = cubit.data.xp;
    await cubit.recordResult(_result(1, 99, mode: GameMode.relaxed));

    expect(cubit.data.difficulties[GameType.colorClash.name], 4);
    expect(cubit.data.xp, beforeXp);
  });

  test('adaptation ignores results from a different difficulty', () async {
    await cubit.recordResult(_result(1, 95, difficulty: 3));
    await cubit.recordResult(_result(2, 95, difficulty: 3));
    await cubit.recordResult(_result(3, 70));

    expect(cubit.data.difficulties[GameType.colorClash.name], 4);
  });

  test('recorded sessions always receive a completion timestamp', () async {
    final result = GameResult(
      type: GameType.colorClash,
      mode: GameMode.standard,
      score: 8,
      normalized: 80,
      accuracy: .8,
      durationMs: 30000,
      difficulty: 4,
      rulesVersion: GameType.colorClash.rulesVersion,
    );

    await cubit.recordResult(result);

    expect(cubit.data.history.single.completedAt, isNotNull);
    expect(cubit.data.history.single.isLegacy, isFalse);
  });

  test(
    'daily workout uses five-game rotation and stores dynamic ratings',
    () async {
      await cubit.startWorkout();
      final order = cubit.data.draft!.order;
      expect(order, dailyOrderForWorkout(0));
      expect(order, hasLength(5));

      for (final game in order) {
        await cubit.recordResult(
          GameResult(
            type: game,
            mode: GameMode.official,
            score: 80,
            normalized: 80,
            accuracy: .8,
            durationMs: 30000,
            difficulty: 4,
            completedAt: DateTime.utc(2026, 1, 1),
            rulesVersion: game.rulesVersion,
            correct: 8,
            attempts: 10,
          ),
        );
      }

      final summary = await cubit.completeWorkout();
      expect(summary, isNotNull);
      expect(summary!.results.map((result) => result.type), order);
      expect(summary.gameRatings.keys.toSet(), order.toSet());
      expect(cubit.data.workouts, 1);
    },
  );

  test('stores a normalized local name and tutorial completion', () async {
    await cubit.setDisplayName('  Asha  ');
    await cubit.completeTutorial(GameType.signalStop);

    expect(cubit.data.displayName, 'Asha');
    expect(cubit.hasCompletedTutorial(GameType.signalStop), isTrue);
    expect(cubit.hasCompletedTutorial(GameType.colorClash), isFalse);
  });

  test(
    'bootstrap treats current-version history as prior tutorial play',
    () async {
      cubit.data.history.add(_result(1, 80));

      await cubit.bootstrap();

      expect(cubit.hasCompletedTutorial(GameType.colorClash), isTrue);
    },
  );

  test(
    'bootstrap does not satisfy a tutorial with older-rule history',
    () async {
      cubit.data.history.add(
        _result(1, 80, rulesVersion: GameType.colorClash.rulesVersion - 1),
      );

      await cubit.bootstrap();

      expect(cubit.hasCompletedTutorial(GameType.colorClash), isFalse);
    },
  );
}

GameResult _result(
  int day,
  double score, {
  GameMode mode = GameMode.standard,
  int difficulty = 4,
  int? rulesVersion,
}) => GameResult(
  type: GameType.colorClash,
  mode: mode,
  score: score.round(),
  normalized: score,
  accuracy: .9,
  durationMs: 30000,
  difficulty: difficulty,
  completedAt: DateTime.utc(2026, 1, day),
  rulesVersion: rulesVersion ?? GameType.colorClash.rulesVersion,
);
