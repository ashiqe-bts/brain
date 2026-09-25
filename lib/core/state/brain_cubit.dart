import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/brain_models.dart';
import '../storage/brain_repository.dart';

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
      ..reminderEnabled = reminders
      ..mood = BuddyMood.wave;
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

  Future<void> react(BuddyMood mood) async {
    data.mood = mood;
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
    final previous = personalBest(result.type, result.mode);
    final isRecord =
        previous == null ||
        result.score > previous.score ||
        (result.type == GameType.reflexTap &&
            result.reactionMs != null &&
            (previous.reactionMs == null ||
                result.reactionMs! < previous.reactionMs!));
    data.history.add(result);
    await repository.saveGame(result);
    data.difficulties[result.type.name] = result.normalized > 80
        ? min(10, result.difficulty + 1)
        : result.normalized < 45
        ? max(1, result.difficulty - 1)
        : result.difficulty;
    if (result.mode == GameMode.official) {
      final draft = data.draft;
      if (draft != null) {
        data.draft = WorkoutDraft(
          date: draft.date,
          order: draft.order,
          results: [...draft.results, result],
        );
      }
    } else if (result.mode != GameMode.zen) {
      data.practiceSessions++;
      addXp((data.boosted ? 2 : 1) * (5 + min(10, result.score ~/ 10)));
      addEnergy(5);
    }
    _progressMission('correct', result.correct);
    if (isRecord) {
      _progressMission('record', 1);
      data.mood = BuddyMood.record;
      addXp(25);
    }
    if (result.accuracy >= .999 && result.attempts > 0) addXp(20);
    await _commit();
    return isRecord;
  }

  GameResult? personalBest(GameType type, GameMode mode) {
    final items = data.history
        .where(
          (e) =>
              e.type == type &&
              (mode == GameMode.personalBest ||
                  e.mode == mode ||
                  e.mode == GameMode.classic),
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
    final speed =
        ((value(GameType.visualSearch) + reflex.normalized) / 2).round();
    final answers = draft.results.where((e) => e.type != GameType.reflexTap);
    final attempts = answers.fold<int>(0, (s, e) => s + e.attempts),
        correct = answers.fold<int>(0, (s, e) => s + e.correct);
    final accuracy = attempts == 0 ? 0 : (100 * correct / attempts).round();
    final brain =
        (focus * .25 + memory * .25 + speed * .20 + math * .15 + accuracy * .15)
            .round();
    final summary = DailySummary(
      date: draft.date,
      brainScore: brain,
      focus: focus,
      memory: memory,
      speed: speed,
      math: math,
      accuracy: accuracy,
      reactionMs: reflex.reactionMs,
      results: draft.results,
    );
    data.daily.removeWhere((e) => e.date == summary.date);
    data.daily.add(summary);
    data.daily.sort((a, b) => a.date.compareTo(b.date));
    _updateStreak(summary.date);
    data.workouts++;
    data.draft = null;
    data.mood = BuddyMood.workoutComplete;
    addXp(100);
    addEnergy(50);
    _progressMission('workout', 1);
    _unlockProgression();
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
    if ([3, 7, 14, 30, 50, 100, 365].contains(data.currentStreak)) {
      data.mood = BuddyMood.streak;
    }
  }

  void addXp(int amount) {
    data.xp += amount;
    while (data.level < 50 && data.xp >= data.xpNeeded) {
      data.xp -= data.xpNeeded;
      data.level++;
      data.mood = BuddyMood.levelUp;
    }
  }

  void addEnergy(int amount) {
    data.energy += amount;
    if (data.energy >= 100) {
      data.energy -= 100;
      data.tokens++;
      data.mood = BuddyMood.fullEnergy;
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
      addEnergy(15);
      data.missions[i] = m.copyWith(claimed: true);
      if (data.missions.every((e) => e.claimed)) {
        data.tokens++;
        data.mood = BuddyMood.chest;
      }
      await _commit();
    }
  }

  Future<void> rerollMission() async {
    final i = data.missions.indexWhere((m) => m.id != 'workout' && !m.complete);
    if (i < 0) return;
    data.missions[i] = Mission(
      id: data.missions[i].id,
      title: 'Score 70+ in any practice game',
      target: 1,
      reward: data.missions[i].reward,
    );
    await _commit();
  }

  void _unlockProgression() {
    if (data.workouts >= 1) data.unlocked.add('Round Glasses');
    if (data.workouts >= 7) data.unlocked.add('7-Day Headband');
    if (data.level >= 5) data.unlocked.add('Graduation Cap');
    if (data.level >= 10) data.unlocked.add('Headphones');
    if (data.currentStreak >= 30) data.unlocked.add('Golden Glasses');
    if (data.currentStreak >= 100) data.unlocked.add('Electric Sparks');
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

  Future<void> equip(String category, String item) async {
    if (data.unlocked.contains(item) ||
        item == 'None' ||
        item == 'Brain Laboratory') {
      data.equipped[category] = item;
      await _commit();
    }
  }

  Future<void> unlock(String item, int cost) async {
    if (data.tokens >= cost) {
      data.tokens -= cost;
      data.unlocked.add(item);
      await _commit();
    }
  }

  Future<void> activateBoost() async {
    data.boostUntil = DateTime.now()
        .add(const Duration(minutes: 10))
        .toIso8601String();
    await _commit();
  }

  Future<void> awardBonusChest() async {
    data.tokens++;
    addXp(25);
    data.mood = BuddyMood.chest;
    await _commit();
  }

  Future<void> claimMicroEvent() async {
    final today = localDate();
    if (data.lastMicroEventDate == today) return;
    data.lastMicroEventDate = today;
    addXp(5);
    data.mood = BuddyMood.surprised;
    await _commit();
  }

  bool shouldInterstitial() =>
      data.practiceSessions > 0 &&
      data.practiceSessions % 4 == 0 &&
      (data.lastInterstitialAt == null ||
          DateTime.now()
                  .difference(DateTime.parse(data.lastInterstitialAt!))
                  .inMinutes >=
              10);
  Future<void> markInterstitial() async {
    data.lastInterstitialAt = DateTime.now().toIso8601String();
    await _commit();
  }

  Future<void> rescueStreak({required bool consumeFreeze}) async {
    if (data.lastCompletedDate == null || data.currentStreak == 0) return;
    final gap = DateTime.now()
        .difference(DateTime.parse(data.lastCompletedDate!))
        .inDays;
    if (gap != 2 || (consumeFreeze && data.freezes == 0)) return;
    if (consumeFreeze) data.freezes--;
    data.lastCompletedDate = localDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    data.mood = BuddyMood.streak;
    await _commit();
  }
}
