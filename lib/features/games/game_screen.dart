import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/demo_ads.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.type,
    required this.mode,
    required this.difficulty,
    this.personalBest,
    this.modifier,
  });
  final GameType type;
  final GameMode mode;
  final int difficulty;
  final GameResult? personalBest;
  final String? modifier;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final Random random;
  final stopwatch = Stopwatch();
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
  int wordIndex = 0, colorIndex = 1;
  String expression = '';
  bool mathAnswer = true;
  int oddIndex = 0, itemCount = 12;
  int memoryRound = 0, gridSize = 4;
  Set<int> memoryTarget = {}, memorySelected = {};
  bool memoryShowing = true;
  int reflexTrial = 0, falseStarts = 0;
  bool secondChanceUsed = false, secondChancePromptOpen = false;
  bool reflexGo = false;
  final reactions = <int>[];
  DateTime? goAt;
  static const colors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.amber,
  ];
  static const names = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    random = Random(
      stableSeed(
        '${DateTime.now().microsecondsSinceEpoch}|${widget.type.name}',
      ),
    );
    timeLeft = widget.modifier == 'Lightning' ? 24 : 30;
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
      case GameType.oddOneOut:
        _nextOdd();
    }
    _startTimer();
  }

  bool get timed =>
      widget.mode != GameMode.endless &&
      widget.mode != GameMode.zen &&
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
    wordIndex = random.nextInt(4);
    do {
      colorIndex = random.nextInt(4);
    } while (colorIndex == wordIndex && random.nextBool());
  }

  void _answerColor(int value) {
    _answer(value == colorIndex);
    _nextColor();
  }

  void _nextMath() {
    final d = widget.difficulty,
        a = random.nextInt(8 + d * 4) + 1,
        b = random.nextInt(8 + d * 3) + 1;
    final op = d < 3
        ? '+'
        : d < 5
        ? (random.nextBool() ? '+' : '−')
        : (random.nextBool() ? '×' : '−');
    final actual = op == '+'
        ? a + b
        : op == '−'
        ? a - b
        : a * b;
    mathAnswer = random.nextBool();
    final shown = mathAnswer
        ? actual
        : actual + (random.nextBool() ? 1 : -1) * (1 + random.nextInt(3));
    expression = '$a $op $b = $shown';
  }

  void _answerMath(bool value) {
    _answer(value == mathAnswer);
    _nextMath();
  }

  void _nextOdd() {
    itemCount = min(30, 9 + widget.difficulty * 3);
    oddIndex = random.nextInt(itemCount);
  }

  void _answerOdd(int value) {
    _answer(value == oddIndex);
    _nextOdd();
  }

  void _answer(bool ok) {
    attempts++;
    if (ok) {
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
      if (widget.modifier == 'Combo' && combo >= 5) multiplier += .5;
      score += (1 * multiplier).round();
      _feedback(true);
    } else {
      combo = 0;
      mistakes++;
      score = max(0, score - (widget.modifier == 'Precision' ? 2 : 1));
      _feedback(false);
    }
    if (widget.mode == GameMode.endless && mistakes >= 3) {
      if (secondChanceUsed) {
        _finish();
      } else if (!secondChancePromptOpen) {
        _offerSecondChance();
      }
    }
    setState(() {});
  }

  void _nextMemory() {
    final roundTarget = widget.modifier == 'Memory Madness' ? 4 : 3;
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
      goAt = DateTime.now();
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
    final ms = DateTime.now().difference(goAt!).inMilliseconds;
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
    final pace = widget.type == GameType.reflexTap
        ? (reactions.isEmpty
                      ? 0.0
                      : (650 -
                                (reactions.reduce((a, b) => a + b) /
                                    reactions.length)) /
                            4)
                  .clamp(0, 100) /
              100
        : min(1.0, correct / max(1, stopwatch.elapsedMilliseconds / 3000));
    final normalized = (accuracy * 70 + pace * 30 - falseStarts * 5)
        .clamp(0, 100)
        .toDouble();
    final sorted = [...reactions]..sort();
    final reaction = sorted.isEmpty ? null : sorted[sorted.length ~/ 2];
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
              Text(
                result.normalized >= 80 ? 'Brilliant!' : 'Round complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${result.score}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Score · ${(result.accuracy * 100).round()}% accuracy${result.reactionMs == null ? '' : ' · ${result.reactionMs} ms'}',
              ),
              if (widget.personalBest != null) ...[
                const SizedBox(height: 8),
                Text('Personal best: ${widget.personalBest!.score}'),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pop(context, result);
                },
                child: const Text('CONTINUE'),
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
            if (timed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$timeLeft s',
                  style: const TextStyle(fontWeight: FontWeight.w900),
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

  Widget _paused() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline, size: 72),
        const Text('Paused'),
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
  Widget _game() => Padding(
    key: ValueKey(widget.type),
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          children: [
            _pill('Score $score'),
            const Spacer(),
            _pill('Combo $combo'),
            if (widget.personalBest != null) ...[
              const SizedBox(width: 8),
              _pill('PB ${widget.personalBest!.score}'),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: switch (widget.type) {
            GameType.colorClash => _color(),
            GameType.mathBlitz => _math(),
            GameType.memoryTiles => _memory(),
            GameType.reflexTap => _reflex(),
            GameType.oddOneOut => _odd(),
          },
        ),
        if (widget.mode == GameMode.zen)
          TextButton(
            onPressed: _finish,
            child: const Text('Finish zen session'),
          ),
      ],
    ),
  );
  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
  Widget _color() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Tap the INK color, not the word'),
      const SizedBox(height: 20),
      Text(
        names[wordIndex],
        style: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          color: colors[colorIndex],
        ),
      ),
      const SizedBox(height: 38),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(4, (position) {
          final i = widget.modifier == 'Reverse' ? 3 - position : position;
          return FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors[i],
              foregroundColor: i == 3 ? Colors.black : Colors.white,
            ),
            onPressed: () => _answerColor(i),
            child: Text('${['●', '◆', '■', '▲'][i]} ${names[i]}'),
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
        expression,
        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 42),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => _answerMath(true),
              child: const Text('TRUE'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => _answerMath(false),
              child: const Text('FALSE'),
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
  Widget _odd() => Column(
    children: [
      const Text('Find the different symbol'),
      const SizedBox(height: 16),
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
          itemBuilder: (context, i) => InkWell(
            onTap: () => _answerOdd(i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: i == oddIndex ? .25 : 0,
                child: Text(
                  i == oddIndex ? '◉' : '●',
                  style: TextStyle(
                    fontSize: itemCount > 20 ? 24 : 32,
                    color: i == oddIndex && widget.difficulty > 5
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
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

  Future<void> _offerSecondChance() async {
    secondChancePromptOpen = true;
    final wantsAd = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Three mistakes'),
        content: const Text(
          'Finish this run, or explicitly choose a Demo Ad for one second chance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('FINISH'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DEMO SECOND CHANCE'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (wantsAd == true &&
        await showRewardedDemo(context, reward: 'Continue this Endless run')) {
      mistakes = 2;
      secondChanceUsed = true;
      secondChancePromptOpen = false;
      setState(() {});
    } else {
      _finish();
    }
  }

  void _feedback(bool positive) {
    final cubit = context.read<BrainCubit>();
    if (cubit.data.sound) {
      SystemSound.play(SystemSoundType.click);
    }
    if (cubit.data.haptics) {
      positive ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    }
  }
}
