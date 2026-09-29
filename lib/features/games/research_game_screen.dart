import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import '../../core/training/game_catalog.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import 'game_engine.dart';
import 'research_game_board.dart';
import 'research_game_engine.dart';

class ResearchGameScreen extends StatefulWidget {
  const ResearchGameScreen({
    super.key,
    required this.type,
    required this.mode,
    required this.difficulty,
    this.personalBest,
    this.randomSeed,
    this.now,
  });

  final GameType type;
  final GameMode mode;
  final int difficulty;
  final GameResult? personalBest;
  final int? randomSeed;
  final DateTime Function()? now;

  @override
  State<ResearchGameScreen> createState() => _ResearchGameScreenState();
}

class _ResearchGameScreenState extends State<ResearchGameScreen>
    with WidgetsBindingObserver {
  late final ResearchGameEngine engine;
  late final GameDefinition definition;
  final sessionWatch = Stopwatch();
  final trialWatch = Stopwatch();
  Timer? timer;
  Timer? delayTimer;
  GameLifecycle lifecycle = GameLifecycle.countdown;
  ResearchTrial? trial;
  int countdown = 3;
  int timeLeft = 30;
  int attempts = 0;
  int correct = 0;
  int score = 0;
  int bestCombo = 0;
  int combo = 0;
  int falseStarts = 0;
  int maxSpan = 0;
  int dualClassificationCorrect = 0;
  int dualCountCorrect = 0;
  bool showingStimulus = true;
  bool? lastAnswerCorrect;
  final responseTimes = <int>[];
  final conditionAttempts = <String, int>{};
  final conditionCorrect = <String, int>{};
  final conditionTimes = <String, List<int>>{};
  final correctExposureTimes = <int>[];
  final stopSignalDelays = <int>[];

  bool get timed =>
      widget.mode != GameMode.relaxed && definition.standardSeconds > 0;
  int get targetTrials => 8 + widget.difficulty ~/ 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    definition = gameDefinition(widget.type);
    timeLeft = definition.standardSeconds == 0
        ? 30
        : definition.standardSeconds;
    engine = ResearchGameEngine(
      seed:
          widget.randomSeed ??
          stableSeed(
            '${DateTime.now().microsecondsSinceEpoch}|${widget.type.name}',
          ),
      type: widget.type,
      difficulty: widget.difficulty,
    );
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    delayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pause();
    }
  }

  void _startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (value) {
      if (countdown <= 1) {
        value.cancel();
        setState(() => countdown = 0);
        _begin();
      } else if (mounted) {
        setState(() => countdown--);
      }
    });
  }

  void _begin() {
    lifecycle = GameLifecycle.running;
    sessionWatch.start();
    _nextTrial();
    if (timed) {
      timer = Timer.periodic(const Duration(seconds: 1), (value) {
        if (timeLeft <= 1) {
          value.cancel();
          _finish();
        } else if (mounted) {
          setState(() => timeLeft--);
        }
      });
    }
  }

  void _nextTrial() {
    if (!timed && attempts >= targetTrials) {
      _finish();
      return;
    }
    delayTimer?.cancel();
    trial = engine.nextTrial();
    if (trial!.condition == 'stop') stopSignalDelays.add(trial!.exposureMs);
    maxSpan = max(maxSpan, trial!.span);
    showingStimulus = trial!.exposureMs > 0;
    trialWatch
      ..reset()
      ..start();
    if (showingStimulus) {
      delayTimer = Timer(Duration(milliseconds: trial!.exposureMs), () {
        if (!mounted || lifecycle != GameLifecycle.running) return;
        setState(() => showingStimulus = false);
        if (trial!.condition == 'stop') {
          delayTimer = Timer(const Duration(milliseconds: 650), () {
            if (mounted && lifecycle == GameLifecycle.running) {
              _answer(trial!.correctIndex, automatic: true);
            }
          });
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _answer(int selected, {bool automatic = false}) {
    if (lifecycle != GameLifecycle.running || trial == null) return;
    if (showingStimulus && trial!.condition != 'stop') return;
    delayTimer?.cancel();
    final elapsed = trialWatch.elapsedMilliseconds;
    final ok = selected == trial!.correctIndex;
    engine.acceptAnswer(trial!, selected);
    if (widget.type == GameType.dualTaskDash) {
      final chosen = trial!.options[selected].split('·');
      final expected = trial!.options[trial!.correctIndex].split('·');
      if (chosen.first.trim() == expected.first.trim()) {
        dualClassificationCorrect++;
      }
      if (chosen.last.trim() == expected.last.trim()) dualCountCorrect++;
    }
    attempts++;
    conditionAttempts.update(
      trial!.condition,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    if (ok) {
      correct++;
      combo++;
      bestCombo = max(bestCombo, combo);
      score += 10 + min(5, combo);
      conditionCorrect.update(
        trial!.condition,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (!automatic) responseTimes.add(elapsed);
      if (trial!.exposureMs > 0) {
        correctExposureTimes.add(trial!.exposureMs);
      }
      if (!automatic) {
        conditionTimes.putIfAbsent(trial!.condition, () => []).add(elapsed);
      }
    } else {
      combo = 0;
      score = max(0, score - 2);
      if (trial!.condition == 'stop') falseStarts++;
    }
    setState(() => lastAnswerCorrect = ok);
    delayTimer = Timer(const Duration(milliseconds: 260), _nextTrial);
  }

  void _pause() {
    if (lifecycle != GameLifecycle.running) return;
    timer?.cancel();
    delayTimer?.cancel();
    sessionWatch.stop();
    trialWatch.stop();
    if (mounted) setState(() => lifecycle = GameLifecycle.paused);
  }

  void _resume() {
    setState(() => lifecycle = GameLifecycle.running);
    sessionWatch.start();
    _nextTrial();
    if (timed) {
      timer = Timer.periodic(const Duration(seconds: 1), (value) {
        if (timeLeft <= 1) {
          value.cancel();
          _finish();
        } else if (mounted) {
          setState(() => timeLeft--);
        }
      });
    }
  }

  void _finish() {
    if (lifecycle == GameLifecycle.completed) return;
    timer?.cancel();
    delayTimer?.cancel();
    sessionWatch.stop();
    lifecycle = GameLifecycle.completed;
    final accuracy = attempts == 0 ? 0.0 : correct / attempts;
    final median = medianMilliseconds(responseTimes);
    final details = scoreGameDetails(
      type: widget.type,
      difficulty: widget.difficulty,
      accuracy: accuracy,
      medianResponseMs: median,
      span: maxSpan,
      falseStarts: falseStarts,
    );
    final metrics = <String, double>{
      'medianResponseMs': median.toDouble(),
      'falseStarts': falseStarts.toDouble(),
      'span': maxSpan.toDouble(),
      'trials': attempts.toDouble(),
      'errors': (attempts - correct).toDouble(),
      for (final entry in conditionAttempts.entries)
        '${entry.key}Attempts': entry.value.toDouble(),
      for (final entry in conditionCorrect.entries)
        '${entry.key}Correct': entry.value.toDouble(),
      for (final entry in conditionTimes.entries)
        '${entry.key}MedianMs': medianMilliseconds(entry.value).toDouble(),
    };
    final switchCost =
        (metrics['switchMedianMs'] ?? 0) - (metrics['repeatMedianMs'] ?? 0);
    final interferenceCost =
        (metrics['incongruentMedianMs'] ?? 0) -
        (metrics['congruentMedianMs'] ?? 0);
    if (conditionTimes.containsKey('switch') &&
        conditionTimes.containsKey('repeat')) {
      metrics['switchCostMs'] = switchCost;
    }
    if (conditionTimes.containsKey('incongruent') &&
        conditionTimes.containsKey('congruent')) {
      metrics['interferenceCostMs'] = interferenceCost;
    }
    if (conditionAttempts.containsKey('stop')) {
      final successfulStops = conditionCorrect['stop'] ?? 0;
      final stopAttempts = conditionAttempts['stop']!;
      metrics['stopSuccessRate'] = successfulStops / max(1, stopAttempts);
      metrics['successfulStops'] = successfulStops.toDouble();
      metrics['commissionErrors'] = (stopAttempts - successfulStops).toDouble();
      final goMedian = metrics['goMedianMs'] ?? 0;
      final stopDelay = medianMilliseconds(stopSignalDelays);
      metrics['estimatedStoppingMs'] = max(0, goMedian - stopDelay);
    }
    if (conditionAttempts.containsKey('match')) {
      final hits = conditionCorrect['match'] ?? 0;
      final misses = conditionAttempts['match']! - hits;
      final correctRejections = conditionCorrect['non-match'] ?? 0;
      final falseAlarms =
          (conditionAttempts['non-match'] ?? 0) - correctRejections;
      final hitRate = hits / max(1, conditionAttempts['match']!);
      final nonMatchAccuracy =
          correctRejections / max(1, conditionAttempts['non-match'] ?? 0);
      metrics['discrimination'] = (hitRate + nonMatchAccuracy) / 2;
      metrics['hits'] = hits.toDouble();
      metrics['misses'] = misses.toDouble();
      metrics['falseAlarms'] = falseAlarms.toDouble();
    }
    if (correctExposureTimes.isNotEmpty) {
      metrics['exposureThresholdMs'] = correctExposureTimes
          .reduce(min)
          .toDouble();
      metrics['exposureDurationMs'] = medianMilliseconds(
        correctExposureTimes,
      ).toDouble();
    }
    if (widget.type == GameType.memoryTiles) {
      metrics['capacity'] = maxSpan.toDouble();
      metrics['rounds'] = attempts.toDouble();
    }
    if (widget.type == GameType.dualTaskDash) {
      metrics['classificationAccuracy'] =
          dualClassificationCorrect / max(1, attempts);
      metrics['countAccuracy'] = dualCountCorrect / max(1, attempts);
    }
    if (widget.type == GameType.towerPlanner) {
      metrics['solvedTrials'] = engine.towerSolvedTrials.toDouble();
      metrics['excessMoves'] = engine.towerExcessMoves.toDouble();
      metrics['planningMedianMs'] = median.toDouble();
    }
    if (widget.type == GameType.objectTracker) {
      metrics['objectCount'] = maxSpan.toDouble();
      metrics['trackingAccuracy'] = accuracy;
    }
    if (widget.type == GameType.symbolSprint) {
      metrics['correctSubstitutions'] = correct.toDouble();
    }
    final result = GameResult(
      type: widget.type,
      mode: widget.mode,
      score: score,
      normalized: details.normalized,
      accuracy: accuracy,
      durationMs: sessionWatch.elapsedMilliseconds,
      difficulty: widget.difficulty,
      bestCombo: bestCombo,
      correct: correct,
      attempts: attempts,
      completedAt: widget.now?.call() ?? DateTime.now(),
      rulesVersion: widget.type.rulesVersion,
      metrics: metrics,
      scoreComponents: details.toJson(),
    );
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _showResult(result);
    });
  }

  Future<void> _showResult(GameResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 54,
                color: context.gameAccent(widget.type),
              ),
              const SizedBox(height: 12),
              PageEyebrow(
                '${widget.type.domain} review',
                color: context.gameAccent(widget.type),
              ),
              const SizedBox(height: 16),
              Text(
                '${(result.accuracy * 100).round()}% accuracy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                result.metrics['medianResponseMs'] == 0
                    ? '${result.correct} of ${result.attempts} correct'
                    : '${result.metrics['medianResponseMs']!.round()} ms median · ${result.correct} of ${result.attempts} correct',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(sessionTip(result), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              PrimaryAction(
                expanded: true,
                color: context.brain.success,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pop(context, result);
                },
                icon: Icons.arrow_forward_rounded,
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: lifecycle == GameLifecycle.completed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.type.title),
          actions: [
            if (lifecycle == GameLifecycle.running)
              IconButton(
                tooltip: 'Pause game',
                onPressed: _pause,
                icon: const Icon(Icons.pause_rounded),
              ),
            if (timed)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: Text('$timeLeft S'),
              ),
          ],
        ),
        body: SafeArea(
          child: switch (lifecycle) {
            GameLifecycle.countdown => Center(
              child: Text(
                '$countdown',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            GameLifecycle.paused => _pausedView(),
            _ => _gameView(),
          },
        ),
      ),
    );
  }

  Widget _pausedView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline_rounded, size: 72),
        const SizedBox(height: 16),
        Text('Paused', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        FilledButton(onPressed: _resume, child: const Text('Resume')),
      ],
    ),
  );

  Widget _gameView() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          children: [
            if (lastAnswerCorrect != null)
              Semantics(
                liveRegion: true,
                label: lastAnswerCorrect! ? 'Correct' : 'Try the next one',
                child: Icon(
                  lastAnswerCorrect!
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  color: lastAnswerCorrect!
                      ? context.brain.success
                      : context.brain.danger,
                ),
              ),
            const Spacer(),
            Text('Score $score · $correct/$attempts'),
          ],
        ),
        const SizedBox(height: 12),
        ProgressMeter(
          label: widget.mode.displayTitle,
          value: timed
              ? timeLeft / max(1, definition.standardSeconds)
              : min(1, attempts / targetTrials),
          color: context.gameAccent(widget.type),
        ),
        const SizedBox(height: 12),
        Text(
          definition.instructions,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: trial == null
              ? const SizedBox.shrink()
              : ResearchGameBoard(
                  type: widget.type,
                  difficulty: widget.difficulty,
                  trial: trial!,
                  showingStimulus: showingStimulus,
                  trialNumber: attempts,
                  onAnswer: _answer,
                ),
        ),
        if (widget.mode == GameMode.relaxed)
          TextButton(
            onPressed: _finish,
            child: const Text('Finish relaxed session'),
          ),
      ],
    ),
  );

  Future<void> _confirmQuit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this round?'),
        content: const Text('This unfinished round will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }
}
