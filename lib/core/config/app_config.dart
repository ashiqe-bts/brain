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
}

abstract final class AppText {
  static const appName = 'BrainFlex';
  static const appTitle = 'BrainFlex';
  static const notRecorded = 'Not recorded';
  static const enterYourName = 'Enter your name';
  static const invalidDisplayName =
      'Use a single line without control characters';
  static const displayNameTooLong = 'Use 30 characters or fewer';
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
  );
  static const notifications = (
    title: 'Ready for today’s you-vs-you practice?',
    streakBody: 'Keep your routine going and see how today feels.',
    body: 'Five games are ready to compare with your own practice.',
    channelName: 'Daily BrainFlex',
    channelDescription: 'One gentle daily workout reminder',
  );

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
}

class GameContent {
  const GameContent({
    required this.title,
    required this.domain,
    required this.semanticLabel,
  });

  final String title;
  final String domain;
  final String semanticLabel;
}

const gameContent = <String, GameContent>{
  'colorClash': GameContent(
    title: 'Color Clash',
    domain: 'Focus',
    semanticLabel: 'Color palette',
  ),
  'mathBlitz': GameContent(
    title: 'Math Blitz',
    domain: 'Calculation',
    semanticLabel: 'Calculator',
  ),
  'memoryTiles': GameContent(
    title: 'Memory Tiles',
    domain: 'Memory',
    semanticLabel: 'Memory grid',
  ),
  'reflexTap': GameContent(
    title: 'Reflex Tap',
    domain: 'Reaction',
    semanticLabel: 'Reaction bolt',
  ),
  'visualSearch': GameContent(
    title: 'Visual Search',
    domain: 'Visual search',
    semanticLabel: 'Visual search',
  ),
  'signalStop': GameContent(
    title: 'Signal Stop',
    domain: 'Response inhibition',
    semanticLabel: 'Stop signal',
  ),
  'peripheralFocus': GameContent(
    title: 'Peripheral Focus',
    domain: 'Visual processing speed',
    semanticLabel: 'Peripheral focus',
  ),
  'nBackNavigator': GameContent(
    title: 'N-Back Navigator',
    domain: 'Working memory',
    semanticLabel: 'Working memory history',
  ),
  'ruleSwitch': GameContent(
    title: 'Rule Switch',
    domain: 'Cognitive flexibility',
    semanticLabel: 'Switching rules',
  ),
  'arrowGuard': GameContent(
    title: 'Arrow Guard',
    domain: 'Selective attention',
    semanticLabel: 'Conflicting arrows',
  ),
  'pairLink': GameContent(
    title: 'Pair Link',
    domain: 'Associative memory',
    semanticLabel: 'Linked pair',
  ),
  'symbolSprint': GameContent(
    title: 'Symbol Sprint',
    domain: 'Processing speed',
    semanticLabel: 'Symbol key',
  ),
  'objectTracker': GameContent(
    title: 'Object Tracker',
    domain: 'Divided attention',
    semanticLabel: 'Tracking target',
  ),
  'towerPlanner': GameContent(
    title: 'Tower Planner',
    domain: 'Planning',
    semanticLabel: 'Planning tree',
  ),
  'dualTaskDash': GameContent(
    title: 'Dual Task Dash',
    domain: 'Dual-task control',
    semanticLabel: 'Two simultaneous tasks',
  ),
  'logicSeries': GameContent(
    title: 'Logic Series',
    domain: 'Inductive reasoning',
    semanticLabel: 'Logic sequence',
  ),
  'spatialRotation': GameContent(
    title: 'Spatial Rotation',
    domain: 'Spatial reasoning',
    semanticLabel: 'Spatial rotation',
  ),
};
