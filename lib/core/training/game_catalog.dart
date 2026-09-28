import 'dart:math';

import '../models/brain_models.dart';

typedef GameScorer = GameScore Function(GameScoreInput input);
typedef RawMetricFormatter = String Function(Map<String, double> metrics);

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

class ResearchEvidence {
  const ResearchEvidence({
    required this.summary,
    required this.population,
    required this.limitation,
    required this.reference,
  });

  final String summary;
  final String population;
  final String limitation;
  final String reference;
}

class GameDefinition {
  const GameDefinition({
    required this.type,
    required this.instructions,
    required this.description,
    required this.evidence,
    required this.scorer,
    required this.rawMetricFormatter,
    this.standardSeconds = 30,
    this.masteryScore = 85,
    this.struggleScore = 60,
    this.minimumDifficulty = 1,
    this.maximumDifficulty = 10,
    this.supportedModes = const {
      GameMode.standard,
      GameMode.relaxed,
      GameMode.personalBest,
      GameMode.official,
    },
  });

  final GameType type;
  final String instructions;
  final String description;
  final ResearchEvidence evidence;
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
}

GameDefinition gameDefinition(GameType type) =>
    _definitions[type] ??
    GameDefinition(
      type: type,
      instructions: 'Archived game',
      description: 'This earlier task remains available only in history.',
      evidence: const ResearchEvidence(
        summary: 'Archived task with no active training recommendation.',
        population: 'Not applicable',
        limitation: 'This task is no longer part of the active catalog.',
        reference: 'PMID: not applicable',
      ),
      scorer: _scoreArchived,
      rawMetricFormatter: _formatGeneric,
      supportedModes: const {},
    );

const _definitions = <GameType, GameDefinition>{
  GameType.colorClash: GameDefinition(
    type: GameType.colorClash,
    instructions: 'Tap the INK color, not the word',
    description: 'Practise resolving interference between a word and its ink.',
    evidence: ResearchEvidence(
      summary:
          'Stroop-like inhibition exercises have been tested in controlled cognitive-training research.',
      population: 'Cognitively healthy older adults',
      limitation:
          'Practice reliably improves the trained task; broad transfer is inconsistent.',
      reference: 'ACTOP trial · PMID 33343503',
    ),
    scorer: _scoreColorClash,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.mathBlitz: GameDefinition(
    type: GameType.mathBlitz,
    instructions: 'Is this equation correct?',
    description:
        'Check adaptive arithmetic while balancing speed and accuracy.',
    evidence: ResearchEvidence(
      summary:
          'Daily reading and arithmetic practice improved targeted cognitive test performance in a randomized study.',
      population: 'Community-dwelling adults aged 70–86',
      limitation:
          'The study used months of structured practice, not a single short round.',
      reference: 'Arithmetic training RCT · PMID 19424870',
    ),
    scorer: _scoreMathBlitz,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.memoryTiles: GameDefinition(
    type: GameType.memoryTiles,
    instructions: 'Remember the pattern, then find what changed',
    description: 'Compare a briefly shown tile pattern with a changed version.',
    evidence: ResearchEvidence(
      summary:
          'Change-detection training has produced gains in trained visual processing and some search measures.',
      population: 'Healthy adults',
      limitation: 'Effects beyond closely related visual tasks were sparse.',
      reference: 'Change-detection training · PMID 35879360',
    ),
    scorer: _scoreMemoryTiles,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.signalStop: GameDefinition(
    type: GameType.signalStop,
    instructions: 'Tap GO quickly, but do not tap STOP',
    description: 'Balance fast responses with the ability to withhold them.',
    evidence: ResearchEvidence(
      summary:
          'Adaptive inhibition training improved trained Go/No-go performance and related neural timing.',
      population: 'Healthy adults',
      limitation: 'Benefits were measured mainly on response-inhibition tasks.',
      reference: 'Inhibitory-control RCT · PMID 31858835',
    ),
    scorer: _scoreSignalStop,
    rawMetricFormatter: _formatSignalStop,
    standardSeconds: 0,
  ),
  GameType.peripheralFocus: GameDefinition(
    type: GameType.peripheralFocus,
    instructions: 'Read the center and locate the matching edge target',
    description:
        'Process central and peripheral information in one brief view.',
    evidence: ResearchEvidence(
      summary:
          'Visual speed-of-processing training improved UFOV and several related measures in controlled trials.',
      population: 'Middle-aged and older adults',
      limitation:
          'Evidence is strongest for trained speed-of-processing abilities.',
      reference: 'Visual processing RCT · PMID 23650501',
    ),
    scorer: _scorePeripheralFocus,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.nBackNavigator: GameDefinition(
    type: GameType.nBackNavigator,
    instructions: 'Is this position the same as N steps back?',
    description: 'Continuously update and compare positions in working memory.',
    evidence: ResearchEvidence(
      summary:
          'N-back training produces medium transfer to untrained N-back tasks.',
      population: 'Healthy adults across 33 randomized trials',
      limitation:
          'Transfer to other working-memory, control, and reasoning tasks is very small.',
      reference: 'N-back meta-analysis · PMID 28116702',
    ),
    scorer: _scoreNBack,
    rawMetricFormatter: _formatSpan,
  ),
  GameType.ruleSwitch: GameDefinition(
    type: GameType.ruleSwitch,
    instructions: 'Follow the current rule: shape or color',
    description: 'Switch between classification rules when the cue changes.',
    evidence: ResearchEvidence(
      summary:
          'Task-switching training reduced switching costs in a controlled crossover study.',
      population: 'Children with ADHD receiving stable medication',
      limitation:
          'Results from a clinical child sample do not establish the same transfer for all users.',
      reference: 'Task-switching study · PMID 22291628',
    ),
    scorer: _scoreRuleSwitch,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.arrowGuard: GameDefinition(
    type: GameType.arrowGuard,
    instructions: 'Choose the CENTER arrow direction',
    description: 'Ignore conflicting flankers around the center arrow.',
    evidence: ResearchEvidence(
      summary:
          'Hybrid flanker/Go-no-go training has shown task-specific behavioral and neural changes.',
      population: 'Healthy adults',
      limitation: 'Interference-control transfer remains mixed across studies.',
      reference: 'Inhibition transfer RCT · PMID 33646327',
    ),
    scorer: _scoreArrowGuard,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.pairLink: GameDefinition(
    type: GameType.pairLink,
    instructions: 'Learn each symbol pair, then choose its partner',
    description: 'Encode and retrieve associations between abstract symbols.',
    evidence: ResearchEvidence(
      summary:
          'Paired-associate strategy training improved trained name–face recall in a randomized study.',
      population: 'Older psychogeriatric patients',
      limitation:
          'The app uses abstract pairs and cannot claim the same real-world effect.',
      reference: 'Paired-associate RCT · PMID 1763422',
    ),
    scorer: _scorePairLink,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.symbolSprint: GameDefinition(
    type: GameType.symbolSprint,
    instructions: 'Use the key to match each symbol to its number',
    description: 'Practise rapid visual-symbol substitution.',
    evidence: ResearchEvidence(
      summary:
          'Speed-of-processing interventions improved UFOV and digit-symbol outcomes in the ACTIVE program.',
      population: 'Cognitively normal older adults',
      limitation:
          'Results describe structured multi-session training in older adults.',
      reference: 'ACTIVE analysis · PMID 26644115',
    ),
    scorer: _scoreSymbolSprint,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.objectTracker: GameDefinition(
    type: GameType.objectTracker,
    instructions: 'Remember the targets, track them, then choose them',
    description: 'Distribute attention across several moving targets.',
    evidence: ResearchEvidence(
      summary:
          'Multiple-object tracking practice produces substantial gains on the trained task.',
      population: 'Healthy young adults',
      limitation:
          'A controlled study found little evidence of transfer to real-world multitasking.',
      reference: 'Object-tracking trial · PMID 32116972',
    ),
    scorer: _scoreObjectTracker,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.towerPlanner: GameDefinition(
    type: GameType.towerPlanner,
    instructions: 'Match the target in as few moves as possible',
    description: 'Plan and execute constrained disk moves.',
    evidence: ResearchEvidence(
      summary:
          'Tower tasks are established planning measures and show learning with standardized practice.',
      population: 'Healthy adults in a clinical trial',
      limitation:
          'Task learning does not establish broad improvement in everyday planning.',
      reference: 'Tower of London trial · PMID 14561454',
    ),
    scorer: _scoreTowerPlanner,
    rawMetricFormatter: _formatSpan,
    standardSeconds: 0,
  ),
  GameType.dualTaskDash: GameDefinition(
    type: GameType.dualTaskDash,
    instructions: 'Track the count while answering the number rule',
    description:
        'Coordinate two simultaneous streams without abandoning either.',
    evidence: ResearchEvidence(
      summary:
          'Controlled dual-task interventions have improved trained dual-task and selected cognitive outcomes.',
      population:
          'Primarily older adults, including people with cognitive impairment',
      limitation:
          'Many studies combine cognitive tasks with physical exercise, unlike this app task.',
      reference: 'Dual-task evidence review · PMID 40304821',
    ),
    scorer: _scoreDualTask,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.logicSeries: GameDefinition(
    type: GameType.logicSeries,
    instructions: 'Choose the item that continues the pattern',
    description: 'Infer rules across visual and numeric sequences.',
    evidence: ResearchEvidence(
      summary:
          'Reasoning training in ACTIVE maintained targeted reasoning gains over long follow-up.',
      population: 'Independent older adults',
      limitation:
          'This short visual-series task is not identical to the full ACTIVE intervention.',
      reference: 'ACTIVE ten-year trial · PMID 24417410',
    ),
    scorer: _scoreLogicSeries,
    rawMetricFormatter: _formatLatency,
  ),
  GameType.spatialRotation: GameDefinition(
    type: GameType.spatialRotation,
    instructions: 'Are these the same shape after rotation?',
    description: 'Mentally rotate abstract shapes and compare them.',
    evidence: ResearchEvidence(
      summary:
          'Mental-rotation training transferred to untrained spatial tasks and persisted for one month.',
      population: 'Healthy young adult women',
      limitation:
          'No transfer was found to visual or verbal tasks outside spatial cognition.',
      reference: 'Mental-rotation RCT · PMID 25575755',
    ),
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
  return value > 0 ? ' · $value ms median' : '';
}

String _formatSpan(Map<String, double> metrics) {
  final value = metrics['span']?.round() ?? 0;
  return value > 0 ? ' · span $value' : _formatLatency(metrics);
}

String _formatSignalStop(Map<String, double> metrics) {
  final value = metrics['falseStarts']?.round() ?? 0;
  return ' · $value false start${value == 1 ? '' : 's'}';
}

String _formatGeneric(Map<String, double> metrics) => _formatLatency(metrics);
