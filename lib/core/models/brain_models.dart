import 'dart:convert';
import 'dart:math';

enum BrainTheme { midnight, oled, daydream, highContrast }

enum SkillDomain { focus, calculation, memory, reaction, visualSearch }

enum GameType { colorClash, mathBlitz, memoryTiles, reflexTap, visualSearch }

enum GameMode { standard, relaxed, personalBest, official }

typedef SessionKind = GameMode;
typedef GameRulesVersion = int;

enum GameLifecycle { initial, countdown, running, paused, feedback, completed }

extension GameTypeX on GameType {
  String get title => switch (this) {
    GameType.colorClash => 'Color Clash',
    GameType.mathBlitz => 'Math Blitz',
    GameType.memoryTiles => 'Memory Tiles',
    GameType.reflexTap => 'Reflex Tap',
    GameType.visualSearch => 'Visual Search',
  };
  SkillDomain get skill => switch (this) {
    GameType.colorClash => SkillDomain.focus,
    GameType.mathBlitz => SkillDomain.calculation,
    GameType.memoryTiles => SkillDomain.memory,
    GameType.reflexTap => SkillDomain.reaction,
    GameType.visualSearch => SkillDomain.visualSearch,
  };
  String get domain => switch (this) {
    GameType.colorClash => 'Focus',
    GameType.mathBlitz => 'Calculation',
    GameType.memoryTiles => 'Memory',
    GameType.reflexTap => 'Reaction',
    GameType.visualSearch => 'Visual search',
  };
  String get emoji => switch (this) {
    GameType.colorClash => '🎨',
    GameType.mathBlitz => '➗',
    GameType.memoryTiles => '🧩',
    GameType.reflexTap => '⚡',
    GameType.visualSearch => '🔎',
  };
}

GameType gameTypeFromName(String name) => switch (name) {
  'oddOneOut' => GameType.visualSearch,
  _ => GameType.values.byName(name),
};

GameMode gameModeFromName(String name) => switch (name) {
  'classic' || 'endless' || 'timeAttack' => GameMode.standard,
  'zen' => GameMode.relaxed,
  _ => GameMode.values.byName(name),
};

Map<String, int> migrateDifficulties(Map<String, int>? stored) {
  final values = {
    for (final game in GameType.values) game.name: stored?[game.name] ?? 1,
  };
  if (stored != null && !stored.containsKey(GameType.visualSearch.name)) {
    values[GameType.visualSearch.name] = stored['oddOneOut'] ?? 1;
  }
  return values;
}

class ComparableSeriesKey {
  const ComparableSeriesKey({
    required this.game,
    required this.rulesVersion,
    this.difficulty,
  });

  final GameType game;
  final GameRulesVersion rulesVersion;
  final int? difficulty;

  bool accepts(GameResult result) =>
      result.type == game &&
      result.rulesVersion == rulesVersion &&
      (difficulty == null || result.difficulty == difficulty);
}

sealed class RawGameMetrics {
  const RawGameMetrics();
}

final class FocusMetrics extends RawGameMetrics {
  const FocusMetrics(this.medianCorrectResponseMs);
  final int medianCorrectResponseMs;
}

final class CalculationMetrics extends RawGameMetrics {
  const CalculationMetrics(this.medianCorrectResponseMs);
  final int medianCorrectResponseMs;
}

final class MemoryMetrics extends RawGameMetrics {
  const MemoryMetrics({
    required this.span,
    required this.exposureDurationMs,
    required this.rounds,
  });
  final int span;
  final int exposureDurationMs;
  final int rounds;
}

final class ReactionMetrics extends RawGameMetrics {
  const ReactionMetrics({
    required this.medianLatencyMs,
    required this.falseStarts,
  });
  final int medianLatencyMs;
  final int falseStarts;
}

final class VisualSearchMetrics extends RawGameMetrics {
  const VisualSearchMetrics(this.medianCorrectSearchMs);
  final int medianCorrectSearchMs;
}

class GameResult {
  const GameResult({
    required this.type,
    required this.mode,
    required this.score,
    required this.normalized,
    required this.accuracy,
    required this.durationMs,
    required this.difficulty,
    this.bestCombo = 0,
    this.reactionMs,
    this.correct = 0,
    this.attempts = 0,
    this.checkpoints = const [],
    this.id,
    this.completedAt,
    this.rulesVersion = 1,
    this.metrics = const {},
    this.scoreComponents = const {},
    this.isLegacy = false,
  });
  final GameType type;
  final GameMode mode;
  final int score;
  final double normalized;
  final double accuracy;
  final int durationMs;
  final int difficulty;
  final int bestCombo;
  final int? reactionMs;
  final int correct;
  final int attempts;
  final List<int> checkpoints;
  final String? id;
  final DateTime? completedAt;
  final GameRulesVersion rulesVersion;
  final Map<String, double> metrics;
  final Map<String, double> scoreComponents;
  final bool isLegacy;

  ComparableSeriesKey comparableSeries({bool matchDifficulty = false}) =>
      ComparableSeriesKey(
        game: type,
        rulesVersion: rulesVersion,
        difficulty: matchDifficulty ? difficulty : null,
      );

  RawGameMetrics get rawMetrics => switch (type) {
    GameType.colorClash => FocusMetrics(
      metrics['medianResponseMs']?.round() ?? 0,
    ),
    GameType.mathBlitz => CalculationMetrics(
      metrics['medianResponseMs']?.round() ?? 0,
    ),
    GameType.memoryTiles => MemoryMetrics(
      span: metrics['span']?.round() ?? 0,
      exposureDurationMs: metrics['exposureDurationMs']?.round() ?? 0,
      rounds: metrics['rounds']?.round() ?? 0,
    ),
    GameType.reflexTap => ReactionMetrics(
      medianLatencyMs: metrics['medianResponseMs']?.round() ?? 0,
      falseStarts: metrics['falseStarts']?.round() ?? 0,
    ),
    GameType.visualSearch => VisualSearchMetrics(
      metrics['medianResponseMs']?.round() ?? 0,
    ),
  };

  bool get contributesToTrends =>
      !isLegacy &&
      completedAt != null &&
      (mode == GameMode.standard || mode == GameMode.official);

  GameResult copyWith({
    String? id,
    DateTime? completedAt,
    int? rulesVersion,
    bool? isLegacy,
  }) => GameResult(
    type: type,
    mode: mode,
    score: score,
    normalized: normalized,
    accuracy: accuracy,
    durationMs: durationMs,
    difficulty: difficulty,
    bestCombo: bestCombo,
    reactionMs: reactionMs,
    correct: correct,
    attempts: attempts,
    checkpoints: checkpoints,
    id: id ?? this.id,
    completedAt: completedAt ?? this.completedAt,
    rulesVersion: rulesVersion ?? this.rulesVersion,
    metrics: metrics,
    scoreComponents: scoreComponents,
    isLegacy: isLegacy ?? this.isLegacy,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'mode': mode.name,
    'score': score,
    'normalized': normalized,
    'accuracy': accuracy,
    'durationMs': durationMs,
    'difficulty': difficulty,
    'bestCombo': bestCombo,
    'reactionMs': reactionMs,
    'correct': correct,
    'attempts': attempts,
    'checkpoints': checkpoints,
    'id': id,
    'completedAt': completedAt?.toIso8601String(),
    'rulesVersion': rulesVersion,
    'metrics': metrics,
    'scoreComponents': scoreComponents,
  };
  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
    type: gameTypeFromName(j['type'] as String),
    mode: gameModeFromName(j['mode'] as String),
    score: j['score'] as int,
    normalized: (j['normalized'] as num).toDouble(),
    accuracy: (j['accuracy'] as num).toDouble(),
    durationMs: j['durationMs'] as int,
    difficulty: j['difficulty'] as int,
    bestCombo: j['bestCombo'] as int? ?? 0,
    reactionMs: j['reactionMs'] as int?,
    correct: j['correct'] as int? ?? 0,
    attempts: j['attempts'] as int? ?? 0,
    checkpoints: List<int>.from(j['checkpoints'] as List? ?? const []),
    id: j['id'] as String?,
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.tryParse(j['completedAt'] as String),
    rulesVersion: j['rulesVersion'] as int? ?? 0,
    metrics: (j['metrics'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
    scoreComponents: (j['scoreComponents'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
    isLegacy: j['completedAt'] == null || j['rulesVersion'] == null,
  );
}

class DailySummary {
  const DailySummary({
    required this.date,
    this.brainScore = 0,
    this.focus = 0,
    this.memory = 0,
    this.speed = 0,
    this.math = 0,
    this.accuracy = 0,
    this.reactionMs,
    required this.results,
    this.skillRatings = const {},
  });
  final String date;
  final int brainScore, focus, memory, speed, math, accuracy;
  final int? reactionMs;
  final List<GameResult> results;
  final Map<SkillDomain, double> skillRatings;
  Map<String, dynamic> toJson() => {
    'date': date,
    'brainScore': brainScore,
    'focus': focus,
    'memory': memory,
    'speed': speed,
    'math': math,
    'accuracy': accuracy,
    'reactionMs': reactionMs,
    'results': results.map((e) => e.toJson()).toList(),
    'skillRatings': skillRatings.map((key, value) => MapEntry(key.name, value)),
  };
  factory DailySummary.fromJson(Map<String, dynamic> j) => DailySummary(
    date: j['date'] as String,
    brainScore: j['brainScore'] as int? ?? 0,
    focus: j['focus'] as int? ?? 0,
    memory: j['memory'] as int? ?? 0,
    speed: j['speed'] as int? ?? 0,
    math: j['math'] as int? ?? 0,
    accuracy: j['accuracy'] as int? ?? 0,
    reactionMs: j['reactionMs'] as int?,
    results: (j['results'] as List? ?? const [])
        .map((e) => GameResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    skillRatings: (j['skillRatings'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        SkillDomain.values.byName(key as String),
        (value as num).toDouble(),
      ),
    ),
  );
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.claimed = false,
  });
  final String id, title;
  final int target, reward, progress;
  final bool claimed;
  bool get complete => progress >= target;
  Mission copyWith({int? progress, bool? claimed, String? title}) => Mission(
    id: id,
    title: title ?? this.title,
    target: target,
    reward: reward,
    progress: progress ?? this.progress,
    claimed: claimed ?? this.claimed,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'reward': reward,
    'progress': progress,
    'claimed': claimed,
  };
  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
    id: j['id'] as String,
    title: j['title'] as String,
    target: j['target'] as int,
    reward: j['reward'] as int,
    progress: j['progress'] as int? ?? 0,
    claimed: j['claimed'] as bool? ?? false,
  );
}

class WorkoutDraft {
  const WorkoutDraft({
    required this.date,
    required this.order,
    this.results = const [],
  });
  final String date;
  final List<GameType> order;
  final List<GameResult> results;
  Map<String, dynamic> toJson() => {
    'date': date,
    'order': order.map((e) => e.name).toList(),
    'results': results.map((e) => e.toJson()).toList(),
  };
  factory WorkoutDraft.fromJson(Map<String, dynamic> j) => WorkoutDraft(
    date: j['date'] as String,
    order: (j['order'] as List)
        .map((e) => gameTypeFromName(e as String))
        .toList(),
    results: (j['results'] as List)
        .map((e) => GameResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class BrainState {
  BrainState({
    this.onboarded = false,
    this.theme = BrainTheme.midnight,
    this.sound = true,
    this.music = true,
    this.haptics = true,
    this.reducedMotion = false,
    this.streakWarning = true,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.reminderEnabled = false,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.workouts = 0,
    Map<String, int>? difficulties,
    List<DailySummary>? daily,
    List<GameResult>? history,
    List<Mission>? missions,
    Set<String>? achievements,
    this.draft,
    this.lastMissionDate,
  }) : difficulties = migrateDifficulties(difficulties),
       daily = daily ?? [],
       history = history ?? [],
       missions = missions ?? [],
       achievements = achievements ?? {};
  bool onboarded,
      sound,
      music,
      haptics,
      reducedMotion,
      streakWarning,
      reminderEnabled;
  BrainTheme theme;
  int reminderHour,
      reminderMinute,
      xp,
      level,
      currentStreak,
      longestStreak,
      workouts;
  String? lastCompletedDate, lastMissionDate;
  Map<String, int> difficulties;
  List<DailySummary> daily;
  List<GameResult> history;
  List<Mission> missions;
  Set<String> achievements;
  WorkoutDraft? draft;

  int get xpNeeded => 300 + 50 * (level - 1);
  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'theme': theme.name,
    'sound': sound,
    'music': music,
    'haptics': haptics,
    'reducedMotion': reducedMotion,
    'streakWarning': streakWarning,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'reminderEnabled': reminderEnabled,
    'xp': xp,
    'level': level,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastCompletedDate': lastCompletedDate,
    'workouts': workouts,
    'difficulties': difficulties,
    'daily': daily.map((e) => e.toJson()).toList(),
    // Timestamped sessions live in Drift. Only snapshot-only legacy records
    // remain here so old personal bests survive without unbounded duplication.
    'history': history.where((e) => e.isLegacy).map((e) => e.toJson()).toList(),
    'missions': missions.map((e) => e.toJson()).toList(),
    'achievements': achievements.toList(),
    'draft': draft?.toJson(),
    'lastMissionDate': lastMissionDate,
  };
  String encode() => jsonEncode(toJson());
  factory BrainState.decode(String value) {
    final j = Map<String, dynamic>.from(jsonDecode(value) as Map);
    return BrainState(
      onboarded: j['onboarded'] as bool? ?? false,
      theme: BrainTheme.values.byName(j['theme'] as String? ?? 'midnight'),
      sound: j['sound'] as bool? ?? true,
      music: j['music'] as bool? ?? true,
      haptics: j['haptics'] as bool? ?? true,
      reducedMotion: j['reducedMotion'] as bool? ?? false,
      streakWarning: j['streakWarning'] as bool? ?? true,
      reminderHour: j['reminderHour'] as int? ?? 19,
      reminderMinute: j['reminderMinute'] as int? ?? 0,
      reminderEnabled: j['reminderEnabled'] as bool? ?? false,
      xp: j['xp'] as int? ?? 0,
      level: j['level'] as int? ?? 1,
      currentStreak: j['currentStreak'] as int? ?? 0,
      longestStreak: j['longestStreak'] as int? ?? 0,
      lastCompletedDate: j['lastCompletedDate'] as String?,
      workouts: j['workouts'] as int? ?? 0,
      difficulties: Map<String, int>.from(j['difficulties'] as Map? ?? {}),
      daily: (j['daily'] as List? ?? [])
          .map(
            (e) => DailySummary.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      history: (j['history'] as List? ?? [])
          .map((e) => GameResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      missions: (j['missions'] as List? ?? [])
          .map((e) => Mission.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      achievements: Set<String>.from(j['achievements'] as List? ?? []),
      draft: j['draft'] == null
          ? null
          : WorkoutDraft.fromJson(Map<String, dynamic>.from(j['draft'] as Map)),
      lastMissionDate: j['lastMissionDate'] as String?,
    );
  }
}

String localDate([DateTime? value]) {
  final d = value ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

int stableSeed(String input) {
  var hash = 0x811c9dc5;
  for (final b in utf8.encode(input)) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

List<GameType> dailyOrder(String date) {
  final list = [...GameType.values];
  list.shuffle(Random(stableSeed('$date|2|brainflex-training')));
  return list;
}
