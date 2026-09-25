import 'dart:math';

import '../models/brain_models.dart';

class BaselineStatus {
  const BaselineStatus({required this.completed, this.required = 3});

  final int completed;
  final int required;

  int get remaining => max(0, required - completed);
  bool get isComplete => completed >= required;
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
