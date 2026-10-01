import 'dart:math';

import '../config/app_config.dart';
import '../models/brain_models.dart';
import 'game_catalog.dart';

enum BaselineState { building, complete }

class BaselineStatus {
  const BaselineStatus({required this.games});

  final Map<GameType, GameBaselineStatus> games;

  int get completedRounds =>
      games.values.fold(0, (sum, item) => sum + item.completed);
  int get requiredRounds =>
      activeGames.length * AppSettings.baselineSessionCount;
  int get completed => completedRounds;
  int get required => requiredRounds;
  int get remaining => max(0, requiredRounds - completedRounds);
  int get readyGames => games.values.where((item) => item.isComplete).length;
  bool get isComplete => readyGames == activeGames.length;
  BaselineState get state =>
      isComplete ? BaselineState.complete : BaselineState.building;

  GameBaselineStatus forGame(GameType type) =>
      games[type] ?? const GameBaselineStatus(completed: 0);
}

class GameBaselineStatus {
  const GameBaselineStatus({required this.completed});

  final int completed;
  int get required => AppSettings.baselineSessionCount;
  int get remaining => max(0, required - completed);
  bool get isComplete => completed >= required;
}

enum TrendDirection { insufficient, stable, improving, needsAttention }

class SkillTrend {
  const SkillTrend({
    required this.type,
    required this.direction,
    required this.currentLevel,
    required this.baselineLevel,
    required this.delta,
    required this.samples,
  });

  final GameType type;
  final TrendDirection direction;
  final double currentLevel;
  final double baselineLevel;
  final double delta;
  final int samples;
}

class WeeklyReview {
  const WeeklyReview({
    required this.workouts,
    required this.trends,
    required this.recommendations,
  });

  final int workouts;
  final Map<GameType, SkillTrend> trends;
  final List<ReviewRecommendation> recommendations;
}

class ReviewRecommendation {
  const ReviewRecommendation({required this.game, required this.reason});

  final GameType game;
  final String reason;
}

class SessionComparison {
  const SessionComparison({
    this.baselineDelta,
    this.previousDelta,
    this.previousCompletedAt,
  });

  final double? baselineDelta;
  final double? previousDelta;
  final DateTime? previousCompletedAt;
}

class ProgressPoint {
  const ProgressPoint({
    required this.result,
    required this.value,
    required this.includedInTrend,
  });

  final GameResult result;
  final double value;
  final bool includedInTrend;
}

List<ProgressPoint> progressPoints({
  required GameType game,
  required GameMetricDefinition metric,
  required Iterable<GameResult> history,
  GameResult? currentOverlay,
  int limit = AppSettings.maximumChartResults,
}) {
  final comparable =
      history
          .where(
            (result) =>
                result.type == game &&
                result.rulesVersion == game.rulesVersion &&
                result.contributesToTrends &&
                result.completedAt != null &&
                metric.value(result) != null,
          )
          .toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  final visible = comparable.length > limit
      ? comparable.sublist(comparable.length - limit)
      : comparable;
  final points = [
    for (final result in visible)
      ProgressPoint(
        result: result,
        value: metric.value(result)!,
        includedInTrend: true,
      ),
  ];
  if (currentOverlay != null &&
      currentOverlay.type == game &&
      metric.value(currentOverlay) != null) {
    points.add(
      ProgressPoint(
        result: currentOverlay,
        value: metric.value(currentOverlay)!,
        includedInTrend: false,
      ),
    );
  }
  return points;
}

String selfComparisonMessage(
  SessionComparison comparison, {
  required DateTime currentAt,
}) {
  final change = comparison.previousDelta;
  if (change == null) return AppText.analytics.startingPoint;
  final previousAt = comparison.previousCompletedAt;
  final currentDay = DateTime(currentAt.year, currentAt.month, currentAt.day);
  final previousDay = previousAt == null
      ? null
      : DateTime(previousAt.year, previousAt.month, previousAt.day);
  final yesterday =
      previousDay != null && currentDay.difference(previousDay).inDays == 1;
  final reference = yesterday
      ? AppText.analytics.yesterday
      : AppText.analytics.lastRun;
  if (change.abs() <= .05) return AppText.matched(reference);
  if (change > 0) {
    return AppText.betterThan(reference, change.toStringAsFixed(1));
  }
  return AppText.below(reference, change.abs().toStringAsFixed(1));
}

BaselineStatus baselineStatus(Iterable<Object> source) {
  final results = source.expand<GameResult>((item) sync* {
    if (item is GameResult) yield item;
    if (item is DailySummary) yield* item.results;
  }).toList();
  return BaselineStatus(
    games: {
      for (final game in activeGames)
        game: GameBaselineStatus(
          completed: min(
            AppSettings.baselineSessionCount,
            results
                .where(
                  (result) =>
                      result.type == game &&
                      result.mode == GameMode.official &&
                      result.rulesVersion == game.rulesVersion &&
                      !result.isLegacy,
                )
                .length,
          ),
        ),
    },
  );
}

/// Picks five distinct active games while favoring games with the least
/// current-rules daily practice. Supplying [random] makes the result
/// deterministic in tests.
List<GameType> coverageAwareDailySelection(
  Iterable<GameResult> history, {
  Random? random,
}) {
  final generator = random ?? Random();
  final counts = {
    for (final game in activeGames)
      game: history.where((result) {
        return result.type == game &&
            result.mode == GameMode.official &&
            result.rulesVersion == game.rulesVersion &&
            !result.isLegacy;
      }).length,
  };
  final shuffled = [...activeGames]..shuffle(generator);
  shuffled.sort((a, b) => counts[a]!.compareTo(counts[b]!));
  return List.unmodifiable(shuffled.take(AppSettings.workoutGameCount));
}

int adaptDifficulty(
  int current,
  Iterable<double> recentScores, {
  double masteryScore = 85,
  double struggleScore = 60,
}) {
  final scores = recentScores.take(AppSettings.trendWindowSize).toList();
  if (scores.length < AppSettings.trendWindowSize) {
    return current.clamp(
      AppSettings.minimumDifficulty,
      AppSettings.maximumDifficulty,
    );
  }
  final mastered = scores.where((score) => score >= masteryScore).length;
  final struggling = scores.where((score) => score < struggleScore).length;
  if (mastered >= 2) return min(AppSettings.maximumDifficulty, current + 1);
  if (struggling >= 2) return max(AppSettings.minimumDifficulty, current - 1);
  return current.clamp(
    AppSettings.minimumDifficulty,
    AppSettings.maximumDifficulty,
  );
}

SessionComparison sessionComparison({
  required GameResult result,
  required List<GameResult> history,
  required List<DailySummary> daily,
}) {
  double level(GameResult item) =>
      trainingLevel(difficulty: item.difficulty, score: item.normalized);

  final compatibleBaseline =
      history
          .where(
            (item) =>
                item.type == result.type &&
                item.rulesVersion == result.rulesVersion &&
                item.mode == GameMode.official &&
                !item.isLegacy &&
                item.completedAt != null,
          )
          .toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  final previous =
      history
          .where(
            (item) =>
                item.type == result.type &&
                item.rulesVersion == result.rulesVersion &&
                item.mode != GameMode.relaxed &&
                !item.isLegacy &&
                item.completedAt != null &&
                result.completedAt != null &&
                item.completedAt!.isBefore(result.completedAt!),
          )
          .toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  final current = level(result);
  return SessionComparison(
    baselineDelta: compatibleBaseline.length < AppSettings.baselineSessionCount
        ? null
        : current -
              _medianDouble(
                compatibleBaseline
                    .take(AppSettings.baselineSessionCount)
                    .map(level),
              ),
    previousDelta: previous.isEmpty ? null : current - level(previous.first),
    previousCompletedAt: previous.isEmpty ? null : previous.first.completedAt,
  );
}

SkillTrend skillTrend(GameType type, Iterable<GameResult> history) {
  final eligible = history
      .where((result) => result.type == type && result.contributesToTrends)
      .toList();
  final latestRules = type.rulesVersion;
  final sessions =
      eligible.where((result) => result.rulesVersion == latestRules).toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  if (sessions.isEmpty) {
    return SkillTrend(
      type: type,
      direction: TrendDirection.insufficient,
      currentLevel: 0,
      baselineLevel: 0,
      delta: 0,
      samples: 0,
    );
  }
  final levels = sessions
      .map(
        (result) => trainingLevel(
          difficulty: result.difficulty,
          score: result.normalized,
        ),
      )
      .toList();
  final baseline = _medianDouble(levels.take(AppSettings.trendWindowSize));
  final current = _medianDouble(
    levels.reversed.take(AppSettings.trendWindowSize),
  );
  final delta = current - baseline;
  final direction = sessions.length < AppSettings.minimumTrendSessions
      ? TrendDirection.insufficient
      : delta >= .2
      ? TrendDirection.improving
      : delta <= -.2
      ? TrendDirection.needsAttention
      : TrendDirection.stable;
  return SkillTrend(
    type: type,
    direction: direction,
    currentLevel: current,
    baselineLevel: baseline,
    delta: delta,
    samples: sessions.length,
  );
}

WeeklyReview weeklyReview({
  required List<DailySummary> daily,
  required List<GameResult> history,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(const Duration(days: 6));
  final workouts = daily.where((summary) {
    final date = DateTime.tryParse(summary.date);
    return date != null && !date.isBefore(start);
  }).length;
  final trends = {
    for (final type in activeGames) type: skillTrend(type, history),
  };
  final ranked = [...activeGames]
    ..sort((a, b) {
      final aTrend = trends[a]!;
      final bTrend = trends[b]!;
      final bySamples = aTrend.samples.compareTo(bTrend.samples);
      if (bySamples != 0) return bySamples;
      return aTrend.currentLevel.compareTo(bTrend.currentLevel);
    });
  return WeeklyReview(
    workouts: workouts,
    trends: trends,
    recommendations: ranked
        .take(AppSettings.weeklyRecommendationCount)
        .map(
          (game) => ReviewRecommendation(
            game: game,
            reason: trends[game]!.samples < AppSettings.trendWindowSize
                ? AppText.analytics.buildHistory
                : AppText.analytics.weakerTrend,
          ),
        )
        .toList(),
  );
}

String sessionTip(GameResult result) {
  if (result.accuracy < .75) {
    return AppText.analytics.accuracyTip;
  }
  return switch (result.type) {
    GameType.reflexTap =>
      result.metrics['falseStarts'] != null &&
              result.metrics['falseStarts']! > 0
          ? AppText.analytics.reflexWait
          : AppText.analytics.reflexRelax,
    _ => AppText.sessionTips[result.type.name]!,
  };
}

double _medianDouble(Iterable<double> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return 0;
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

GameScore scoreGameDetails({
  required GameType type,
  required int difficulty,
  required double accuracy,
  required int medianResponseMs,
  int span = 0,
  int falseStarts = 0,
}) {
  return gameDefinition(type).scorer(
    GameScoreInput(
      difficulty: difficulty,
      accuracy: accuracy,
      medianResponseMs: medianResponseMs,
      span: span,
      falseStarts: falseStarts,
    ),
  );
}

double scoreGame({
  required GameType type,
  required int difficulty,
  required double accuracy,
  required int medianResponseMs,
  int span = 0,
  int falseStarts = 0,
}) => scoreGameDetails(
  type: type,
  difficulty: difficulty,
  accuracy: accuracy,
  medianResponseMs: medianResponseMs,
  span: span,
  falseStarts: falseStarts,
).normalized;
