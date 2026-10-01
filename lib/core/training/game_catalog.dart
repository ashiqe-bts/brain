import 'dart:math';

import '../config/app_config.dart';
import '../models/brain_models.dart';

typedef GameScorer = GameScore Function(GameScoreInput input);
typedef RawMetricFormatter = String Function(Map<String, double> metrics);

enum MetricDirection { higherIsBetter, lowerIsBetter, neutral }

class GameMetricDefinition {
  const GameMetricDefinition({
    required this.key,
    required this.label,
    required this.direction,
    this.unit = '',
    this.percent = false,
    this.decimals = 0,
  });

  static const trainingLevelKey = 'trainingLevel';
  static const accuracyKey = 'accuracy';

  final String key;
  final String label;
  final MetricDirection direction;
  final String unit;
  final bool percent;
  final int decimals;

  double? value(GameResult result) {
    final raw = switch (key) {
      trainingLevelKey => trainingLevel(
        difficulty: result.difficulty,
        score: result.normalized,
      ),
      accuracyKey => result.accuracy * 100,
      _ => result.metrics[key],
    };
    if (raw == null) return null;
    return percent && key != accuracyKey ? raw * 100 : raw;
  }

  String formatValue(GameResult result) {
    final number = value(result);
    if (number == null) return AppText.notRecorded;
    final text = number.toStringAsFixed(decimals);
    return percent
        ? '$text%'
        : unit.isEmpty
        ? text
        : '$text $unit';
  }
}

const _levelMetric = GameMetricDefinition(
  key: GameMetricDefinition.trainingLevelKey,
  label: AppText.metricTrainingLevel,
  direction: MetricDirection.higherIsBetter,
  decimals: 1,
);
const _accuracyMetric = GameMetricDefinition(
  key: GameMetricDefinition.accuracyKey,
  label: AppText.metricAccuracy,
  direction: MetricDirection.higherIsBetter,
  percent: true,
);
const _responseMetric = GameMetricDefinition(
  key: 'medianResponseMs',
  label: AppText.metricMedianResponse,
  direction: MetricDirection.lowerIsBetter,
  unit: 'ms',
);

List<GameMetricDefinition> gameMetricDefinitions(GameType type) {
  const interference = GameMetricDefinition(
    key: 'interferenceCostMs',
    label: AppText.metricInterferenceCost,
    direction: MetricDirection.lowerIsBetter,
    unit: 'ms',
  );
  const span = GameMetricDefinition(
    key: 'span',
    label: AppText.metricSpan,
    direction: MetricDirection.higherIsBetter,
  );
  final specific = switch (type) {
    GameType.colorClash => const [_responseMetric, interference],
    GameType.mathBlitz => const [_responseMetric],
    GameType.memoryTiles => const [
      span,
      GameMetricDefinition(
        key: 'capacity',
        label: AppText.metricCapacity,
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'exposureDurationMs',
        label: AppText.metricExposureDuration,
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.signalStop => const [
      GameMetricDefinition(
        key: 'stopSuccessRate',
        label: AppText.metricStopSuccess,
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
      GameMetricDefinition(
        key: 'estimatedStoppingMs',
        label: AppText.metricEstimatedStoppingTime,
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
      GameMetricDefinition(
        key: 'commissionErrors',
        label: AppText.metricCommissionErrors,
        direction: MetricDirection.lowerIsBetter,
      ),
    ],
    GameType.peripheralFocus => const [
      _responseMetric,
      GameMetricDefinition(
        key: 'exposureThresholdMs',
        label: AppText.metricExposureThreshold,
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.nBackNavigator => const [
      span,
      GameMetricDefinition(
        key: 'discrimination',
        label: AppText.metricDiscrimination,
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
    ],
    GameType.ruleSwitch => const [
      _responseMetric,
      GameMetricDefinition(
        key: 'switchCostMs',
        label: AppText.metricSwitchCost,
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.arrowGuard => const [_responseMetric, interference],
    GameType.pairLink => const [span],
    GameType.symbolSprint => const [
      _responseMetric,
      GameMetricDefinition(
        key: 'correctSubstitutions',
        label: AppText.metricCorrectSubstitutions,
        direction: MetricDirection.higherIsBetter,
      ),
    ],
    GameType.objectTracker => const [
      GameMetricDefinition(
        key: 'objectCount',
        label: AppText.metricObjectsTracked,
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'trackingAccuracy',
        label: AppText.metricTrackingAccuracy,
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
    ],
    GameType.towerPlanner => const [
      GameMetricDefinition(
        key: 'solvedTrials',
        label: AppText.metricSolvedTrials,
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'excessMoves',
        label: AppText.metricExcessMoves,
        direction: MetricDirection.lowerIsBetter,
      ),
      GameMetricDefinition(
        key: 'planningMedianMs',
        label: AppText.metricPlanningTime,
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.dualTaskDash => const [
      GameMetricDefinition(
        key: 'classificationAccuracy',
        label: AppText.metricClassificationAccuracy,
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
      GameMetricDefinition(
        key: 'countAccuracy',
        label: AppText.metricCountingAccuracy,
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
      _responseMetric,
    ],
    GameType.logicSeries || GameType.spatialRotation => const [_responseMetric],
    GameType.reflexTap || GameType.visualSearch => const [_responseMetric],
  };
  return [_levelMetric, _accuracyMetric, ...specific];
}

class GameScoreInput {
  const GameScoreInput({
    required this.difficulty,
    required this.accuracy,
    required this.medianResponseMs,
    required this.span,
    required this.falseStarts,
  });

  final int difficulty;
  final double accuracy;
  final int medianResponseMs;
  final int span;
  final int falseStarts;
}

class GameScore {
  const GameScore({
    required this.normalized,
    required this.accuracyContribution,
    required this.paceContribution,
    required this.penalty,
  });

  final double normalized;
  final double accuracyContribution;
  final double paceContribution;
  final double penalty;

  Map<String, double> toJson() => {
    'accuracy': accuracyContribution,
    'pace': paceContribution,
    'penalty': penalty,
  };
}

class GameDefinition {
  const GameDefinition({
    required this.type,
    required this.scorer,
    required this.rawMetricFormatter,
    this.standardSeconds = AppSettings.defaultTimedSessionSeconds,
    this.masteryScore = 85,
    this.struggleScore = 60,
    this.minimumDifficulty = AppSettings.minimumDifficulty,
    this.maximumDifficulty = AppSettings.maximumDifficulty,
    this.supportedModes = const {
      GameMode.standard,
      GameMode.relaxed,
      GameMode.personalBest,
      GameMode.official,
    },
  });

  final GameType type;
  String get instructions => gameContent[type]!.instructions;
  String get description => gameContent[type]!.description;
  ResearchEvidence get evidence => gameContent[type]!.evidence;
  final GameScorer scorer;
  final RawMetricFormatter rawMetricFormatter;
  final int standardSeconds;
  final double masteryScore;
  final double struggleScore;
  final int minimumDifficulty;
  final int maximumDifficulty;
  final Set<GameMode> supportedModes;

  int clampDifficulty(int value) =>
      value.clamp(minimumDifficulty, maximumDifficulty);

  TutorialDefinition get tutorial => gameContent[type]!.tutorial;
}

GameDefinition gameDefinition(GameType type) =>
    _definitions[type] ??
    GameDefinition(
      type: type,
      scorer: _scoreArchived,
      rawMetricFormatter: _formatGeneric,
      supportedModes: const {},
    );

const _definitions = <GameType, GameDefinition>{
  GameType.colorClash: GameDefinition(
    type: GameType.colorClash,
    scorer: _scoreColorClash,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.mathBlitz: GameDefinition(
    type: GameType.mathBlitz,
    scorer: _scoreMathBlitz,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.memoryTiles: GameDefinition(
    type: GameType.memoryTiles,
    scorer: _scoreMemoryTiles,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.signalStop: GameDefinition(
    type: GameType.signalStop,
    scorer: _scoreSignalStop,
    rawMetricFormatter: _formatSignalStop,
    standardSeconds: 0,
  ),
  GameType.peripheralFocus: GameDefinition(
    type: GameType.peripheralFocus,
    scorer: _scorePeripheralFocus,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.nBackNavigator: GameDefinition(
    type: GameType.nBackNavigator,
    scorer: _scoreNBack,
    rawMetricFormatter: _formatSpan,
  ),
  GameType.ruleSwitch: GameDefinition(
    type: GameType.ruleSwitch,
    scorer: _scoreRuleSwitch,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.arrowGuard: GameDefinition(
    type: GameType.arrowGuard,
    scorer: _scoreArrowGuard,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.pairLink: GameDefinition(
    type: GameType.pairLink,
    scorer: _scorePairLink,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.symbolSprint: GameDefinition(
    type: GameType.symbolSprint,
    scorer: _scoreSymbolSprint,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.objectTracker: GameDefinition(
    type: GameType.objectTracker,
    scorer: _scoreObjectTracker,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.towerPlanner: GameDefinition(
    type: GameType.towerPlanner,
    scorer: _scoreTowerPlanner,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.dualTaskDash: GameDefinition(
    type: GameType.dualTaskDash,
    scorer: _scoreDualTask,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.logicSeries: GameDefinition(
    type: GameType.logicSeries,
    scorer: _scoreLogicSeries,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.spatialRotation: GameDefinition(
    type: GameType.spatialRotation,
    scorer: _scoreSpatialRotation,
    rawMetricFormatter: _formatLatency,
  ),
};

GameScore _scoreColorClash(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .7, fast: 450, slow: 1600);
GameScore _scoreMathBlitz(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .72, fast: 900, slow: 3500);
GameScore _scoreMemoryTiles(GameScoreInput input) => _accuracyAndCapacity(
  input,
  accuracyWeight: .8,
  target: 3 + input.difficulty,
);
GameScore _scoreSignalStop(GameScoreInput input) => _accuracyAndPace(
  input,
  accuracyWeight: .8,
  fast: 250,
  slow: 900,
  penalty: input.falseStarts * 6.0,
);
GameScore _scorePeripheralFocus(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .74, fast: 250, slow: 1400);
GameScore _scoreNBack(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .82, fast: 400, slow: 1800);
GameScore _scoreRuleSwitch(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .76, fast: 500, slow: 2200);
GameScore _scoreArrowGuard(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .74, fast: 350, slow: 1500);
GameScore _scorePairLink(GameScoreInput input) => _accuracyAndCapacity(
  input,
  accuracyWeight: .84,
  target: 2 + input.difficulty,
);
GameScore _scoreSymbolSprint(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .7, fast: 500, slow: 2200);
GameScore _scoreObjectTracker(GameScoreInput input) => _accuracyAndCapacity(
  input,
  accuracyWeight: .86,
  target: 2 + input.difficulty ~/ 2,
);
GameScore _scoreTowerPlanner(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .86, fast: 900, slow: 6000);
GameScore _scoreDualTask(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .84, fast: 600, slow: 2600);
GameScore _scoreLogicSeries(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .8, fast: 1200, slow: 7000);
GameScore _scoreSpatialRotation(GameScoreInput input) =>
    _accuracyAndPace(input, accuracyWeight: .78, fast: 700, slow: 4000);
GameScore _scoreArchived(GameScoreInput input) => _accuracyAndPace(
  input,
  accuracyWeight: .35,
  fast: 180,
  slow: 700,
  penalty: input.falseStarts * 6.0,
);

GameScore _accuracyAndPace(
  GameScoreInput input, {
  required double accuracyWeight,
  required int fast,
  required int slow,
  double penalty = 0,
}) => _components(
  accuracy: input.accuracy,
  secondary: _pace(input.medianResponseMs, fast: fast, slow: slow),
  accuracyWeight: accuracyWeight,
  penalty: penalty,
);

GameScore _accuracyAndCapacity(
  GameScoreInput input, {
  required double accuracyWeight,
  required int target,
}) => _components(
  accuracy: input.accuracy,
  secondary: input.span / max(1, target),
  accuracyWeight: accuracyWeight,
);

GameScore _components({
  required double accuracy,
  required double secondary,
  required double accuracyWeight,
  double penalty = 0,
}) {
  final accuracyContribution = 100 * accuracy.clamp(0, 1) * accuracyWeight;
  final paceContribution = 100 * secondary.clamp(0, 1) * (1 - accuracyWeight);
  return GameScore(
    normalized: (accuracyContribution + paceContribution - penalty)
        .clamp(0, 100)
        .toDouble(),
    accuracyContribution: accuracyContribution,
    paceContribution: paceContribution,
    penalty: penalty,
  );
}

double _pace(int value, {required int fast, required int slow}) {
  if (value <= 0) return 0;
  return ((slow - value) / (slow - fast)).clamp(0, 1).toDouble();
}

String _formatLatency(Map<String, double> metrics) {
  final value = metrics['medianResponseMs']?.round() ?? 0;
  return value > 0 ? AppText.medianMilliseconds(value) : '';
}

String _formatSpan(Map<String, double> metrics) {
  final value = metrics['span']?.round() ?? 0;
  return value > 0 ? ' · ${AppText.span(value)}' : _formatLatency(metrics);
}

String _formatSignalStop(Map<String, double> metrics) {
  final value = metrics['falseStarts']?.round() ?? 0;
  return ' · ${AppText.falseStarts(value)}';
}

String _formatGeneric(Map<String, double> metrics) => _formatLatency(metrics);
