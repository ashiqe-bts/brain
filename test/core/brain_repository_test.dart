import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';

void main() {
  late AppDatabase database;
  late BrainRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BrainRepository(database);
  });

  tearDown(() => repository.close());

  test('stored sessions retain timestamps, rules, and stable ids', () async {
    final completedAt = DateTime.utc(2026, 1, 2, 12);
    await repository.saveGame(
      GameResult(
        type: GameType.colorClash,
        mode: GameMode.standard,
        score: 14,
        normalized: 82,
        accuracy: .9,
        durationMs: 30000,
        difficulty: 4,
        completedAt: completedAt,
        rulesVersion: 2,
        metrics: const {'medianResponseMs': 640},
        scoreComponents: const {'accuracy': 63, 'pace': 19, 'penalty': 0},
      ),
    );

    final sessions = await repository.loadSessions(limit: 10);

    expect(sessions, hasLength(1));
    expect(sessions.single.id, isNotEmpty);
    expect(sessions.single.completedAt, completedAt);
    expect(sessions.single.rulesVersion, 2);
    expect(sessions.single.metrics['medianResponseMs'], 640);
    expect(sessions.single.scoreComponents['accuracy'], 63);
  });

  test(
    'load preserves legacy snapshot results without putting them in trends',
    () async {
      final state = BrainState(
        history: const [
          GameResult(
            type: GameType.memoryTiles,
            mode: GameMode.standard,
            score: 7,
            normalized: 70,
            accuracy: .8,
            durationMs: 12000,
            difficulty: 2,
            isLegacy: true,
          ),
        ],
      );
      await repository.save(state);

      final loaded = await repository.load();

      expect(loaded.history, hasLength(1));
      expect(loaded.history.single.contributesToTrends, isFalse);
      expect(await repository.hasMigrationBackup(), isTrue);
    },
  );

  test('partial legacy daily summaries decode without data loss', () async {
    await database
        .into(database.appSnapshots)
        .insert(
          AppSnapshotsCompanion.insert(
            key: 'state',
            value: '{"onboarded":true,"daily":[{"date":"2025-12-01"}]}',
            updatedAt: DateTime.utc(2026),
          ),
        );

    final loaded = await repository.load();

    expect(loaded.onboarded, isTrue);
    expect(loaded.daily.single.date, '2025-12-01');
    expect(loaded.daily.single.results, isEmpty);
  });
}
