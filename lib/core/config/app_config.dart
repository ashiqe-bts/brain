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
