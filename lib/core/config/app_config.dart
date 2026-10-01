enum GameType {
  colorClash,
  mathBlitz,
  memoryTiles,
  reflexTap,
  visualSearch,
  signalStop,
  peripheralFocus,
  nBackNavigator,
  ruleSwitch,
  arrowGuard,
  pairLink,
  symbolSprint,
  objectTracker,
  towerPlanner,
  dualTaskDash,
  logicSeries,
  spatialRotation,
}

const activeGames = <GameType>[
  GameType.colorClash,
  GameType.mathBlitz,
  GameType.memoryTiles,
  GameType.signalStop,
  GameType.peripheralFocus,
  GameType.nBackNavigator,
  GameType.ruleSwitch,
  GameType.arrowGuard,
  GameType.pairLink,
  GameType.symbolSprint,
  GameType.objectTracker,
  GameType.towerPlanner,
  GameType.dualTaskDash,
  GameType.logicSeries,
  GameType.spatialRotation,
];

const archivedGames = <GameType>{GameType.reflexTap, GameType.visualSearch};

enum GameMode { standard, relaxed, personalBest, official }

extension GameModePresentation on GameMode {
  String get displayTitle => AppText.gameModeLabels[name]!;
}

extension GameContentPresentation on GameType {
  String get title => gameContent[this]!.title;
  String get domain => gameContent[this]!.domain;
}

abstract final class AppSettings {
  static const workoutGameCount = 5;
  static const baselineSessionCount = 3;
  static const trendWindowSize = 3;
  static const minimumTrendSessions = 6;
  static const maximumDisplayNameCharacters = 30;
  static const maximumOverviewGames = 5;
  static const maximumChartResults = 30;
  static const maximumRecentSessions = 20;
  static const minimumDifficulty = 1;
  static const maximumDifficulty = 10;
  static const defaultReminderHour = 19;
  static const defaultReminderMinute = 0;
  static const gameCountdownSeconds = 3;
  static const defaultTimedSessionSeconds = 30;
  static const tutorialHelperDelay = Duration(milliseconds: 2500);
  static const compactNavigationBreakpoint = 900.0;
  static const extendedNavigationBreakpoint = 1180.0;
  static const onboardingWideBreakpoint = 820.0;
  static const setupCardBreakpoint = 700.0;
  static const gameGridBreakpoint = 680.0;
  static const standardContentWidth = 820.0;
  static const narrowContentWidth = 620.0;
  static const resultContentWidth = 760.0;
  static const onboardingContentWidth = 1080.0;
  static const profileCardWidth = 520.0;
  static const trainContentWidth = 920.0;
  static const weeklyRecommendationCount = 2;
  static const dailyCorrectTarget = 15;
  static const workoutMissionReward = 40;
  static const correctMissionReward = 30;
  static const improvementMissionReward = 50;
}

abstract final class AppText {
  static const appName = 'BrainFlex';
  static const appTitle = 'BrainFlex';
  static const notRecorded = 'Not recorded';
  static const backToTrain = 'Back to Train';
  static const startPlaying = 'Start playing';
  static const returnToTrain = 'RETURN TO TRAIN';
  static const enterDisplayName = 'Enter a display name';
  static const saving = 'Saving';
  static const enterYourName = 'Enter your name';
  static const invalidDisplayName =
      'Use a single line without control characters';
  static const metricTrainingLevel = 'Training level';
  static const metricAccuracy = 'Accuracy';
  static const metricMedianResponse = 'Median response';
  static const metricInterferenceCost = 'Interference cost';
  static const metricSpan = 'Span';
  static const metricCapacity = 'Capacity';
  static const metricExposureDuration = 'Exposure duration';
  static const metricStopSuccess = 'Stop success';
  static const metricEstimatedStoppingTime = 'Estimated stopping time';
  static const metricCommissionErrors = 'Commission errors';
  static const metricExposureThreshold = 'Exposure threshold';
  static const metricDiscrimination = 'Discrimination';
  static const metricSwitchCost = 'Switch cost';
  static const metricCorrectSubstitutions = 'Correct substitutions';
  static const metricObjectsTracked = 'Objects tracked';
  static const metricTrackingAccuracy = 'Tracking accuracy';
  static const metricSolvedTrials = 'Solved trials';
  static const metricExcessMoves = 'Excess moves';
  static const metricPlanningTime = 'Planning time';
  static const metricClassificationAccuracy = 'Classification accuracy';
  static const metricCountingAccuracy = 'Counting accuracy';
  static const navigation = (
    today: 'Today',
    train: 'Train',
    insights: 'Insights',
    settings: 'Settings',
  );
  static const onboarding = (
    setup: 'Set up BrainFlex',
    eyebrow: 'Research-informed daily practice',
    welcomeTitle: 'A calmer way to challenge your focus.',
    welcomeBody:
        'Five short games a day. Clear progress against your own previous practice. No rankings and no pressure.',
    getStarted: 'Get started',
    routinePromise: 'A focused five-minute routine',
    progressPromise: 'Progress measured only against you',
    privacyPromise: 'Private by design',
    disclaimer:
        'BrainFlex trains performance on its activities. It does not measure IQ or provide medical assessment.',
    tagline: 'You versus yesterday',
    profileEyebrow: 'Your profile',
    profileTitle: 'What should we call you?',
    profileBody:
        'Your display name stays on this device and can be changed later.',
    returningProfileBody:
        'Your progress is still here. This name stays only on this device.',
    routineEyebrow: 'Your routine',
    routineTitle: 'Practice on your schedule',
    routineBody:
        'A single optional reminder can help you return. Your results remain on this device.',
    remindersUnavailable: 'Reminders unavailable in Chrome',
    remindersAndroidOnly: 'Daily reminders are supported on Android only.',
    dailyReminder: 'Daily reminder',
    reminderStoredLocally: 'Scheduled only on this Android device',
    reminderTime: 'Reminder time',
    back: 'Back',
    continueLabel: 'Continue',
    startTraining: 'Start training',
  );
  static const home = (
    practiceComplete: 'Practice complete',
    recommendedPractice: 'Recommended practice',
    recommendationReason: 'Based on your least-trained recent skills',
    openTrain: 'Open Train to start a Standard session.',
    goals: "Today's goals",
    thisWeek: 'This week',
    dayStreak: 'day streak',
    workouts: 'workouts',
    baselines: 'baselines',
    today: 'TODAY',
    complete: 'COMPLETE',
    dailyResetComplete: 'Daily reset complete',
    resumeTitle: 'Pick up where you left off',
    readyTitle: 'Ready for your daily reset?',
    completeBody: 'Nice work. Come back tomorrow for a fresh mix.',
    savedSelection: 'Your selection is saved until the workout is complete.',
    duration: '5 games • about 5 minutes',
    startWorkout: "Start today's workout",
    continueWorkout: 'Continue workout',
    personalBaselineReady: 'Personal baseline ready',
    buildingBaseline: 'Building your personal baseline',
    baselineReadyBody:
        'Insights compare you with your own compatible sessions.',
    collect: 'Collect',
  );
  static const workout = (
    dailyWorkout: 'Daily workout',
    buildMix: 'Build your daily mix',
    chooseGames: 'Choose 5 games',
    randomFive: 'Random 5',
    reshuffleFive: 'Reshuffle 5',
    start: 'Start workout',
    dailyPractice: 'Daily practice',
    dailyReset: 'Your five-game daily reset',
    resume: 'Resume practice',
    sessionReview: 'Session review',
    completeTitle: 'Daily reset complete',
    done: 'Done for today',
    resultDisclaimer:
        'These results describe performance in practiced BrainFlex tasks, not IQ, a medical assessment, or proof of everyday cognitive change.',
    finish: 'Finish workout',
    compatibleResults: 'Results are compared only with compatible sessions.',
  );
  static const gameplay = (
    pause: 'Pause game',
    paused: 'Paused',
    resume: 'Resume',
    finishRelaxed: 'Finish relaxed session',
    leaveTitle: 'Leave this round?',
    keepPlaying: 'Keep playing',
    stay: 'Stay',
    leave: 'Leave',
    correct: 'Correct',
    tryNext: 'Try the next one',
    classicLeaveBody: 'Your current round progress will be lost.',
    researchLeaveBody: 'This unfinished round will not be saved.',
    findTarget: 'Find the target',
    targetSymbol: 'Target symbol',
    study: 'Study…',
    keepWaiting: 'Keep waiting…',
    tutorialProgress: 'Tutorial progress',
    startPlaying: 'Start playing',
    tutorialUnscored:
        'Tutorial practice is unscored and never changes your progress.',
    stopGuide: 'STOP: do not tap. Keep waiting until the trial completes.',
    trackingGuide: 'Watch the highlighted objects and follow their movement.',
    watchGuide: 'Watch carefully and remember what you see.',
    trueLabel: 'TRUE',
    falseLabel: 'FALSE',
    tap: 'TAP',
  );
  static const notifications = (
    title: 'Ready for today’s you-vs-you practice?',
    streakBody: 'Keep your routine going and see how today feels.',
    body: 'Five games are ready to compare with your own practice.',
    channelName: 'Daily BrainFlex',
    channelDescription: 'One gentle daily workout reminder',
  );
  static const missions = (
    workout: "Complete today's workout",
    improvement: 'Improve on one of your results',
    chooseUniqueGames: 'Choose five unique games',
    chooseActiveGames: 'Choose active games only',
  );
  static const achievements = (
    firstSpark: 'First Spark',
    oneWeekStrong: 'One Week Strong',
    lightningFingers: 'Lightning Fingers',
    memoryMachine: 'Memory Machine',
    mathWizard: 'Math Wizard',
    unstoppable: 'Unstoppable',
    perfectionist: 'Perfectionist',
  );
  static const settings = (
    eyebrow: 'Your preferences stay on this device',
    profile: 'Profile',
    addName: 'Add your name',
    storedLocally: 'Stored only on this device',
    appearance: 'Appearance',
    light: 'Light',
    dark: 'Dark',
    highContrast: 'High contrast',
    reducedMotion: 'Reduced motion',
    reducedMotionBody: 'Use fades instead of large movement',
    feedback: 'Feedback',
    soundEffects: 'Sound effects',
    ambientMusic: 'Ambient music',
    haptics: 'Haptics',
    reminders: 'Reminders',
    streakWording: 'Streak-aware wording',
    streakWordingBody: 'Replaces the normal reminder; it does not add another',
    about: 'About',
    privacy: 'Privacy',
    privacySubtitle: 'Your progress stays on this device',
    medicalTitle: 'Mental exercise, not medicine',
    medicalBody:
        'BrainFlex tracks performance in its trained tasks. It does not measure IQ, diagnose conditions, or make health claims.',
    version: '1.0.0',
    legalese: 'Private, offline cognitive practice.',
    editName: 'Edit your name',
    yourName: 'Your name',
    cancel: 'Cancel',
    save: 'Save',
    privacyTitle: 'Your training data stays yours.',
    privacyStorage:
        'BrainFlex does not require an account. Session history, personal baselines, progress, and settings are stored locally on your device. There is no backend, cloud sync, advertising SDK, product analytics service, or user-generated content.',
    privacySessions:
        'Standard and daily sessions contribute to personal trends. Relaxed practice is kept separate so it cannot distort measured progress.',
    privacyNotifications:
        'Local notification permission is optional. Reminder schedules are managed by your operating system and can be disabled at any time in BrainFlex or system settings.',
    privacyDeletion:
        'Deleting the app clears its local BrainFlex data unless your operating system independently restores an app backup.',
  );
  static const train = (
    chooseGame: 'Choose a practice game',
    intro:
        'You vs you: each game compares only with your own compatible practice. Relaxed sessions never affect trends.',
    filterSemantics: 'Filter games by cognitive domain',
    all: 'All',
    firstResult:
        'Your first standard result will become a personal starting point.',
    tutorial: 'Tutorial',
    researchBasis: 'Research basis',
    standardBody: 'Comparable practice that contributes to skill trends',
    personalBestBody: 'Challenge a result with matching rules and difficulty',
    relaxedBody: 'Untimed practice that does not affect your trends',
    researchDisclaimer:
        'This task is for practice and self-comparison. It is not a medical treatment, diagnosis, or proof of improvement in everyday cognition.',
  );
  static const analytics = (
    startingPoint: 'This is your personal starting point.',
    yesterday: 'yesterday',
    lastRun: 'your last run',
    buildHistory: 'Build more comparable history',
    weakerTrend: 'Prioritize the weaker rolling trend',
    accuracyTip:
        'Prioritize accuracy before speed on the next comparable round.',
    reflexWait:
        'Wait for the full signal; false starts matter more than raw speed.',
    reflexRelax:
        'Keep your finger relaxed and compare results on the same device.',
  );
  static const progress = (
    combined: 'Combined progress',
    profile: 'Fifteen-game profile',
    filterSemantics: 'Filter insights by cognitive domain',
    weeklyReview: 'Weekly review',
    recentSessions: 'Recent sessions',
    activityCalendar: 'Activity calendar',
    achievements: 'Achievements',
    disclaimer:
        'BrainFlex measures practice performance in these tasks. It does not measure IQ, diagnose a condition, or prove changes in everyday cognition.',
    compareScale: 'Compare games on the shared training-level scale',
    selectGames:
        'Select up to five games. Lines are separate—BrainFlex does not average them into an overall score.',
    allBaselines: 'All game baselines complete',
    trendMethod:
        'Trends use comparable, versioned sessions and rolling medians.',
    improving: 'Improving',
    needsAttention: 'Needs attention',
    steady: 'Steady',
    moreNeeded: 'More sessions needed',
    noResult: 'No comparable result yet',
    viewDetails: 'View details',
    recommendationsLocked:
        'Recommendations unlock after all per-game baselines are ready.',
    naturalVariation:
        'A single fast or slow day is normal. BrainFlex waits for repeated comparable results before labeling a trend.',
    emptyHistory: 'Complete a Standard or daily session to start your history.',
    earlierVersion: 'Earlier version',
    previousMonth: 'Previous month',
    nextMonth: 'Next month',
    complete: 'Complete',
    metric: 'Metric',
    insufficientTrend:
        'Complete at least three post-baseline comparable sessions before BrainFlex labels a direction.',
    chartDisclaimer:
        'Charts describe performance in this practiced task and are not a medical or IQ assessment.',
  );
  static const results = (
    backToTrain: 'Back to Train',
    roundComplete: 'Round complete',
    relaxed: 'Relaxed practice · excluded from progress trends',
    current: 'Current result',
    previous: 'Previous',
    unavailable: 'Not available',
    baselineMedian: 'Baseline median',
    progressGraph: 'Progress graph',
    relaxedNote: 'Relaxed, excluded from trend',
    challengeNote: 'Challenge, excluded from trend',
    measuredSkills: 'All measured skills',
    higherBetter: 'Higher is better',
    lowerBetter: 'Lower is better',
    contextMeasure: 'Context measure',
    chartEmpty: 'Complete a comparable session to start this chart.',
  );
  static const achievementDescriptions = <String, String>{
    'First Spark': 'Complete your first workout',
    'One Week Strong': 'Maintain a 7-day streak',
    'Lightning Fingers': 'React in under 250 ms',
    'Memory Machine': 'Perfect five Memory Tiles rounds',
    'Math Wizard': 'Get 25 Calculation answers correct',
    'Unstoppable': 'Reach a 30-day streak',
    'Perfectionist': 'Finish a workout above 95% accuracy',
  };
  static const calendarWeekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const sessionTips = <String, String>{
    'colorClash':
        'Keep naming the ink color silently before choosing an answer.',
    'mathBlitz':
        'Check the operation first, then estimate before calculating exactly.',
    'memoryTiles':
        'Group nearby tiles into small shapes instead of memorizing one by one.',
    'visualSearch':
        'Scan in a consistent path instead of jumping randomly around the grid.',
    'signalStop':
        'Prioritize successful stops; fast go responses only help when control stays accurate.',
    'peripheralFocus':
        'Keep your gaze centered and use peripheral vision instead of chasing the target.',
    'nBackNavigator':
        'Update one position at a time instead of rehearsing the whole sequence.',
    'ruleSwitch':
        'Read the rule cue before the item, especially immediately after a switch.',
    'arrowGuard':
        'Anchor attention on the center arrow and let the surrounding arrows blur.',
    'pairLink':
        'Create a quick mental connection between each pair before recall begins.',
    'symbolSprint':
        'Check the key before answering; accuracy builds speed more reliably than guessing.',
    'objectTracker':
        'Spread attention across the targets instead of following only one object.',
    'towerPlanner': 'Plan the first two moves before touching a disk.',
    'dualTaskDash': 'Use a steady rhythm and protect accuracy on both tasks.',
    'logicSeries':
        'Look for one changing feature at a time before combining rules.',
    'spatialRotation':
        'Choose one distinctive corner and mentally track it through the rotation.',
  };
  static const skillDomainLabels = <String, String>{
    'focus': 'Focus and attention',
    'calculation': 'Calculation',
    'memory': 'Memory',
    'reaction': 'Reaction',
    'visualSearch': 'Visual search',
    'executiveControl': 'Executive control',
    'processingSpeed': 'Processing speed',
    'reasoning': 'Reasoning and planning',
    'spatial': 'Spatial reasoning',
  };

  static const gameModeLabels = <String, String>{
    'standard': 'Standard',
    'relaxed': 'Relaxed',
    'personalBest': 'Challenge My Best',
    'official': 'Daily',
  };

  static String remainingRounds(int value) =>
      '$value more compatible game round${value == 1 ? '' : 's'}';

  static String falseStarts(int value) =>
      '$value false start${value == 1 ? '' : 's'}';

  static String onboardingStep(int page) => '$page of 2';
  static String greeting(String name) => 'Hey, $name';
  static String selectedGames(int count) =>
      '$count / ${AppSettings.workoutGameCount}';
  static String roundProgress(int round, int total) => 'ROUND $round OF $total';
  static String baselineGames(int ready, int total) => '$ready/$total games';
  static String missionProgress(int progress, int target) =>
      '$progress of $target complete';
  static String workoutStatus(String domain, int round, int total) =>
      '$domain · round $round of $total';
  static String continueToGame(int game) => 'Continue to game $game';
  static String gameSelectionSemantics({
    required String title,
    required String domain,
    required int level,
    required int baseline,
  }) =>
      '$title, $domain, level $level, baseline $baseline of ${AppSettings.baselineSessionCount}';
  static String gameSelectionSubtitle({
    required String domain,
    required int level,
    required int baseline,
  }) =>
      '$domain · Level $level · Baseline $baseline/${AppSettings.baselineSessionCount}';
  static String readyGameBaselines(int ready, int total) =>
      '$ready of $total game baselines ready.';
  static String accuracy(int percent) => '$percent% accuracy';
  static String medianReaction(int milliseconds) =>
      '$milliseconds ms median reaction';
  static String span(int value) => 'span $value';
  static String medianResponse(int milliseconds) =>
      '$milliseconds ms median response';
  static String baselinePending() =>
      'Baseline change: available after ${AppSettings.baselineSessionCount} compatible daily results';
  static String baselineChange(String delta) =>
      'Baseline change: $delta levels';
  static String baselineBuilding(int remaining) =>
      '${remainingRounds(remaining)} across the rotation. Each game unlocks its own baseline after ${AppSettings.baselineSessionCount} rounds.';
  static String recommendationSubtitle(String domain, String reason) =>
      '$domain · $reason';
  static String weekDayStatus(String day, bool complete) =>
      '$day, ${complete ? 'complete' : 'not complete'}';
  static String correctMission(String gameTitle) =>
      'Get ${AppSettings.dailyCorrectTarget} correct in $gameTitle';
  static String reminderSchedule(String time) => '$time · at most one per day';
  static String gameLevel(String domain, int level) => '$domain · Level $level';
  static String playGame(String title) => 'Play $title';
  static String tutorialFor(String title) => 'Tutorial for $title';
  static String researchFor(String title) => 'Research basis for $title';
  static String personalLevel(String level, int accuracy) =>
      'Personal level $level · $accuracy% accuracy';
  static String researchTitle(String title) => '$title: research basis';
  static String studiedPopulation(String population) =>
      'Studied population: $population';
  static String importantLimitation(String limitation) =>
      'Important limitation: $limitation';
  static String matched(String reference) => 'Matched $reference.';
  static String betterThan(String reference, String change) =>
      'Better than $reference by $change levels.';
  static String below(String reference, String change) =>
      '$change levels below $reference. One session naturally varies.';
  static String gameInsights(String title) => '$title insights';
  static String comparableSessions(int count) => '$count comparable sessions';
  static String insightSummary(int sessions, int baseline) =>
      '${comparableSessions(sessions)} · Baseline $baseline/${AppSettings.baselineSessionCount}';
  static String trendDelta(String delta) =>
      '$delta levels from your baseline median';
  static String trendExplanation(String delta) =>
      '${trendDelta(delta)}. Rolling medians reduce the effect of one unusually fast or slow day.';
  static String baselineReady(int ready, int total) =>
      '$ready of $total game baselines ready';
  static String baselineRemaining(int remaining) =>
      '${remainingRounds(remaining)} remain. Individual games unlock after ${AppSettings.baselineSessionCount} official results.';
  static String comparableDomain(String domain, int sessions) =>
      '$domain · ${comparableSessions(sessions)}';
  static String trainingResult(String level, int accuracy, String metric) =>
      'Training level $level · $accuracy% accuracy$metric';
  static String chartSemantics(String title, int sessions) =>
      '$title training level history with ${comparableSessions(sessions)}';
  static String level(String level) => 'Level $level';
  static String weeklyWorkouts(int count) =>
      '$count workout${count == 1 ? '' : 's'} in the last 7 days';
  static String nextWeek(String domains) => 'Next week, prioritize $domains.';
  static String sessionSubtitle(String mode, String date) => '$mode · $date';
  static String calendarDay(String date, bool complete) =>
      '$date, ${complete ? 'workout complete' : 'no workout'}';
  static String noChartHistory(String label) =>
      'No ${label.toLowerCase()} history yet';
  static String chartLatest(String series, String value, String date) =>
      '$series, latest $value on $date';
  static String chartInstructions(String label, String summary) =>
      '$label progress chart. $summary. Use left and right arrow keys to inspect points.';
  static String chartPoint(
    String series,
    String date,
    String value,
    String? note,
  ) => '$series · $date · $value${note == null ? '' : ' · $note'}';
  static String chartSeries(int index) => 'Series $index';
  static String medianMilliseconds(int value) => ' · $value ms median';
  static String afterBaselineResults() =>
      'After ${AppSettings.baselineSessionCount} daily results';
  static String gameStimulus(String value) => 'Game stimulus: $value';
  static String colorStimulus(String word, String ink) =>
      'Game stimulus: word $word in $ink ink';
  static String answerOption(int index) => 'Answer option $index';
  static String tileSemantics(int index, bool marked) =>
      'Tile $index${marked ? ', marked' : ''}';
  static String pegSemantics(int index, bool goal) =>
      'Peg $index${goal ? ' · goal' : ''}';
  static String searchItem(int index) => 'Search item $index';
  static String score(int value) => 'Score $value';
  static String combo(int value) => 'Combo $value';
  static String tutorialTitle(String title) => '$title tutorial';
  static String tutorialComplete(String title) => '$title tutorial complete';
  static String tutorialStep(int step, int total) => '$step / $total';
  static String tutorialCreationError(String game) =>
      'Could not create the $game tutorial trial.';
  static String displayNameTooLong() =>
      'Use ${AppSettings.maximumDisplayNameCharacters} characters or fewer';
  static String percentSemantics(String label, int percent) =>
      '$label, $percent percent';
  static String secondsRemaining(int seconds) => '$seconds S';
  static String focusMark() => '$appName focus mark';
}

class GameContent {
  const GameContent({
    required this.type,
    required this.title,
    required this.domain,
    required this.semanticLabel,
  });

  final GameType type;
  final String title;
  final String domain;
  final String semanticLabel;
  String get instructions => _gameInstructions[type]!;
  String get description => _gameDescriptions[type]!;
  ResearchEvidence get evidence => _gameEvidence[type]!;
  TutorialDefinition get tutorial => _gameTutorials[type]!;
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

enum TutorialScenarioKind { primary, exception, continuation }

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.instruction,
    required this.successMessage,
    required this.retryMessage,
    this.scenario = TutorialScenarioKind.primary,
  });

  final String title;
  final String instruction;
  final String successMessage;
  final String retryMessage;
  final TutorialScenarioKind scenario;
}

const gameContent = <GameType, GameContent>{
  GameType.colorClash: GameContent(
    type: GameType.colorClash,
    title: 'Color Clash',
    domain: 'Focus',
    semanticLabel: 'Color palette',
  ),
  GameType.mathBlitz: GameContent(
    type: GameType.mathBlitz,
    title: 'Math Blitz',
    domain: 'Calculation',
    semanticLabel: 'Calculator',
  ),
  GameType.memoryTiles: GameContent(
    type: GameType.memoryTiles,
    title: 'Memory Tiles',
    domain: 'Memory',
    semanticLabel: 'Memory grid',
  ),
  GameType.reflexTap: GameContent(
    type: GameType.reflexTap,
    title: 'Reflex Tap',
    domain: 'Reaction',
    semanticLabel: 'Reaction bolt',
  ),
  GameType.visualSearch: GameContent(
    type: GameType.visualSearch,
    title: 'Visual Search',
    domain: 'Visual search',
    semanticLabel: 'Visual search',
  ),
  GameType.signalStop: GameContent(
    type: GameType.signalStop,
    title: 'Signal Stop',
    domain: 'Response inhibition',
    semanticLabel: 'Stop signal',
  ),
  GameType.peripheralFocus: GameContent(
    type: GameType.peripheralFocus,
    title: 'Peripheral Focus',
    domain: 'Visual processing speed',
    semanticLabel: 'Peripheral focus',
  ),
  GameType.nBackNavigator: GameContent(
    type: GameType.nBackNavigator,
    title: 'N-Back Navigator',
    domain: 'Working memory',
    semanticLabel: 'Working memory history',
  ),
  GameType.ruleSwitch: GameContent(
    type: GameType.ruleSwitch,
    title: 'Rule Switch',
    domain: 'Cognitive flexibility',
    semanticLabel: 'Switching rules',
  ),
  GameType.arrowGuard: GameContent(
    type: GameType.arrowGuard,
    title: 'Arrow Guard',
    domain: 'Selective attention',
    semanticLabel: 'Conflicting arrows',
  ),
  GameType.pairLink: GameContent(
    type: GameType.pairLink,
    title: 'Pair Link',
    domain: 'Associative memory',
    semanticLabel: 'Linked pair',
  ),
  GameType.symbolSprint: GameContent(
    type: GameType.symbolSprint,
    title: 'Symbol Sprint',
    domain: 'Processing speed',
    semanticLabel: 'Symbol key',
  ),
  GameType.objectTracker: GameContent(
    type: GameType.objectTracker,
    title: 'Object Tracker',
    domain: 'Divided attention',
    semanticLabel: 'Tracking target',
  ),
  GameType.towerPlanner: GameContent(
    type: GameType.towerPlanner,
    title: 'Tower Planner',
    domain: 'Planning',
    semanticLabel: 'Planning tree',
  ),
  GameType.dualTaskDash: GameContent(
    type: GameType.dualTaskDash,
    title: 'Dual Task Dash',
    domain: 'Dual-task control',
    semanticLabel: 'Two simultaneous tasks',
  ),
  GameType.logicSeries: GameContent(
    type: GameType.logicSeries,
    title: 'Logic Series',
    domain: 'Inductive reasoning',
    semanticLabel: 'Logic sequence',
  ),
  GameType.spatialRotation: GameContent(
    type: GameType.spatialRotation,
    title: 'Spatial Rotation',
    domain: 'Spatial reasoning',
    semanticLabel: 'Spatial rotation',
  ),
};

const _gameInstructions = <GameType, String>{
  GameType.colorClash: 'Tap the INK color, not the word',
  GameType.mathBlitz: 'Is this equation correct?',
  GameType.memoryTiles: 'Remember the pattern, then find what changed',
  GameType.reflexTap: 'Archived game',
  GameType.visualSearch: 'Archived game',
  GameType.signalStop: 'Tap GO quickly, but do not tap STOP',
  GameType.peripheralFocus:
      'Read the center and locate the matching edge target',
  GameType.nBackNavigator: 'Is this position the same as N steps back?',
  GameType.ruleSwitch: 'Follow the current rule: shape or color',
  GameType.arrowGuard: 'Choose the CENTER arrow direction',
  GameType.pairLink: 'Learn each symbol pair, then choose its partner',
  GameType.symbolSprint: 'Use the key to match each symbol to its number',
  GameType.objectTracker: 'Remember the targets, track them, then choose them',
  GameType.towerPlanner: 'Match the target in as few moves as possible',
  GameType.dualTaskDash: 'Track the count while answering the number rule',
  GameType.logicSeries: 'Choose the item that continues the pattern',
  GameType.spatialRotation: 'Are these the same shape after rotation?',
};

const _gameDescriptions = <GameType, String>{
  GameType.colorClash:
      'Practise resolving interference between a word and its ink.',
  GameType.mathBlitz:
      'Check adaptive arithmetic while balancing speed and accuracy.',
  GameType.memoryTiles:
      'Compare a briefly shown tile pattern with a changed version.',
  GameType.reflexTap: 'This earlier task remains available only in history.',
  GameType.visualSearch: 'This earlier task remains available only in history.',
  GameType.signalStop:
      'Balance fast responses with the ability to withhold them.',
  GameType.peripheralFocus:
      'Process central and peripheral information in one brief view.',
  GameType.nBackNavigator:
      'Continuously update and compare positions in working memory.',
  GameType.ruleSwitch:
      'Switch between classification rules when the cue changes.',
  GameType.arrowGuard: 'Ignore conflicting flankers around the center arrow.',
  GameType.pairLink:
      'Encode and retrieve associations between abstract symbols.',
  GameType.symbolSprint: 'Practise rapid visual-symbol substitution.',
  GameType.objectTracker: 'Distribute attention across several moving targets.',
  GameType.towerPlanner: 'Plan and execute constrained disk moves.',
  GameType.dualTaskDash:
      'Coordinate two simultaneous streams without abandoning either.',
  GameType.logicSeries: 'Infer rules across visual and numeric sequences.',
  GameType.spatialRotation: 'Mentally rotate abstract shapes and compare them.',
};

const _archivedEvidence = ResearchEvidence(
  summary: 'Archived task with no active training recommendation.',
  population: 'Not applicable',
  limitation: 'This task is no longer part of the active catalog.',
  reference: 'PMID: not applicable',
);

const _gameEvidence = <GameType, ResearchEvidence>{
  GameType.reflexTap: _archivedEvidence,
  GameType.visualSearch: _archivedEvidence,
  GameType.colorClash: ResearchEvidence(
    summary:
        'Stroop-like inhibition exercises have been tested in controlled cognitive-training research.',
    population: 'Cognitively healthy older adults',
    limitation:
        'Practice reliably improves the trained task; broad transfer is inconsistent.',
    reference: 'ACTOP trial · PMID 33343503',
  ),
  GameType.mathBlitz: ResearchEvidence(
    summary:
        'Daily reading and arithmetic practice improved targeted cognitive test performance in a randomized study.',
    population: 'Community-dwelling adults aged 70–86',
    limitation:
        'The study used months of structured practice, not a single short round.',
    reference: 'Arithmetic training RCT · PMID 19424870',
  ),
  GameType.memoryTiles: ResearchEvidence(
    summary:
        'Change-detection training has produced gains in trained visual processing and some search measures.',
    population: 'Healthy adults',
    limitation: 'Effects beyond closely related visual tasks were sparse.',
    reference: 'Change-detection training · PMID 35879360',
  ),
  GameType.signalStop: ResearchEvidence(
    summary:
        'Adaptive inhibition training improved trained Go/No-go performance and related neural timing.',
    population: 'Healthy adults',
    limitation: 'Benefits were measured mainly on response-inhibition tasks.',
    reference: 'Inhibitory-control RCT · PMID 31858835',
  ),
  GameType.peripheralFocus: ResearchEvidence(
    summary:
        'Visual speed-of-processing training improved UFOV and several related measures in controlled trials.',
    population: 'Middle-aged and older adults',
    limitation:
        'Evidence is strongest for trained speed-of-processing abilities.',
    reference: 'Visual processing RCT · PMID 23650501',
  ),
  GameType.nBackNavigator: ResearchEvidence(
    summary:
        'N-back training produces medium transfer to untrained N-back tasks.',
    population: 'Healthy adults across 33 randomized trials',
    limitation:
        'Transfer to other working-memory, control, and reasoning tasks is very small.',
    reference: 'N-back meta-analysis · PMID 28116702',
  ),
  GameType.ruleSwitch: ResearchEvidence(
    summary:
        'Task-switching training reduced switching costs in a controlled crossover study.',
    population: 'Children with ADHD receiving stable medication',
    limitation:
        'Results from a clinical child sample do not establish the same transfer for all users.',
    reference: 'Task-switching study · PMID 22291628',
  ),
  GameType.arrowGuard: ResearchEvidence(
    summary:
        'Hybrid flanker/Go-no-go training has shown task-specific behavioral and neural changes.',
    population: 'Healthy adults',
    limitation: 'Interference-control transfer remains mixed across studies.',
    reference: 'Inhibition transfer RCT · PMID 33646327',
  ),
  GameType.pairLink: ResearchEvidence(
    summary:
        'Paired-associate strategy training improved trained name–face recall in a randomized study.',
    population: 'Older psychogeriatric patients',
    limitation:
        'The app uses abstract pairs and cannot claim the same real-world effect.',
    reference: 'Paired-associate RCT · PMID 1763422',
  ),
  GameType.symbolSprint: ResearchEvidence(
    summary:
        'Speed-of-processing interventions improved UFOV and digit-symbol outcomes in the ACTIVE program.',
    population: 'Cognitively normal older adults',
    limitation:
        'Results describe structured multi-session training in older adults.',
    reference: 'ACTIVE analysis · PMID 26644115',
  ),
  GameType.objectTracker: ResearchEvidence(
    summary:
        'Multiple-object tracking practice produces substantial gains on the trained task.',
    population: 'Healthy young adults',
    limitation:
        'A controlled study found little evidence of transfer to real-world multitasking.',
    reference: 'Object-tracking trial · PMID 32116972',
  ),
  GameType.towerPlanner: ResearchEvidence(
    summary:
        'Tower tasks are established planning measures and show learning with standardized practice.',
    population: 'Healthy adults in a clinical trial',
    limitation:
        'Task learning does not establish broad improvement in everyday planning.',
    reference: 'Tower of London trial · PMID 14561454',
  ),
  GameType.dualTaskDash: ResearchEvidence(
    summary:
        'Controlled dual-task interventions have improved trained dual-task and selected cognitive outcomes.',
    population:
        'Primarily older adults, including people with cognitive impairment',
    limitation:
        'Many studies combine cognitive tasks with physical exercise, unlike this app task.',
    reference: 'Dual-task evidence review · PMID 40304821',
  ),
  GameType.logicSeries: ResearchEvidence(
    summary:
        'Reasoning training in ACTIVE maintained targeted reasoning gains over long follow-up.',
    population: 'Independent older adults',
    limitation:
        'This short visual-series task is not identical to the full ACTIVE intervention.',
    reference: 'ACTIVE ten-year trial · PMID 24417410',
  ),
  GameType.spatialRotation: ResearchEvidence(
    summary:
        'Mental-rotation training transferred to untrained spatial tasks and persisted for one month.',
    population: 'Healthy young adult women',
    limitation:
        'No transfer was found to visual or verbal tasks outside spatial cognition.',
    reference: 'Mental-rotation RCT · PMID 25575755',
  ),
};

const _gameTutorials = <GameType, TutorialDefinition>{
  GameType.colorClash: TutorialDefinition(
    intro: 'Choose the ink color and ignore the word itself.',
    steps: [
      TutorialStep(
        title: 'Same word and ink',
        instruction: 'The ink is red. Choose RED.',
        successMessage: 'Correct. The word and ink matched.',
        retryMessage: 'Look at the ink color: it is red.',
      ),
      TutorialStep(
        title: 'Ignore the word',
        instruction: 'The word says RED, but the ink is blue.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. You chose the blue ink.',
        retryMessage: 'Ignore the letters and choose BLUE.',
      ),
    ],
  ),
  GameType.mathBlitz: TutorialDefinition(
    intro: 'Decide whether each displayed equation is true or false.',
    steps: [
      TutorialStep(
        title: 'Check a true equation',
        instruction: 'Calculate before choosing.',
        successMessage: 'Correct. Four plus three is seven.',
        retryMessage: 'Add 4 and 3, then compare with 7.',
      ),
      TutorialStep(
        title: 'Catch a close alternative',
        instruction: 'The shown answer may be plausible but wrong.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. Nine minus four is five.',
        retryMessage: 'Work it out: 9 − 4 equals 5, not 6.',
      ),
    ],
  ),
  GameType.memoryTiles: TutorialDefinition(
    intro: 'Study the marked tiles, then identify the one that changed.',
    steps: [
      TutorialStep(
        title: 'Find the changed tile',
        instruction: 'Study the marked tiles, then find the tile that changed.',
        successMessage: 'Correct. You found the changed tile.',
        retryMessage: 'Compare the first pattern with the pattern shown now.',
      ),
      TutorialStep(
        title: 'Try another pattern',
        instruction: 'Study the marked tiles, then compare the new pattern.',
        successMessage: 'Correct. You found the changed tile.',
        retryMessage: 'Compare the first pattern with the pattern shown now.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.signalStop: TutorialDefinition(
    intro: 'Respond quickly to GO, but withhold your response for STOP.',
    steps: [
      TutorialStep(
        title: 'Respond to GO',
        instruction: 'Tap when GO appears.',
        successMessage: 'Good. Respond quickly on GO.',
        retryMessage: 'GO means tap.',
      ),
      TutorialStep(
        title: 'Withhold on STOP',
        instruction: 'Do not press TAP. Wait for the timer to finish.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Good stop. You withheld the response.',
        retryMessage: 'STOP means do not tap. Try waiting again.',
      ),
    ],
  ),
  GameType.peripheralFocus: TutorialDefinition(
    intro: 'Keep attention centered while noticing the edge position.',
    steps: [
      TutorialStep(
        title: 'Combine center and edge',
        instruction: 'Remember the center symbol and the edge marker together.',
        successMessage: 'Correct. You combined both details.',
        retryMessage: 'Use the center shape and the edge position together.',
      ),
      TutorialStep(
        title: 'Keep your eyes centered',
        instruction: 'Remember both the center symbol and peripheral marker.',
        successMessage: 'Correct. You noticed both details.',
        retryMessage: 'Match the center symbol and edge direction together.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.nBackNavigator: TutorialDefinition(
    intro: 'Compare the current position with the position one step earlier.',
    steps: [
      TutorialStep(
        title: 'Learn the previous position',
        instruction:
            'Choose NEW when the position differs from the one before it.',
        successMessage: 'Correct. You stored the new position.',
        retryMessage:
            'Compare this position with the immediately previous one.',
      ),
      TutorialStep(
        title: 'Update your memory',
        instruction:
            'This is another new position. Remember it for the next trial.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. This position was new.',
        retryMessage: 'Compare it with the position you just saw.',
      ),
      TutorialStep(
        title: 'Spot a 1-back match',
        instruction:
            'Choose MATCH when the current position repeats the previous one.',
        scenario: TutorialScenarioKind.continuation,
        successMessage: 'Correct. The position repeated.',
        retryMessage: 'Recall the position shown immediately before this one.',
      ),
    ],
  ),
  GameType.ruleSwitch: TutorialDefinition(
    intro: 'Read the rule cue before classifying each item.',
    steps: [
      TutorialStep(
        title: 'Follow the shape rule',
        instruction: 'Read RULE: SHAPE, then answer with the displayed shape.',
        successMessage: 'Correct. You followed the shape rule.',
        retryMessage: 'The rule asks for shape, not color.',
      ),
      TutorialStep(
        title: 'Switch to the color rule',
        instruction:
            'When the cue changes to RULE: COLOR, answer with the color.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. You followed the new rule.',
        retryMessage: 'The rule changed. Answer with the color.',
      ),
    ],
  ),
  GameType.arrowGuard: TutorialDefinition(
    intro: 'Answer for the center arrow and ignore the surrounding arrows.',
    steps: [
      TutorialStep(
        title: 'Read the center arrow',
        instruction: 'Only the middle arrow counts.',
        successMessage: 'Correct. You followed the center arrow.',
        retryMessage: 'Focus only on the arrow in the center.',
      ),
      TutorialStep(
        title: 'Handle an opposing crowd',
        instruction:
            'Answer for the center arrow even when its neighbors disagree.',
        successMessage: 'Correct. You ignored the surrounding arrows.',
        retryMessage: 'Read only the direction of the center arrow.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.pairLink: TutorialDefinition(
    intro: 'Learn symbol partners and retrieve them after a delay.',
    steps: [
      TutorialStep(
        title: 'Immediate recall',
        instruction: 'Study the pair, then select the symbol shown with it.',
        successMessage: 'Correct. You recalled the partner.',
        retryMessage:
            'Recall the two symbols shown together during the study phase.',
      ),
      TutorialStep(
        title: 'Learn another pair',
        instruction:
            'Study and recall a second pair before returning to the first.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. Keep both pairs in mind.',
        retryMessage: 'Recall the newest pair shown during the study phase.',
      ),
      TutorialStep(
        title: 'Delayed recall',
        instruction:
            'Retrieve the earlier partner after another pair intervenes.',
        scenario: TutorialScenarioKind.continuation,
        successMessage: 'Correct. You retained the association.',
        retryMessage: 'Think back to the earlier study pair.',
      ),
    ],
  ),
  GameType.symbolSprint: TutorialDefinition(
    intro: 'Use the current key instead of memorizing an old mapping.',
    steps: [
      TutorialStep(
        title: 'Read the key',
        instruction: 'Use the displayed key to translate the target symbol.',
        successMessage: 'Correct. You used the current key.',
        retryMessage: 'Find the target symbol in the key and read its number.',
      ),
      TutorialStep(
        title: 'The key can change',
        instruction:
            'Read the new key instead of relying on the previous mapping.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. You followed the updated key.',
        retryMessage: 'Check this trial’s key again before answering.',
      ),
    ],
  ),
  GameType.objectTracker: TutorialDefinition(
    intro: 'Follow highlighted objects as they move to lettered positions.',
    steps: [
      TutorialStep(
        title: 'Track one object',
        instruction:
            'Watch the highlighted object move to a lettered position.',
        successMessage: 'Correct. You found the target’s final position.',
        retryMessage: 'Follow the highlighted object to its final letter.',
      ),
      TutorialStep(
        title: 'Track a new movement',
        instruction:
            'Follow the highlighted object without following distractors.',
        successMessage: 'Correct. You kept track of the target.',
        retryMessage:
            'Replay the movement in your mind and choose its final letter.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.towerPlanner: TutorialDefinition(
    intro:
        'Move one top disk at a time. A larger disk cannot sit on a smaller disk.',
    steps: [
      TutorialStep(
        title: 'Move 1 of 3',
        instruction: 'Choose the legal move that starts the shortest plan.',
        successMessage: 'Legal move. The small disk moves first.',
        retryMessage:
            'Only a top disk can move. Choose the shortest legal move.',
      ),
      TutorialStep(
        title: 'Move 2 of 3',
        instruction: 'Continue toward the marked goal peg using legal moves.',
        scenario: TutorialScenarioKind.continuation,
        successMessage: 'Correct. The tower is closer to the goal peg.',
        retryMessage: 'Keep the goal clear and choose the shortest legal move.',
      ),
      TutorialStep(
        title: 'Move 3 of 3',
        instruction: 'Choose the move that completes the shortest plan.',
        scenario: TutorialScenarioKind.continuation,
        successMessage: 'Solved in the minimum three moves.',
        retryMessage: 'Finish by placing the remaining disk on the goal tower.',
      ),
    ],
  ),
  GameType.dualTaskDash: TutorialDefinition(
    intro: 'Answer the number rule and target count at the same time.',
    steps: [
      TutorialStep(
        title: 'Protect both tasks',
        instruction:
            'Classify the number and count the stars at the same time.',
        successMessage: 'Correct on both streams.',
        retryMessage: 'Check the number rule and star count separately.',
      ),
      TutorialStep(
        title: 'Balance both answers',
        instruction: 'Classify the new number and count every star.',
        successMessage: 'Correct. Both parts of your answer match.',
        retryMessage: 'Check the number rule and star count separately.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.logicSeries: TutorialDefinition(
    intro: 'Find the rule that changes one item into the next.',
    steps: [
      TutorialStep(
        title: 'Continue the series',
        instruction:
            'Find the repeated change, then continue the number series.',
        successMessage: 'Correct. You continued the rule.',
        retryMessage: 'Compare neighboring values to find the repeated step.',
      ),
      TutorialStep(
        title: 'Find a new step',
        instruction: 'Work out how much each value changes before answering.',
        successMessage: 'Correct. You continued the pattern.',
        retryMessage: 'Compare neighboring values to find the repeated step.',
        scenario: TutorialScenarioKind.exception,
      ),
    ],
  ),
  GameType.spatialRotation: TutorialDefinition(
    intro: 'Decide whether rotation alone can make the shapes match.',
    steps: [
      TutorialStep(
        title: 'A rotated match',
        instruction: 'Decide whether rotation alone can align the two shapes.',
        successMessage: 'Correct. Rotation makes them match.',
        retryMessage: 'Mentally rotate the first shape without reflecting it.',
      ),
      TutorialStep(
        title: 'A mirrored mismatch',
        instruction: 'A mirrored shape cannot be aligned using rotation alone.',
        scenario: TutorialScenarioKind.exception,
        successMessage: 'Correct. This pair is mirrored.',
        retryMessage: 'Rotation preserves handedness; this shape is mirrored.',
      ),
    ],
  ),
  GameType.reflexTap: TutorialDefinition(
    intro: 'This archived game has no active tutorial.',
    steps: [],
  ),
  GameType.visualSearch: TutorialDefinition(
    intro: 'This archived game has no active tutorial.',
    steps: [],
  ),
};
