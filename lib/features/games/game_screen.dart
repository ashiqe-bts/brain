import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';
import 'classic_game_board.dart';
import 'game_engine.dart';
import 'research_game_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
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
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool get usesResearchGame =>
      widget.type != GameType.colorClash &&
      widget.type != GameType.mathBlitz &&
      widget.type != GameType.reflexTap &&
      widget.type != GameType.visualSearch;

  late final Random random;
  late final GameTrialFactory trialFactory;
  late final List<ColorTrial> colorTrials;
  late final List<MathTrial> mathTrials;
  final stopwatch = Stopwatch();
  final trialWatch = Stopwatch();
  final reflexWatch = Stopwatch();
  Timer? timer, delayTimer;
  GameLifecycle lifecycle = GameLifecycle.initial;
  int countdown = AppSettings.gameCountdownSeconds,
      timeLeft = AppSettings.defaultTimedSessionSeconds,
      score = 0,
      correct = 0,
      attempts = 0,
      combo = 0,
      bestCombo = 0,
      mistakes = 0;
  final checkpoints = <int>[];
  int colorTrialIndex = 0, mathTrialIndex = 0, itemCount = 12;
  late ColorTrial colorTrial;
  late MathTrial mathTrial;
  late VisualSearchTrial visualTrial;
  int reflexTrial = -1, falseStarts = 0;
  bool reflexGo = false;
  final reactions = <int>[];
  final responseTimes = <int>[];
  final colorConditionAttempts = <String, int>{};
  final colorConditionCorrect = <String, int>{};
  final colorConditionTimes = <String, List<int>>{};
  bool? lastAnswerCorrect;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final seed =
        widget.randomSeed ??
        stableSeed(
          '${DateTime.now().microsecondsSinceEpoch}|${widget.type.name}',
        );
    random = Random(seed);
    trialFactory = GameTrialFactory(seed);
    colorTrials = trialFactory.colorTrials(120);
    mathTrials = trialFactory.mathTrials(widget.difficulty, count: 120);
    timeLeft = AppSettings.defaultTimedSessionSeconds;
    if (usesResearchGame) return;
    _countdown();
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
      timer?.cancel();
      delayTimer?.cancel();
      stopwatch.stop();
      if (mounted) setState(() => lifecycle = GameLifecycle.paused);
    } else if (state == AppLifecycleState.resumed &&
        lifecycle == GameLifecycle.paused) {
      if (widget.type == GameType.reflexTap) {
        reflexGo = false;
        _scheduleReflex();
      } else {
        setState(() => lifecycle = GameLifecycle.running);
        stopwatch.start();
        _startTimer();
      }
    }
  }

  void _countdown() {
    lifecycle = GameLifecycle.countdown;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown <= 1) {
        t.cancel();
        setState(() => countdown = 0);
        _begin();
      } else {
        setState(() => countdown--);
      }
    });
  }

  void _begin() {
    lifecycle = GameLifecycle.running;
    stopwatch.start();
    switch (widget.type) {
      case GameType.colorClash:
        _nextColor();
      case GameType.mathBlitz:
        _nextMath();
      case GameType.memoryTiles:
        return;
      case GameType.reflexTap:
        _scheduleReflex();
      case GameType.visualSearch:
        _nextOdd();
      case GameType.signalStop ||
          GameType.peripheralFocus ||
          GameType.nBackNavigator ||
          GameType.ruleSwitch ||
          GameType.arrowGuard ||
          GameType.pairLink ||
          GameType.symbolSprint ||
          GameType.objectTracker ||
          GameType.towerPlanner ||
          GameType.dualTaskDash ||
          GameType.logicSeries ||
          GameType.spatialRotation:
        return;
    }
    _startTimer();
  }

  bool get timed =>
      widget.mode != GameMode.relaxed && widget.type != GameType.reflexTap;
  void _startTimer() {
    if (!timed) return;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 1) {
        t.cancel();
        _finish();
      } else if (mounted) {
        setState(() {
          timeLeft--;
          checkpoints.add(score);
        });
      }
    });
  }

  void _nextColor() {
    colorTrial = colorTrials[colorTrialIndex++ % colorTrials.length];
    trialWatch
      ..reset()
      ..start();
  }

  void _answerColor(int value) {
    final condition = colorTrial.isCongruent ? 'congruent' : 'incongruent';
    final ok = value == colorTrial.colorIndex;
    final responseMs = trialWatch.elapsedMilliseconds;
    colorConditionAttempts.update(
      condition,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (ok) {
      colorConditionCorrect.update(
        condition,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      colorConditionTimes.putIfAbsent(condition, () => []).add(responseMs);
    }
    _answer(ok, responseMs: responseMs);
    _nextColor();
  }

  void _nextMath() {
    mathTrial = mathTrials[mathTrialIndex++ % mathTrials.length];
    trialWatch
      ..reset()
      ..start();
  }

  void _answerMath(bool value) {
    _answer(
      value == mathTrial.isCorrect,
      responseMs: trialWatch.elapsedMilliseconds,
    );
    _nextMath();
  }

  void _nextOdd() {
    itemCount = min(30, 9 + widget.difficulty * 3);
    visualTrial = trialFactory.visualSearch(
      widget.difficulty,
      itemCount: itemCount,
    );
    trialWatch
      ..reset()
      ..start();
  }

  void _answerOdd(int value) {
    _answer(
      value == visualTrial.targetIndex,
      responseMs: trialWatch.elapsedMilliseconds,
    );
    _nextOdd();
  }

  void _answer(bool ok, {int? responseMs}) {
    attempts++;
    if (ok) {
      if (responseMs != null) responseTimes.add(responseMs);
      correct++;
      combo++;
      bestCombo = max(bestCombo, combo);
      var multiplier = combo >= 20
          ? 2.0
          : combo >= 10
          ? 1.5
          : combo >= 5
          ? 1.2
          : 1.0;
      score += (1 * multiplier).round();
      _feedback(true);
    } else {
      combo = 0;
      mistakes++;
      score = max(0, score - 1);
      _feedback(false);
    }
    lastAnswerCorrect = ok;
    setState(() {});
  }

  void _scheduleReflex() {
    if (reflexTrial >= 5) {
      _finish();
      return;
    }
    reflexGo = false;
    lifecycle = GameLifecycle.running;
    setState(() {});
    delayTimer = Timer(Duration(milliseconds: 1500 + random.nextInt(2501)), () {
      if (!mounted) return;
      reflexWatch
        ..reset()
        ..start();
      setState(() => reflexGo = true);
    });
  }

  void _tapReflex() {
    if (!reflexGo) {
      falseStarts++;
      mistakes++;
      score = max(0, score - 1);
      _feedback(false);
      delayTimer?.cancel();
      _scheduleReflex();
      return;
    }
    final ms = reflexWatch.elapsedMilliseconds;
    if (reflexTrial < 0) {
      reflexTrial = 0;
      _feedback(true);
      _scheduleReflex();
      return;
    }
    reactions.add(ms);
    score += max(1, 10 - (ms ~/ 80));
    correct++;
    attempts++;
    reflexTrial++;
    _feedback(true);
    _scheduleReflex();
  }

  void _finish() {
    if (lifecycle == GameLifecycle.completed) return;
    timer?.cancel();
    delayTimer?.cancel();
    stopwatch.stop();
    lifecycle = GameLifecycle.completed;
    final accuracy = attempts == 0 ? 0.0 : correct / attempts;
    final responseMedian = medianMilliseconds(
      widget.type == GameType.reflexTap ? reactions : responseTimes,
    );
    final scoreDetails = scoreGameDetails(
      type: widget.type,
      difficulty: widget.difficulty,
      accuracy: accuracy,
      medianResponseMs: responseMedian,
      span: 0,
      falseStarts: falseStarts,
    );
    final reaction = widget.type == GameType.reflexTap && responseMedian > 0
        ? responseMedian
        : null;
    final result = GameResult(
      type: widget.type,
      mode: widget.mode,
      score: score,
      normalized: scoreDetails.normalized,
      accuracy: accuracy,
      durationMs: stopwatch.elapsedMilliseconds,
      difficulty: widget.difficulty,
      bestCombo: bestCombo,
      reactionMs: reaction,
      correct: correct,
      attempts: attempts,
      checkpoints: checkpoints,
      completedAt: widget.now?.call() ?? DateTime.now(),
      rulesVersion: widget.type.rulesVersion,
      metrics: {
        'medianResponseMs': responseMedian.toDouble(),
        'falseStarts': falseStarts.toDouble(),
        for (final entry in colorConditionAttempts.entries)
          '${entry.key}Attempts': entry.value.toDouble(),
        for (final entry in colorConditionCorrect.entries)
          '${entry.key}Correct': entry.value.toDouble(),
        for (final entry in colorConditionTimes.entries)
          '${entry.key}MedianMs': medianMilliseconds(entry.value).toDouble(),
        if (colorConditionTimes.containsKey('congruent') &&
            colorConditionTimes.containsKey('incongruent'))
          'interferenceCostMs':
              (medianMilliseconds(colorConditionTimes['incongruent']!) -
                      medianMilliseconds(colorConditionTimes['congruent']!))
                  .toDouble(),
      },
      scoreComponents: scoreDetails.toJson(),
    );
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (usesResearchGame) {
      return ResearchGameScreen(
        type: widget.type,
        mode: widget.mode,
        difficulty: widget.difficulty,
        personalBest: widget.personalBest,
        randomSeed: widget.randomSeed,
        now: widget.now,
      );
    }
    return PopScope(
      canPop: lifecycle == GameLifecycle.completed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.type.title, style: const TextStyle(fontSize: 20)),
          actions: [
            if (timed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppText.secondsRemaining(timeLeft),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: context.rewardInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: lifecycle == GameLifecycle.countdown
                ? Center(
                    key: const ValueKey('count'),
                    child: Text(
                      '$countdown',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : lifecycle == GameLifecycle.paused
                ? _paused()
                : _game(),
          ),
        ),
      ),
    );
  }

  Widget _paused() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_outline_rounded, size: 72),
          const SizedBox(height: 16),
          Text(
            AppText.gameplay.paused,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              setState(() => lifecycle = GameLifecycle.running);
              stopwatch.start();
              if (widget.type == GameType.reflexTap) {
                _scheduleReflex();
              } else {
                _startTimer();
              }
            },
            child: Text(AppText.gameplay.resume),
          ),
        ],
      ),
    );
  }

  Widget _game() {
    return Padding(
      key: ValueKey(widget.type),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SessionHud(
            label: widget.mode.displayTitle,
            progress: timed
                ? timeLeft / AppSettings.defaultTimedSessionSeconds
                : min(1, correct / 10),
            color: context.gameAccent(widget.type),
            primaryStat: AppText.score(score),
            secondaryStat: AppText.combo(combo),
            answerCorrect: lastAnswerCorrect,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: switch (widget.type) {
              GameType.colorClash => ColorClashBoard(
                trial: colorTrial,
                onAnswer: _answerColor,
              ),
              GameType.mathBlitz => MathBlitzBoard(
                trial: mathTrial,
                onAnswer: _answerMath,
              ),
              GameType.memoryTiles => const SizedBox.shrink(),
              GameType.reflexTap => _reflex(),
              GameType.visualSearch => _visualSearch(),
              _ => const SizedBox.shrink(),
            },
          ),
          if (widget.mode == GameMode.relaxed)
            TextButton(
              onPressed: _finish,
              child: Text(AppText.gameplay.finishRelaxed),
            ),
        ],
      ),
    );
  }

  Widget _reflex() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _tapReflex,
    child: Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reflexGo
              ? Colors.greenAccent
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(color: context.brain.outline, width: 5),
          boxShadow: reflexGo
              ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 35)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          reflexGo ? 'GO!' : 'WAIT…',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: reflexGo ? Colors.black : null,
          ),
        ),
      ),
    ),
  );
  Widget _visualSearch() => Column(
    children: [
      Text(AppText.gameplay.findTarget),
      const SizedBox(height: 8),
      Semantics(
        label: AppText.gameplay.targetSymbol,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.brain.hud,
            border: Border.all(color: context.brain.outline, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _glyph(visualTrial.target, 38),
        ),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemCount > 20
                ? 6
                : itemCount > 12
                ? 5
                : 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: itemCount,
          itemBuilder: (context, i) => Semantics(
            label: AppText.searchItem(i + 1),
            button: true,
            child: InkWell(
              onTap: () => _answerOdd(i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.brain.outline, width: 3),
                ),
                alignment: Alignment.center,
                child: _glyph(visualTrial.items[i], itemCount > 20 ? 24 : 32),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _glyph(VisualGlyph glyph, double size) {
    final filledIcons = [
      Icons.circle,
      Icons.change_history,
      Icons.square,
      Icons.hexagon,
    ];
    final outlinedIcons = [
      Icons.circle_outlined,
      Icons.change_history_outlined,
      Icons.square_outlined,
      Icons.hexagon_outlined,
    ];
    return Transform.rotate(
      angle: glyph.rotation * pi / 2,
      child: Icon(
        (glyph.filled ? filledIcons : outlinedIcons)[glyph.shape],
        size: size,
        color: context.clashColor(glyph.colorIndex),
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.gameplay.leaveTitle),
        content: Text(AppText.gameplay.classicLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppText.gameplay.stay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppText.gameplay.leave),
          ),
        ],
      ),
    );
    if (yes == true && mounted) Navigator.pop(context);
  }

  void _feedback(bool positive) {
    final cubit = context.read<BrainCubit>();
    lastAnswerCorrect = positive;
    if (cubit.data.sound) {
      SystemSound.play(SystemSoundType.click);
    }
    if (cubit.data.haptics) {
      positive ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    }
  }
}
