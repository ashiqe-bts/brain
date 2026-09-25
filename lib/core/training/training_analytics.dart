import 'dart:math';

import '../models/brain_models.dart';

class BaselineStatus {
  const BaselineStatus({required this.completed, this.required = 3});

  final int completed;
  final int required;

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
  final List<GameType> recommendations;
}

BaselineStatus baselineStatus(List<DailySummary> daily) =>
    BaselineStatus(completed: min(3, daily.length));

double trainingLevel({required int difficulty, required double score}) {
  final safeDifficulty = difficulty.clamp(1, 10);
  final safeScore = score.clamp(0, 100);
  return (((safeDifficulty - 1) + safeScore / 100) * 10).clamp(0, 100).round() /
      10;
}

int adaptDifficulty(int current, Iterable<double> recentScores) {
  final scores = recentScores.take(3).toList();
  if (scores.length < 3) return current.clamp(1, 10);
  final mastered = scores.where((score) => score >= 85).length;
  final struggling = scores.where((score) => score < 60).length;
  if (mastered >= 2) return min(10, current + 1);
  if (struggling >= 2) return max(1, current - 1);
  return current.clamp(1, 10);
}

SkillTrend skillTrend(GameType type, Iterable<GameResult> history) {
  final eligible = history
      .where((result) => result.type == type && result.contributesToTrends)
      .toList();
  final latestRules = eligible.fold<int>(
    0,
    (v, result) => max(v, result.rulesVersion),
  );
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
  final baseline = _medianDouble(levels.take(3));
  final current = _medianDouble(levels.reversed.take(3));
  final delta = current - baseline;
  final direction = sessions.length < 6
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
    for (final type in GameType.values) type: skillTrend(type, history),
  };
  final ranked = [...GameType.values]
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
    recommendations: ranked.take(2).toList(),
  );
}

String sessionTip(GameResult result) {
  if (result.accuracy < .75) {
    return 'Prioritize accuracy before speed on the next comparable round.';
  }
  return switch (result.type) {
    GameType.colorClash =>
      'Keep naming the ink color silently before choosing an answer.',
    GameType.mathBlitz =>
      'Check the operation first, then estimate before calculating exactly.',
    GameType.memoryTiles =>
      'Group nearby tiles into small shapes instead of memorizing one by one.',
    GameType.reflexTap =>
      result.metrics['falseStarts'] != null &&
              result.metrics['falseStarts']! > 0
          ? 'Wait for the full signal; false starts matter more than raw speed.'
          : 'Keep your finger relaxed and compare results on the same device.',
    GameType.visualSearch =>
      'Scan in a consistent path instead of jumping randomly around the grid.',
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

double scoreGame({
  required GameType type,
  required int difficulty,
  required double accuracy,
  required int medianResponseMs,
  int span = 0,
  int falseStarts = 0,
}) {
  final safeAccuracy = accuracy.clamp(0, 1);
  final pace = switch (type) {
    GameType.colorClash => _pace(medianResponseMs, fast: 450, slow: 1600),
    GameType.mathBlitz => _pace(medianResponseMs, fast: 900, slow: 3500),
    GameType.memoryTiles => (span / max(1, 4 + difficulty)).clamp(0, 1),
    GameType.reflexTap => _pace(medianResponseMs, fast: 180, slow: 700),
    GameType.visualSearch => _pace(medianResponseMs, fast: 550, slow: 3000),
  };
  final accuracyWeight = type == GameType.reflexTap ? .35 : .7;
  final falseStartPenalty = type == GameType.reflexTap ? falseStarts * 6 : 0;
  return (100 * (safeAccuracy * accuracyWeight + pace * (1 - accuracyWeight)) -
          falseStartPenalty)
      .clamp(0, 100)
      .toDouble();
}

double _pace(int value, {required int fast, required int slow}) {
  if (value <= 0) return 0;
  return ((slow - value) / (slow - fast)).clamp(0, 1).toDouble();
}
