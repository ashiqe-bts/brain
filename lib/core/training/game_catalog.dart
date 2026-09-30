import 'dart:math';

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
      trainingLevelKey =>
        (((result.difficulty.clamp(1, 10) - 1) +
                        result.normalized.clamp(0, 100) / 100) *
                    10)
                .clamp(0, 100)
                .round() /
            10,
      accuracyKey => result.accuracy * 100,
      _ => result.metrics[key],
    };
    if (raw == null) return null;
    return percent && key != accuracyKey ? raw * 100 : raw;
  }

  String formatValue(GameResult result) {
    final number = value(result);
    if (number == null) return 'Not recorded';
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
  label: 'Training level',
  direction: MetricDirection.higherIsBetter,
  decimals: 1,
);
const _accuracyMetric = GameMetricDefinition(
  key: GameMetricDefinition.accuracyKey,
  label: 'Accuracy',
  direction: MetricDirection.higherIsBetter,
  percent: true,
);
const _responseMetric = GameMetricDefinition(
  key: 'medianResponseMs',
  label: 'Median response',
  direction: MetricDirection.lowerIsBetter,
  unit: 'ms',
);

List<GameMetricDefinition> gameMetricDefinitions(GameType type) {
  const interference = GameMetricDefinition(
    key: 'interferenceCostMs',
    label: 'Interference cost',
    direction: MetricDirection.lowerIsBetter,
    unit: 'ms',
  );
  const span = GameMetricDefinition(
    key: 'span',
    label: 'Span',
    direction: MetricDirection.higherIsBetter,
  );
  final specific = switch (type) {
    GameType.colorClash => const [_responseMetric, interference],
    GameType.mathBlitz => const [_responseMetric],
    GameType.memoryTiles => const [
      span,
      GameMetricDefinition(
        key: 'capacity',
        label: 'Capacity',
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'exposureDurationMs',
        label: 'Exposure duration',
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.signalStop => const [
      GameMetricDefinition(
        key: 'stopSuccessRate',
        label: 'Stop success',
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
      GameMetricDefinition(
        key: 'estimatedStoppingMs',
        label: 'Estimated stopping time',
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
      GameMetricDefinition(
        key: 'commissionErrors',
        label: 'Commission errors',
        direction: MetricDirection.lowerIsBetter,
      ),
    ],
    GameType.peripheralFocus => const [
      _responseMetric,
      GameMetricDefinition(
        key: 'exposureThresholdMs',
        label: 'Exposure threshold',
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.nBackNavigator => const [
      span,
      GameMetricDefinition(
        key: 'discrimination',
        label: 'Discrimination',
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
    ],
    GameType.ruleSwitch => const [
      _responseMetric,
      GameMetricDefinition(
        key: 'switchCostMs',
        label: 'Switch cost',
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
        label: 'Correct substitutions',
        direction: MetricDirection.higherIsBetter,
      ),
    ],
    GameType.objectTracker => const [
      GameMetricDefinition(
        key: 'objectCount',
        label: 'Objects tracked',
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'trackingAccuracy',
        label: 'Tracking accuracy',
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
    ],
    GameType.towerPlanner => const [
      GameMetricDefinition(
        key: 'solvedTrials',
        label: 'Solved trials',
        direction: MetricDirection.higherIsBetter,
      ),
      GameMetricDefinition(
        key: 'excessMoves',
        label: 'Excess moves',
        direction: MetricDirection.lowerIsBetter,
      ),
      GameMetricDefinition(
        key: 'planningMedianMs',
        label: 'Planning time',
        direction: MetricDirection.lowerIsBetter,
        unit: 'ms',
      ),
    ],
    GameType.dualTaskDash => const [
      GameMetricDefinition(
        key: 'classificationAccuracy',
        label: 'Classification accuracy',
        direction: MetricDirection.higherIsBetter,
        percent: true,
      ),
      GameMetricDefinition(
        key: 'countAccuracy',
        label: 'Counting accuracy',
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

class TutorialDefinition {
  const TutorialDefinition({required this.intro, required this.steps});

  final String intro;
  final List<TutorialStep> steps;
}

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.instruction,
    required this.stimulus,
    required this.options,
    required this.correctIndex,
    required this.successMessage,
    required this.retryMessage,
    this.waitMilliseconds = 0,
  });

  const TutorialStep.wait({
    required this.title,
    required this.instruction,
    required this.stimulus,
    required this.successMessage,
    required this.retryMessage,
    this.waitMilliseconds = 1400,
  }) : options = const ['TAP'],
       correctIndex = -1;

  final String title;
  final String instruction;
  final String stimulus;
  final List<String> options;
  final int correctIndex;
  final String successMessage;
  final String retryMessage;
  final int waitMilliseconds;

  bool get isWaitStep => waitMilliseconds > 0;
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

  TutorialDefinition get tutorial => tutorialDefinition(type);
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

TutorialDefinition tutorialDefinition(GameType type) => switch (type) {
  GameType.colorClash => const TutorialDefinition(
    intro: 'Choose the ink color and ignore the word itself.',
    steps: [
      TutorialStep(
        title: 'Same word and ink',
        instruction: 'The ink is red. Choose RED.',
        stimulus: 'RED (red ink)',
        options: ['RED', 'BLUE', 'GREEN', 'YELLOW'],
        correctIndex: 0,
        successMessage: 'Correct. The word and ink matched.',
        retryMessage: 'Look at the ink color: it is red.',
      ),
      TutorialStep(
        title: 'Ignore the word',
        instruction: 'The word says RED, but the ink is blue.',
        stimulus: 'RED (blue ink)',
        options: ['RED', 'BLUE', 'GREEN', 'YELLOW'],
        correctIndex: 1,
        successMessage: 'Correct. You chose the blue ink.',
        retryMessage: 'Ignore the letters and choose BLUE.',
      ),
    ],
  ),
  GameType.mathBlitz => const TutorialDefinition(
    intro: 'Decide whether each displayed equation is true or false.',
    steps: [
      TutorialStep(
        title: 'Check a true equation',
        instruction: 'Calculate before choosing.',
        stimulus: '4 + 3 = 7',
        options: ['TRUE', 'FALSE'],
        correctIndex: 0,
        successMessage: 'Correct. Four plus three is seven.',
        retryMessage: 'Add 4 and 3, then compare with 7.',
      ),
      TutorialStep(
        title: 'Catch a close alternative',
        instruction: 'The shown answer may be plausible but wrong.',
        stimulus: '9 − 4 = 6',
        options: ['TRUE', 'FALSE'],
        correctIndex: 1,
        successMessage: 'Correct. Nine minus four is five.',
        retryMessage: 'Work it out: 9 − 4 equals 5, not 6.',
      ),
    ],
  ),
  GameType.memoryTiles => const TutorialDefinition(
    intro: 'Study the marked tiles, then identify the one that changed.',
    steps: [
      TutorialStep(
        title: 'Find the changed tile',
        instruction: 'Tiles 1 and 5 were marked. Now 1 and 6 are marked.',
        stimulus: 'Before: 1, 5   →   After: 1, 6',
        options: ['Tile 1', 'Tile 5', 'Tile 3', 'Tile 8'],
        correctIndex: 1,
        successMessage: 'Correct. Tile 5 changed.',
        retryMessage: 'Compare the two sets: tile 5 disappeared.',
      ),
    ],
  ),
  GameType.signalStop => const TutorialDefinition(
    intro: 'Respond quickly to GO, but withhold your response for STOP.',
    steps: [
      TutorialStep(
        title: 'Respond to GO',
        instruction: 'Tap when GO appears.',
        stimulus: 'GO',
        options: ['TAP', 'WAIT'],
        correctIndex: 0,
        successMessage: 'Good. Respond quickly on GO.',
        retryMessage: 'GO means tap.',
      ),
      TutorialStep.wait(
        title: 'Withhold on STOP',
        instruction: 'Do not press TAP. Wait for the timer to finish.',
        stimulus: 'STOP',
        successMessage: 'Good stop. You withheld the response.',
        retryMessage: 'STOP means do not tap. Try waiting again.',
      ),
    ],
  ),
  GameType.peripheralFocus => const TutorialDefinition(
    intro: 'Keep attention centered while noticing the edge position.',
    steps: [
      TutorialStep(
        title: 'Combine center and edge',
        instruction: 'The center is a triangle and the marker is on the right.',
        stimulus: '▲   • right edge',
        options: ['▲ · RIGHT', '● · RIGHT', '▲ · LEFT', '■ · TOP'],
        correctIndex: 0,
        successMessage: 'Correct. You combined both details.',
        retryMessage: 'Use the center shape and the edge position together.',
      ),
    ],
  ),
  GameType.nBackNavigator => const TutorialDefinition(
    intro: 'Compare the current position with the position one step earlier.',
    steps: [
      TutorialStep(
        title: 'A 1-back match',
        instruction: 'Previous position: 4. Current position: 4.',
        stimulus: '4 → 4',
        options: ['MATCH', 'NEW'],
        correctIndex: 0,
        successMessage: 'Correct. The position repeated.',
        retryMessage: 'Both positions are 4, so this is a match.',
      ),
      TutorialStep(
        title: 'A 1-back non-match',
        instruction: 'Previous position: 4. Current position: 7.',
        stimulus: '4 → 7',
        options: ['MATCH', 'NEW'],
        correctIndex: 1,
        successMessage: 'Correct. The position is new.',
        retryMessage: 'Seven differs from the previous position four.',
      ),
    ],
  ),
  GameType.ruleSwitch => const TutorialDefinition(
    intro: 'Read the rule cue before classifying each item.',
    steps: [
      TutorialStep(
        title: 'Follow the shape rule',
        instruction: 'RULE: SHAPE',
        stimulus: 'COOL TRIANGLE',
        options: ['CIRCLE', 'TRIANGLE'],
        correctIndex: 1,
        successMessage: 'Correct. The shape is a triangle.',
        retryMessage: 'The rule asks for shape, not color.',
      ),
      TutorialStep(
        title: 'Switch to the color rule',
        instruction: 'RULE: COLOR',
        stimulus: 'WARM TRIANGLE',
        options: ['WARM', 'COOL'],
        correctIndex: 0,
        successMessage: 'Correct. You followed the new rule.',
        retryMessage: 'The rule changed. Answer with the color.',
      ),
    ],
  ),
  GameType.arrowGuard => const TutorialDefinition(
    intro: 'Answer for the center arrow and ignore the surrounding arrows.',
    steps: [
      TutorialStep(
        title: 'Ignore conflicting flankers',
        instruction: 'Only the middle arrow counts.',
        stimulus: '→ → ← → →',
        options: ['LEFT', 'RIGHT'],
        correctIndex: 0,
        successMessage: 'Correct. The center arrow points left.',
        retryMessage: 'Focus only on the arrow in the center.',
      ),
    ],
  ),
  GameType.pairLink => const TutorialDefinition(
    intro: 'Learn symbol partners and retrieve them after a delay.',
    steps: [
      TutorialStep(
        title: 'Immediate recall',
        instruction: 'Study: ★ was paired with ♦.',
        stimulus: '★ + ♦',
        options: ['♥', '♦', '☂', '☼'],
        correctIndex: 1,
        successMessage: 'Correct. The partner was ♦.',
        retryMessage: 'Recall the pair shown above: ★ + ♦.',
      ),
      TutorialStep(
        title: 'Delayed recall',
        instruction: 'Which partner went with ★?',
        stimulus: '★ + ?',
        options: ['♥', '♦', '☂', '☼'],
        correctIndex: 1,
        successMessage: 'Correct. You retained the association.',
        retryMessage: '★ was paired with ♦.',
      ),
    ],
  ),
  GameType.symbolSprint => const TutorialDefinition(
    intro: 'Use the current key instead of memorizing an old mapping.',
    steps: [
      TutorialStep(
        title: 'Read the key',
        instruction: '★=3  ●=1  ▲=4  ■=2',
        stimulus: '★',
        options: ['1', '2', '3', '4'],
        correctIndex: 2,
        successMessage: 'Correct. The key maps ★ to 3.',
        retryMessage: 'Check the key: ★ equals 3.',
      ),
      TutorialStep(
        title: 'The key can change',
        instruction: '★=2  ●=4  ▲=1  ■=3',
        stimulus: '●',
        options: ['1', '2', '3', '4'],
        correctIndex: 3,
        successMessage: 'Correct. This key maps ● to 4.',
        retryMessage: 'Use the new key: ● equals 4.',
      ),
    ],
  ),
  GameType.objectTracker => const TutorialDefinition(
    intro: 'Follow highlighted objects as they move to lettered positions.',
    steps: [
      TutorialStep(
        title: 'Track one object',
        instruction: 'Object 1 moves from the upper left to position D.',
        stimulus: '1  ↝  D',
        options: ['A', 'B', 'D', 'F'],
        correctIndex: 2,
        successMessage: 'Correct. The target finished at D.',
        retryMessage: 'Follow object 1 through the movement to D.',
      ),
    ],
  ),
  GameType.towerPlanner => const TutorialDefinition(
    intro:
        'Move one top disk at a time. A larger disk cannot sit on a smaller disk.',
    steps: [
      TutorialStep(
        title: 'Move 1 of 3',
        instruction: 'Move two disks from peg 1 to peg 3.',
        stimulus: 'Peg 1: [2,1]   Peg 2: []   Peg 3: []',
        options: ['Disk 1: 1 → 2', 'Disk 2: 1 → 3'],
        correctIndex: 0,
        successMessage: 'Legal move. The small disk moves first.',
        retryMessage: 'Disk 2 is under disk 1 and cannot move yet.',
      ),
      TutorialStep(
        title: 'Move 2 of 3',
        instruction: 'Continue the shortest plan.',
        stimulus: 'Peg 1: [2]   Peg 2: [1]   Peg 3: []',
        options: ['Disk 2: 1 → 3', 'Disk 1: 2 → 3'],
        correctIndex: 0,
        successMessage: 'Correct. The large disk reaches the goal peg.',
        retryMessage: 'Keep the goal clear for disk 2 first.',
      ),
      TutorialStep(
        title: 'Move 3 of 3',
        instruction: 'Finish the tower.',
        stimulus: 'Peg 1: []   Peg 2: [1]   Peg 3: [2]',
        options: ['Disk 1: 2 → 3', 'Disk 2: 3 → 2'],
        correctIndex: 0,
        successMessage: 'Solved in the minimum three moves.',
        retryMessage: 'Place disk 1 on top of disk 2 at peg 3.',
      ),
    ],
  ),
  GameType.dualTaskDash => const TutorialDefinition(
    intro: 'Answer the number rule and target count at the same time.',
    steps: [
      TutorialStep(
        title: 'Protect both tasks',
        instruction: 'Classify 8 and count the stars.',
        stimulus: '8   ★ ★ ★',
        options: ['EVEN · 3', 'ODD · 3', 'EVEN · 2', 'ODD · 2'],
        correctIndex: 0,
        successMessage: 'Correct on both streams.',
        retryMessage: 'Eight is even and there are three stars.',
      ),
    ],
  ),
  GameType.logicSeries => const TutorialDefinition(
    intro: 'Find the rule that changes one item into the next.',
    steps: [
      TutorialStep(
        title: 'Continue the series',
        instruction: 'Each number increases by two.',
        stimulus: '2 → 4 → 6 → ?',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
        successMessage: 'Correct. Adding two gives eight.',
        retryMessage: 'Apply the +2 rule once more.',
      ),
    ],
  ),
  GameType.spatialRotation => const TutorialDefinition(
    intro: 'Decide whether rotation alone can make the shapes match.',
    steps: [
      TutorialStep(
        title: 'A rotated match',
        instruction: 'The second shape is the first turned 90 degrees.',
        stimulus: '.■■/■■.     ■./■■/.■',
        options: ['SAME', 'DIFFERENT'],
        correctIndex: 0,
        successMessage: 'Correct. Rotation makes them match.',
        retryMessage: 'Mentally turn the first shape 90 degrees.',
      ),
      TutorialStep(
        title: 'A mirrored mismatch',
        instruction: 'A mirror image cannot be made by rotation alone.',
        stimulus: '.■■/■■.     ■■./.■■',
        options: ['SAME', 'DIFFERENT'],
        correctIndex: 1,
        successMessage: 'Correct. This pair is mirrored.',
        retryMessage: 'Rotation preserves handedness; this shape is mirrored.',
      ),
    ],
  ),
  GameType.reflexTap || GameType.visualSearch => const TutorialDefinition(
    intro: 'This archived game has no active tutorial.',
    steps: [],
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
