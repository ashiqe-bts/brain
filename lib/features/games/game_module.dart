import '../../core/models/brain_models.dart';

/// A typed input understood by a game controller.
sealed class GameAction {
  const GameAction();
}

final class TapAction extends GameAction {
  const TapAction(this.target);
  final int target;
}

final class SwipeAction extends GameAction {
  const SwipeAction(this.direction);
  final AxisDirection direction;
}

enum AxisDirection { left, right, up, down }

final class SelectObjectAction extends GameAction {
  const SelectObjectAction(this.objectId);
  final int objectId;
}

final class MoveDiskAction extends GameAction {
  const MoveDiskAction({required this.from, required this.to});
  final int from;
  final int to;
}

final class RotateAction extends GameAction {
  const RotateAction(this.quarterTurns);
  final int quarterTurns;
}

/// Marker contract for immutable, replayable game state.
abstract interface class GameModuleState {
  int get trialNumber;
}

/// Pure seeded controllers can be replayed in tests without a Flutter clock.
abstract interface class SeededGameController<S extends GameModuleState> {
  S get state;
  S dispatch(GameAction action);
}

enum GameEngineFamily { classic, research }

enum GameInteraction {
  tapInkColour,
  swipeEquation,
  tapChangedTile,
  withholdSignal,
  compareBeacon,
  routeToken,
  reconnectPair,
  selectTrackedObjects,
  moveDisk,
  rotatePiece,
  genericMultipleChoice,
}

class GameModuleDefinition {
  const GameModuleDefinition({
    required this.type,
    required this.engineFamily,
    required this.interaction,
    required this.metricKeys,
    required this.accessibilityAlternative,
  });

  final GameType type;
  final GameEngineFamily engineFamily;
  final GameInteraction interaction;
  final List<String> metricKeys;
  final String accessibilityAlternative;

  int get rulesVersion => type.rulesVersion;
  ExpeditionRegion get region => type.region;
}

const _modules = <GameType, GameModuleDefinition>{
  GameType.colorClash: GameModuleDefinition(
    type: GameType.colorClash,
    engineFamily: GameEngineFamily.classic,
    interaction: GameInteraction.tapInkColour,
    metricKeys: ['accuracy', 'medianResponseMs', 'interferenceCostMs'],
    accessibilityAlternative: 'Four labelled colour controls',
  ),
  GameType.mathBlitz: GameModuleDefinition(
    type: GameType.mathBlitz,
    engineFamily: GameEngineFamily.classic,
    interaction: GameInteraction.swipeEquation,
    metricKeys: ['accuracy', 'medianResponseMs'],
    accessibilityAlternative: 'True and false tap gates',
  ),
  GameType.memoryTiles: GameModuleDefinition(
    type: GameType.memoryTiles,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.tapChangedTile,
    metricKeys: ['capacity', 'exposureDurationMs', 'errors'],
    accessibilityAlternative: 'Numbered grid cells',
  ),
  GameType.signalStop: GameModuleDefinition(
    type: GameType.signalStop,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.withholdSignal,
    metricKeys: ['stopSuccessRate', 'estimatedStoppingMs'],
    accessibilityAlternative: 'Labelled launch control and wait cue',
  ),
  GameType.nBackNavigator: GameModuleDefinition(
    type: GameType.nBackNavigator,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.compareBeacon,
    metricKeys: ['discrimination', 'hits', 'falseAlarms'],
    accessibilityAlternative: 'Match and new tap controls',
  ),
  GameType.ruleSwitch: GameModuleDefinition(
    type: GameType.ruleSwitch,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.routeToken,
    metricKeys: ['accuracy', 'switchCostMs'],
    accessibilityAlternative: 'Labelled route gates',
  ),
  GameType.pairLink: GameModuleDefinition(
    type: GameType.pairLink,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.reconnectPair,
    metricKeys: ['accuracy', 'medianResponseMs', 'span'],
    accessibilityAlternative: 'Labelled portal choices',
  ),
  GameType.objectTracker: GameModuleDefinition(
    type: GameType.objectTracker,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.selectTrackedObjects,
    metricKeys: ['objectCount', 'trackingAccuracy'],
    accessibilityAlternative: 'Direct multi-select with confirm control',
  ),
  GameType.towerPlanner: GameModuleDefinition(
    type: GameType.towerPlanner,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.moveDisk,
    metricKeys: ['solvedTrials', 'excessMoves', 'planningMedianMs'],
    accessibilityAlternative: 'Tap source peg then destination peg',
  ),
  GameType.spatialRotation: GameModuleDefinition(
    type: GameType.spatialRotation,
    engineFamily: GameEngineFamily.research,
    interaction: GameInteraction.rotatePiece,
    metricKeys: ['accuracy', 'medianResponseMs'],
    accessibilityAlternative: 'Same and mirrored tap controls',
  ),
};

GameModuleDefinition gameModule(GameType type) {
  final module = _modules[type];
  if (module == null) {
    throw UnsupportedError('${type.name} is archived and has no active module');
  }
  return module;
}
