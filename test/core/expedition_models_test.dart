import 'dart:math';

import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/training/training_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the expedition catalog contains ten distinct active games', () {
    expect(activeGames, const [
      GameType.colorClash,
      GameType.mathBlitz,
      GameType.memoryTiles,
      GameType.signalStop,
      GameType.nBackNavigator,
      GameType.ruleSwitch,
      GameType.pairLink,
      GameType.objectTracker,
      GameType.towerPlanner,
      GameType.spatialRotation,
    ]);
    expect(
      archivedGames,
      containsAll(const {
        GameType.reflexTap,
        GameType.visualSearch,
        GameType.peripheralFocus,
        GameType.arrowGuard,
        GameType.symbolSprint,
        GameType.dualTaskDash,
        GameType.logicSeries,
      }),
    );
  });

  test('daily expedition selects one stage per region and a unique bonus', () {
    final plan = dailyExpeditionSelection(const [], random: Random(7));

    expect(plan.coreGames, hasLength(3));
    expect(plan.coreGames.map((game) => game.region).toSet(), {
      ExpeditionRegion.focusFrontier,
      ExpeditionRegion.memoryGrove,
      ExpeditionRegion.puzzlePeaks,
    });
    expect(plan.bonusGame, isNot(isIn(plan.coreGames)));
  });

  test('explorer progress and new expedition drafts round-trip', () {
    final state = BrainState(
      explorerProgress: const ExplorerProgress(
        totalMapStars: 9,
        regionStars: {
          ExpeditionRegion.focusFrontier: 4,
          ExpeditionRegion.memoryGrove: 3,
          ExpeditionRegion.puzzlePeaks: 2,
        },
      ),
      draft: const WorkoutDraft(
        date: '2026-10-22',
        order: [
          GameType.colorClash,
          GameType.memoryTiles,
          GameType.towerPlanner,
        ],
        requiredRoundCount: 3,
        bonusGame: GameType.objectTracker,
      ),
    );

    final restored = BrainState.decode(state.encode());

    expect(restored.explorerProgress.totalMapStars, 9);
    expect(
      restored.explorerProgress.regionStars[ExpeditionRegion.focusFrontier],
      4,
    );
    expect(restored.draft!.requiredRoundCount, 3);
    expect(restored.draft!.bonusGame, GameType.objectTracker);
  });

  test('legacy character fields are ignored without losing star progress', () {
    final progress = ExplorerProgress.fromJson({
      'totalMapStars': 9,
      'regionStars': {'focusFrontier': 4, 'memoryGrove': 3},
      'seenRewardIds': ['nova-scout-cap'],
      'equippedRewardId': 'nova-scout-cap',
    });

    expect(progress.totalMapStars, 9);
    expect(progress.regionStars, {
      ExpeditionRegion.focusFrontier: 4,
      ExpeditionRegion.memoryGrove: 3,
    });
    expect(progress.toJson(), isNot(contains('seenRewardIds')));
    expect(progress.toJson(), isNot(contains('equippedRewardId')));
  });

  test(
    'legacy five-game drafts remain resumable without becoming a bonus run',
    () {
      final draft = WorkoutDraft.fromJson({
        'date': '2026-10-21',
        'order': [
          'colorClash',
          'mathBlitz',
          'memoryTiles',
          'signalStop',
          'nBackNavigator',
        ],
        'results': <Object>[],
      });

      expect(draft.requiredRoundCount, 5);
      expect(draft.bonusGame, isNull);
    },
  );

  test(
    'reward catalog contains twelve deterministic collectible thresholds',
    () {
      expect(expeditionRewards, hasLength(12));
      expect(
        expeditionRewards.map((reward) => reward.requiredStars).toList(),
        orderedEquals(<int>[3, 6, 9, 12, 18, 24, 30, 39, 48, 60, 75, 90]),
      );
      expect(
        unlockedExpeditionRewards(9).map((reward) => reward.id),
        orderedEquals(const ['scout-cap', 'prism-pin', 'memory-leaf']),
      );
    },
  );
}
