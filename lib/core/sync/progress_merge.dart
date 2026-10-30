import '../config/app_config.dart';
import '../models/brain_models.dart';
import '../training/game_catalog.dart';
import '../training/training_analytics.dart';

/// Deterministically combines two offline-capable progress snapshots.
///
/// Device-only preferences intentionally come from [local]. Cloud progress is
/// merged without allowing a second device to change reminders or accessibility
/// preferences on this device.
BrainState mergeProgress({
  required BrainState local,
  required BrainState cloud,
}) {
  final historyById = <String, GameResult>{};
  for (final result in [...cloud.history, ...local.history]) {
    final key = result.id ?? _legacyResultKey(result);
    final existing = historyById[key];
    if (existing == null ||
        _completedAt(result).isAfter(_completedAt(existing))) {
      historyById[key] = result;
    }
  }
  final history = historyById.values.toList()
    ..sort((a, b) => _completedAt(a).compareTo(_completedAt(b)));

  final dailyByDate = <String, DailySummary>{};
  for (final summary in [...cloud.daily, ...local.daily]) {
    final existing = dailyByDate[summary.date];
    if (existing == null || summary.results.length > existing.results.length) {
      dailyByDate[summary.date] = summary;
    }
  }
  final daily = dailyByDate.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final streaks = _streaks(daily.map((item) => item.date));
  final difficulties = _recomputeDifficulties(history);
  final displayName = _preferredName(cloud.displayName, local.displayName);
  final explorerProgress = _mergeExplorerProgress(
    local.explorerProgress,
    cloud.explorerProgress,
  );

  return BrainState(
    onboarded: local.onboarded || cloud.onboarded,
    displayName: displayName,
    theme: local.theme,
    sound: local.sound,
    music: local.music,
    haptics: local.haptics,
    reducedMotion: local.reducedMotion,
    streakWarning: local.streakWarning,
    reminderHour: local.reminderHour,
    reminderMinute: local.reminderMinute,
    reminderEnabled: local.reminderEnabled,
    xp: local.xp > cloud.xp ? local.xp : cloud.xp,
    level: local.level > cloud.level ? local.level : cloud.level,
    currentStreak: streaks.$1,
    longestStreak: streaks.$2,
    lastCompletedDate: daily.isEmpty ? null : daily.last.date,
    workouts: daily.length,
    difficulties: difficulties,
    daily: daily,
    history: history,
    missions: _preferredMissions(local, cloud),
    achievements: {...cloud.achievements, ...local.achievements},
    completedTutorials: {
      ...cloud.completedTutorials,
      ...local.completedTutorials,
    },
    explorerProgress: explorerProgress,
    draft: _preferredDraft(local.draft, cloud.draft),
    lastMissionDate: _latestDate(local.lastMissionDate, cloud.lastMissionDate),
  );
}

ExplorerProgress _mergeExplorerProgress(
  ExplorerProgress local,
  ExplorerProgress cloud,
) {
  return ExplorerProgress(
    totalMapStars: local.totalMapStars > cloud.totalMapStars
        ? local.totalMapStars
        : cloud.totalMapStars,
    regionStars: {
      for (final region in ExpeditionRegion.values)
        if ((local.regionStars[region] ?? 0) > 0 ||
            (cloud.regionStars[region] ?? 0) > 0)
          region:
              (local.regionStars[region] ?? 0) >
                  (cloud.regionStars[region] ?? 0)
              ? local.regionStars[region]!
              : cloud.regionStars[region]!,
    },
  );
}

DateTime _completedAt(GameResult result) =>
    result.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

String _legacyResultKey(GameResult result) => [
  result.type.name,
  result.mode.name,
  result.completedAt?.toUtc().toIso8601String() ?? 'legacy',
  result.score,
  result.durationMs,
].join(':');

String? _preferredName(String? cloud, String? local) {
  if (cloud != null && cloud.trim().isNotEmpty) return cloud;
  if (local != null && local.trim().isNotEmpty) return local;
  return null;
}

(int, int) _streaks(Iterable<String> dates) {
  final values = dates.toSet().map(DateTime.parse).toList()..sort();
  if (values.isEmpty) return (0, 0);
  var current = 1;
  var longest = 1;
  for (var index = 1; index < values.length; index++) {
    if (values[index].difference(values[index - 1]).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return (current, longest);
}

Map<String, int> _recomputeDifficulties(List<GameResult> history) {
  final values = {for (final game in GameType.values) game.name: 1};
  for (final game in activeGames) {
    final comparable = history
        .where(
          (item) =>
              item.type == game &&
              item.rulesVersion == game.rulesVersion &&
              item.contributesToTrends,
        )
        .toList();
    var difficulty = comparable.isEmpty ? 1 : comparable.first.difficulty;
    for (var index = 0; index < comparable.length; index++) {
      final sameDifficulty = comparable
          .take(index + 1)
          .where((item) => item.difficulty == difficulty)
          .toList()
          .reversed
          .take(AppSettings.trendWindowSize)
          .map((item) => item.normalized);
      final definition = gameDefinition(game);
      difficulty = adaptDifficulty(
        difficulty,
        sameDifficulty,
        masteryScore: definition.masteryScore,
        struggleScore: definition.struggleScore,
      );
    }
    values[game.name] = difficulty;
  }
  return values;
}

List<Mission> _preferredMissions(BrainState local, BrainState cloud) {
  final newest = _latestDate(local.lastMissionDate, cloud.lastMissionDate);
  if (newest == cloud.lastMissionDate) return List.of(cloud.missions);
  return List.of(local.missions);
}

WorkoutDraft? _preferredDraft(WorkoutDraft? local, WorkoutDraft? cloud) {
  if (local == null) return cloud;
  if (cloud == null) return local;
  if (local.date != cloud.date) {
    return local.date.compareTo(cloud.date) >= 0 ? local : cloud;
  }
  return local.results.length >= cloud.results.length ? local : cloud;
}

String? _latestDate(String? left, String? right) {
  if (left == null) return right;
  if (right == null) return left;
  return left.compareTo(right) >= 0 ? left : right;
}
