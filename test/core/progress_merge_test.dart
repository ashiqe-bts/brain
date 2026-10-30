import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/sync/progress_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge unions stable sessions and recomputes daily progress', () {
    final local = BrainState(
      displayName: 'Asha',
      xp: 120,
      level: 2,
      daily: [_daily('2026-10-05', 'local-session')],
      history: [_result('local-session', 5, 80)],
      achievements: {'starter'},
      completedTutorials: {'colorClash:v3'},
      explorerProgress: const ExplorerProgress(
        totalMapStars: 9,
        regionStars: {ExpeditionRegion.focusFrontier: 5},
      ),
    );
    final cloud = BrainState(
      displayName: 'Cloud name',
      xp: 80,
      level: 3,
      daily: [_daily('2026-10-04', 'cloud-session')],
      history: [_result('cloud-session', 4, 90)],
      achievements: {'steady'},
      completedTutorials: {'mathBlitz:v3'},
      explorerProgress: const ExplorerProgress(
        totalMapStars: 6,
        regionStars: {
          ExpeditionRegion.focusFrontier: 2,
          ExpeditionRegion.memoryGrove: 4,
        },
      ),
    );

    final merged = mergeProgress(local: local, cloud: cloud);

    expect(merged.displayName, 'Cloud name');
    expect(merged.history.map((item) => item.id), {
      'local-session',
      'cloud-session',
    });
    expect(merged.daily.map((item) => item.date), ['2026-10-04', '2026-10-05']);
    expect(merged.currentStreak, 2);
    expect(merged.longestStreak, 2);
    expect(merged.workouts, 2);
    expect(merged.xp, 120);
    expect(merged.level, 3);
    expect(merged.achievements, {'starter', 'steady'});
    expect(merged.completedTutorials, {'colorClash:v3', 'mathBlitz:v3'});
    expect(merged.explorerProgress.totalMapStars, 9);
    expect(merged.explorerProgress.regionStars, {
      ExpeditionRegion.focusFrontier: 5,
      ExpeditionRegion.memoryGrove: 4,
    });
  });

  test('merge prefers the more complete summary for the same day', () {
    final shorter = _daily('2026-10-05', 'one');
    final fuller = DailySummary(
      date: '2026-10-05',
      results: [_result('one', 5, 70), _result('two', 5, 90)],
    );

    final merged = mergeProgress(
      local: BrainState(daily: [shorter]),
      cloud: BrainState(daily: [fuller]),
    );

    expect(merged.daily.single.results, hasLength(2));
  });
}

GameResult _result(String id, int day, double normalized) => GameResult(
  id: id,
  type: GameType.colorClash,
  mode: GameMode.official,
  score: normalized.round(),
  normalized: normalized,
  accuracy: .8,
  durationMs: 30000,
  difficulty: 4,
  completedAt: DateTime.utc(2026, 10, day),
  rulesVersion: GameType.colorClash.rulesVersion,
);

DailySummary _daily(String date, String resultId) => DailySummary(
  date: date,
  results: [_result(resultId, int.parse(date.substring(8)), 80)],
);
