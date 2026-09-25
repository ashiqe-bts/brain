import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/brain_models.dart';
import '../storage/brain_repository.dart';
import '../training/training_analytics.dart';

class BrainViewState extends Equatable {
  const BrainViewState(this.data, this.revision, {this.ready = true});
  final BrainState data;
  final int revision;
  final bool ready;
  @override
  List<Object?> get props => [revision, ready];
}

class BrainCubit extends Cubit<BrainViewState> {
  BrainCubit(this.repository, BrainState initial)
    : super(BrainViewState(initial, 0));
  final BrainRepository repository;
  BrainState get data => state.data;

  Future<void> _commit() async {
    emit(BrainViewState(data, state.revision + 1));
    await repository.save(data);
  }

  Future<void> bootstrap() async {
    ensureToday();
    await _commit();
  }

  void ensureToday() {
    final today = localDate();
    if (data.lastMissionDate != today) {
      final seeded = Random(stableSeed('$today|missions'));
      final game = GameType.values[seeded.nextInt(GameType.values.length)];
      data.missions = [
        const Mission(
          id: 'workout',
          title: "Complete today's workout",
          target: 1,
          reward: 40,
        ),
        Mission(
          id: 'correct',
          title: 'Get 15 correct in ${game.title}',
          target: 15,
          reward: 30,
        ),
        const Mission(
          id: 'record',
          title: 'Beat a personal record',
          target: 1,
          reward: 50,
        ),
      ];
      data.lastMissionDate = today;
    }
    if (data.draft != null && data.draft!.date != today) data.draft = null;
  }

  Future<void> finishOnboarding({
    required int hour,
    required int minute,
    required bool reminders,
  }) async {
    data
      ..onboarded = true
      ..reminderHour = hour
      ..reminderMinute = minute
      ..reminderEnabled = reminders;
    await _commit();
  }

  Future<void> setTheme(BrainTheme value) async {
    data.theme = value;
    await _commit();
  }

  Future<void> toggle(String key, bool value) async {
    switch (key) {
      case 'sound':
        data.sound = value;
      case 'music':
        data.music = value;
      case 'haptics':
        data.haptics = value;
      case 'reducedMotion':
        data.reducedMotion = value;
      case 'reminder':
        data.reminderEnabled = value;
      case 'streakWarning':
        data.streakWarning = value;
    }
    await _commit();
  }

  Future<void> setReminder(int h, int m) async {
    data
      ..reminderHour = h
      ..reminderMinute = m;
    await _commit();
  }

  void haptic([bool warning = false]) {
    if (!data.haptics) return;
    warning ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
  }

  Future<void> startWorkout() async {
    final today = localDate();
    if (data.daily.any((e) => e.date == today)) return;
    data.draft ??= WorkoutDraft(date: today, order: dailyOrder(today));
    await _commit();
  }

  Future<bool> recordResult(GameResult result) async {
    final previous = personalBest(
      result.type,
      result.mode,
      difficulty: result.difficulty,
      rulesVersion: result.rulesVersion,
    );
    final isRecord =
        result.mode != GameMode.relaxed &&
        (previous == null ||
            result.score > previous.score ||
            (result.type == GameType.reflexTap &&
                result.reactionMs != null &&
                (previous.reactionMs == null ||
                    result.reactionMs! < previous.reactionMs!)));
    data.history.add(result);
    await repository.saveGame(result);
    final recentComparable =
        data.history
            .where(
              (item) =>
                  item.type == result.type &&
                  item.rulesVersion == result.rulesVersion &&
                  item.contributesToTrends,
            )
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? DateTime(1970)).compareTo(
              a.completedAt ?? DateTime(1970),
            ),
          );
    if (result.contributesToTrends) {
      data.difficulties[result.type.name] = adaptDifficulty(
        result.difficulty,
        recentComparable.take(3).map((item) => item.normalized),
      );
    }
    if (result.mode == GameMode.official) {
      final draft = data.draft;
      if (draft != null) {
        data.draft = WorkoutDraft(
          date: draft.date,
          order: draft.order,
          results: [...draft.results, result],
        );
      }
    } else if (result.mode != GameMode.relaxed) {
      addXp(5 + min(10, result.score ~/ 10));
    }
    _progressMission('correct', result.correct);
    if (isRecord) {
      _progressMission('record', 1);
      addXp(25);
    }
    if (result.accuracy >= .999 && result.attempts > 0) addXp(20);
    await _commit();
    return isRecord;
  }

  GameResult? personalBest(
    GameType type,
    GameMode mode, {
    int? difficulty,
    int rulesVersion = 2,
  }) {
    if (mode == GameMode.relaxed) return null;
    final items = data.history
        .where(
          (e) =>
              e.type == type &&
              e.rulesVersion == rulesVersion &&
              (difficulty == null || e.difficulty == difficulty) &&
              (mode == GameMode.personalBest
                  ? e.mode == GameMode.personalBest ||
                        e.mode == GameMode.standard ||
                        e.mode == GameMode.official
                  : e.mode == mode),
        )
        .toList();
    if (items.isEmpty) return null;
    if (type == GameType.reflexTap) {
      items.sort(
        (a, b) => (a.reactionMs ?? 9999).compareTo(b.reactionMs ?? 9999),
      );
    } else {
      items.sort((a, b) => b.score.compareTo(a.score));
    }
    return items.first;
  }

  Future<DailySummary?> completeWorkout() async {
    final draft = data.draft;
    if (draft == null || draft.results.length < 5) return null;
    int value(GameType g) =>
        (draft.results.firstWhere((e) => e.type == g).normalized).round();
    final focus = value(GameType.colorClash),
        memory = value(GameType.memoryTiles),
        math = value(GameType.mathBlitz);
    final reflex = draft.results.firstWhere(
      (e) => e.type == GameType.reflexTap,
    );
    final speed = ((value(GameType.visualSearch) + reflex.normalized) / 2)
        .round();
    final answers = draft.results.where((e) => e.type != GameType.reflexTap);
    final attempts = answers.fold<int>(0, (s, e) => s + e.attempts),
        correct = answers.fold<int>(0, (s, e) => s + e.correct);
    final accuracy = attempts == 0 ? 0 : (100 * correct / attempts).round();
    final summary = DailySummary(
      date: draft.date,
      focus: focus,
      memory: memory,
      speed: speed,
      math: math,
      accuracy: accuracy,
      reactionMs: reflex.reactionMs,
      results: draft.results,
      skillRatings: {
        for (final result in draft.results)
          result.type.skill: trainingLevel(
            difficulty: result.difficulty,
            score: result.normalized,
          ),
      },
    );
    data.daily.removeWhere((e) => e.date == summary.date);
    data.daily.add(summary);
    data.daily.sort((a, b) => a.date.compareTo(b.date));
    _updateStreak(summary.date);
    data.workouts++;
    data.draft = null;
    addXp(100);
    _progressMission('workout', 1);
    _evaluateAchievements(summary);
    await repository.saveDaily(summary);
    await _commit();
    return summary;
  }

  void _updateStreak(String date) {
    if (data.lastCompletedDate == date) return;
    if (data.lastCompletedDate == null) {
      data.currentStreak = 1;
    } else {
      final last = DateTime.parse(data.lastCompletedDate!),
          now = DateTime.parse(date),
          gap = now.difference(last).inDays;
      data.currentStreak = gap == 1 ? data.currentStreak + 1 : 1;
    }
    data.lastCompletedDate = date;
    data.longestStreak = max(data.longestStreak, data.currentStreak);
  }

  void addXp(int amount) {
    data.xp += amount;
    while (data.level < 50 && data.xp >= data.xpNeeded) {
      data.xp -= data.xpNeeded;
      data.level++;
    }
  }

  void _progressMission(String id, int amount) {
    final i = data.missions.indexWhere((m) => m.id == id);
    if (i >= 0) {
      final m = data.missions[i];
      data.missions[i] = m.copyWith(
        progress: min(m.target, m.progress + amount),
      );
    }
  }

  Future<void> claimMission(String id) async {
    final i = data.missions.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final m = data.missions[i];
    if (m.complete && !m.claimed) {
      addXp(m.reward);
      data.missions[i] = m.copyWith(claimed: true);
      await _commit();
    }
  }

  void _evaluateAchievements(DailySummary s) {
    data.achievements.add('First Spark');
    if (data.currentStreak >= 7) data.achievements.add('One Week Strong');
    if ((s.reactionMs ?? 9999) < 250) {
      data.achievements.add('Lightning Fingers');
    }
    if (data.history
            .where((e) => e.type == GameType.memoryTiles && e.accuracy == 1)
            .length >=
        5) {
      data.achievements.add('Memory Machine');
    }
    if (data.history
            .where((e) => e.type == GameType.mathBlitz)
            .fold<int>(0, (a, b) => a + b.correct) >=
        25) {
      data.achievements.add('Math Wizard');
    }
    if (data.currentStreak >= 30) data.achievements.add('Unstoppable');
    if (s.accuracy > 95) data.achievements.add('Perfectionist');
  }
}
