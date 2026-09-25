import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';
import 'game_engine.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.type,
    required this.mode,
    required this.difficulty,
    this.personalBest,
  });
  final GameType type;
  final GameMode mode;
  final int difficulty;
  final GameResult? personalBest;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final Random random;
  late final GameTrialFactory trialFactory;
  late final List<ColorTrial> colorTrials;
  late final List<MathTrial> mathTrials;
  final stopwatch = Stopwatch();
  final trialWatch = Stopwatch();
  final reflexWatch = Stopwatch();
  Timer? timer, delayTimer;
  GameLifecycle lifecycle = GameLifecycle.initial;
  int countdown = 3,
      timeLeft = 30,
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
  int memoryRound = 0, gridSize = 4;
  int maxMemorySpan = 0;
  Set<int> memoryTarget = {}, memorySelected = {};
  bool memoryShowing = true;
  int reflexTrial = -1, falseStarts = 0;
  bool reflexGo = false;
  final reactions = <int>[];
  final responseTimes = <int>[];
  bool? lastAnswerCorrect;
  static const names = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final seed = stableSeed(
      '${DateTime.now().microsecondsSinceEpoch}|${widget.type.name}',
    );
    random = Random(seed);
    trialFactory = GameTrialFactory(seed);
    colorTrials = trialFactory.colorTrials(120);
    mathTrials = trialFactory.mathTrials(widget.difficulty, count: 120);
    timeLeft = 30;
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
        _nextMemory();
      case GameType.reflexTap:
        _scheduleReflex();
      case GameType.visualSearch:
        _nextOdd();
    }
    _startTimer();
  }

  bool get timed =>
      widget.mode != GameMode.relaxed &&
      widget.type != GameType.memoryTiles &&
      widget.type != GameType.reflexTap;
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
    _answer(
      value == colorTrial.colorIndex,
      responseMs: trialWatch.elapsedMilliseconds,
    );
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

  void _nextMemory() {
    const roundTarget = 3;
    if (memoryRound >= roundTarget) {
      _finish();
      return;
    }
    gridSize = widget.difficulty >= 7
        ? 6
        : widget.difficulty >= 4
        ? 5
        : 4;
    final count = min(
      gridSize * gridSize - 1,
      3 + widget.difficulty + memoryRound,
    );
    memoryTarget = {};
    while (memoryTarget.length < count) {
      memoryTarget.add(random.nextInt(gridSize * gridSize));
    }
    memorySelected = {};
    memoryShowing = true;
    setState(() {});
    delayTimer = Timer(
      Duration(milliseconds: max(900, 1800 - widget.difficulty * 80)),
      () {
        if (mounted) setState(() => memoryShowing = false);
      },
    );
  }

  void _tapMemory(int i) {
    if (memoryShowing) return;
    setState(() => memorySelected.add(i));
    if (memorySelected.length >= memoryTarget.length) {
      attempts += memoryTarget.length;
      final hits = memorySelected.intersection(memoryTarget).length;
      correct += hits;
      score += hits;
      mistakes += memoryTarget.length - hits;
      if (hits == memoryTarget.length) {
        maxMemorySpan = max(maxMemorySpan, memoryTarget.length);
      }
      memoryRound++;
      delayTimer = Timer(const Duration(milliseconds: 350), _nextMemory);
    }
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
    final normalized = scoreGame(
      type: widget.type,
      difficulty: widget.difficulty,
      accuracy: accuracy,
      medianResponseMs: responseMedian,
      span: maxMemorySpan,
      falseStarts: falseStarts,
    );
    final reaction = widget.type == GameType.reflexTap && responseMedian > 0
        ? responseMedian
        : null;
    final result = GameResult(
      type: widget.type,
      mode: widget.mode,
      score: score,
      normalized: normalized,
      accuracy: accuracy,
      durationMs: stopwatch.elapsedMilliseconds,
      difficulty: widget.difficulty,
      bestCombo: bestCombo,
      reactionMs: reaction,
      correct: correct,
      attempts: attempts,
      checkpoints: checkpoints,
      completedAt: DateTime.now(),
      rulesVersion: 2,
      metrics: {
        'medianResponseMs': responseMedian.toDouble(),
        'falseStarts': falseStarts.toDouble(),
        'span': maxMemorySpan.toDouble(),
      },
    );
    if (mounted) setState(() {});
    Future.delayed(const Duration(milliseconds: 250), () {
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
                result.normalized >= 85
                    ? Icons.trending_up_rounded
                    : Icons.check_circle_outline_rounded,
                size: 54,
                color: context.gameAccent(widget.type),
              ),
              const SizedBox(height: 12),
              TitlePlaque(
                '${widget.type.domain} review',
                color: context.gameAccent(widget.type),
              ),
              const SizedBox(height: 16),
              Text(
                'TRAINING LEVEL',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                trainingLevel(
                  difficulty: result.difficulty,
                  score: result.normalized,
                ).toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${(result.accuracy * 100).round()}% accuracy'
                '${result.metrics['medianResponseMs'] == 0 ? '' : ' · ${result.metrics['medianResponseMs']!.round()} ms median'}',
                textAlign: TextAlign.center,
              ),
              if (widget.personalBest != null) ...[
                const SizedBox(height: 8),
                Text('Personal best: ${widget.personalBest!.score}'),
              ],
              const SizedBox(height: 20),
              ArcadeButton(
                expanded: true,
                color: context.brain.success,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pop(context, result);
                },
                icon: Icons.arrow_forward_rounded,
                label: 'CONTINUE',
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
          title: Text(
            widget.type.title.toUpperCase(),
            style: const TextStyle(fontSize: 20),
          ),
          actions: [
            if (timed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$timeLeft S',
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
          Text('Paused', style: Theme.of(context).textTheme.headlineSmall),
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
            child: const Text('RESUME'),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill('Score $score'),
                    _pill('Combo $combo'),
                    if (widget.personalBest != null)
                      _pill('PB ${widget.personalBest!.score}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResourceBar(
            label: widget.mode == GameMode.official
                ? 'Daily quest'
                : widget.mode.name,
            value: timed ? timeLeft / 30 : min(1, correct / 10),
            color: context.gameAccent(widget.type),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: switch (widget.type) {
              GameType.colorClash => _color(),
              GameType.mathBlitz => _math(),
              GameType.memoryTiles => _memory(),
              GameType.reflexTap => _reflex(),
              GameType.visualSearch => _visualSearch(),
            },
          ),
          if (widget.mode == GameMode.relaxed)
            TextButton(
              onPressed: _finish,
              child: const Text('Finish relaxed session'),
            ),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: context.brain.hud,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.brain.outline, width: 3),
      boxShadow: [
        BoxShadow(color: context.brain.shadow, offset: const Offset(0, 3)),
      ],
    ),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
  Widget _color() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Tap the INK color, not the word'),
      const SizedBox(height: 20),
      Text(
        names[colorTrial.wordIndex],
        style: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          color: context.clashColor(colorTrial.colorIndex),
        ),
      ),
      const SizedBox(height: 38),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(4, (i) {
          return ArcadeButton(
            color: context.clashColor(i),
            onPressed: () => _answerColor(i),
            label: '${['●', '◆', '■', '▲'][i]} ${names[i]}',
          );
        }),
      ),
    ],
  );
  Widget _math() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Is this equation correct?'),
      const SizedBox(height: 28),
      Text(
        mathTrial.expression,
        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 42),
      Row(
        children: [
          Expanded(
            child: ArcadeButton(
              expanded: true,
              color: context.brain.success,
              onPressed: () => _answerMath(true),
              icon: Icons.check_rounded,
              label: 'TRUE',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ArcadeButton(
              expanded: true,
              color: context.brain.danger,
              onPressed: () => _answerMath(false),
              icon: Icons.close_rounded,
              label: 'FALSE',
            ),
          ),
        ],
      ),
    ],
  );
  Widget _memory() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        memoryShowing ? 'Remember the glowing tiles' : 'Repeat the pattern',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 20),
      AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, i) {
            final active = memoryShowing
                ? memoryTarget.contains(i)
                : memorySelected.contains(i);
            return Semantics(
              label: 'Memory tile ${i + 1}',
              button: true,
              child: InkWell(
                onTap: () => _tapMemory(i),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).extension<BrainPalette>()!.outline,
                      width: 3,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: .5),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
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
      const Text('Find the target'),
      const SizedBox(height: 8),
      Semantics(
        label: 'Target symbol',
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
            label: 'Search item ${i + 1}',
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
        title: const Text('Leave this round?'),
        content: const Text('Your current round progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LEAVE'),
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
