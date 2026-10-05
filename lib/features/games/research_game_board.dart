import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/config/app_config.dart';
import 'research_game_engine.dart';
import 'game_experience.dart';
import 'tutorial_guide.dart';

class ResearchGameBoard extends StatelessWidget {
  const ResearchGameBoard({
    super.key,
    required this.type,
    required this.difficulty,
    required this.trial,
    required this.showingStimulus,
    required this.trialNumber,
    required this.onAnswer,
    this.guide,
  });

  final GameType type;
  final int difficulty;
  final ResearchTrial trial;
  final bool showingStimulus;
  final int trialNumber;
  final ValueChanged<int> onAnswer;
  final TutorialGuide? guide;

  @override
  Widget build(BuildContext context) {
    final isStop = trial.condition == 'stop';
    final revealOptions = !showingStimulus && !isStop;
    return GameStage(
      game: type,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: AppText.gameStimulus(
              showingStimulus ? trial.prompt : trial.cue,
            ),
            child: GameDepthPanel(
              accent: context.gameAccent(type),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 150),
                child: Center(child: _stimulus(context)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isStop && !showingStimulus)
            TutorialGuidedControl(
              showGuide: guide?.kind == TutorialGuideKind.passive,
              passive: true,
              child: Text(
                AppText.gameplay.keepWaiting,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (isStop)
            TutorialGuidedControl(
              showGuide:
                  guide?.kind == TutorialGuideKind.passive ||
                  (guide?.pointsTo(0) ?? false),
              passive: guide?.kind == TutorialGuideKind.passive,
              child: GameAnswerButton(
                color: context.brain.danger,
                onPressed: () => onAnswer(0),
                label: AppText.gameplay.tap,
              ),
            )
          else if (revealOptions || trial.exposureMs == 0)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                trial.options.length,
                (index) => Semantics(
                  label: AppText.answerOption(index + 1),
                  button: true,
                  child: TutorialGuidedControl(
                    showGuide: guide?.pointsTo(index) ?? false,
                    child: SizedBox(
                      width: 145,
                      child: GameAnswerButton(
                        expanded: true,
                        color: context.gameAccent(type),
                        onPressed: () => onAnswer(index),
                        label: trial.options[index],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(AppText.gameplay.study),
        ],
      ),
    );
  }

  Widget _stimulus(BuildContext context) {
    final visual = trial.visual;
    if (visual is SignalVisual) {
      return _SignalConsole(stop: visual.stop, waiting: showingStimulus);
    }
    if (visual is TrackingVisual) {
      return _TrackingField(
        key: ValueKey('$trialNumber-${trial.prompt}'),
        targetCount: trial.span,
        accent: context.gameAccent(type),
        movement: trial.movement,
        revealFinal: !showingStimulus,
      );
    }
    if (visual is MemoryGridVisual) {
      final values = showingStimulus ? visual.before : visual.after;
      final count = difficulty >= 7 ? 16 : 9;
      return _MemoryBoard(
        values: values,
        count: count,
        accent: context.gameAccent(type),
      );
    }
    if (visual is TowerVisual) {
      return _TowerBoard(
        pegs: visual.pegs,
        target: visual.target,
        accent: context.gameAccent(type),
      );
    }
    if (visual is PeripheralVisual && showingStimulus) {
      return _PeripheralConsole(
        shape: visual.shape,
        direction: visual.direction,
        accent: context.gameAccent(type),
      );
    }
    if (visual is PositionVisual) {
      return _PositionBoard(
        position: visual.position,
        n: visual.n,
        accent: context.gameAccent(type),
      );
    }
    if (visual is RuleVisual) {
      return _RuleToken(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is ArrowVisual) {
      return _ArrowLane(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is PairVisual) {
      return _PairCards(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is SymbolKeyVisual) {
      return _SymbolConsole(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is DualTaskVisual) {
      return _DualConsole(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is SeriesVisual) {
      return _SeriesTrack(visual: visual, accent: context.gameAccent(type));
    }
    if (visual is RotationVisual) {
      return _RotationBoard(visual: visual, accent: context.gameAccent(type));
    }
    final text = showingStimulus || trial.exposureMs == 0
        ? trial.prompt
        : trial.cue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trial.cue.isNotEmpty && trial.exposureMs == 0)
          Text(trial.cue, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MemoryBoard extends StatelessWidget {
  const _MemoryBoard({
    required this.values,
    required this.count,
    required this.accent,
  });

  final Set<int> values;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 190,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count == 16 ? 4 : 3,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final active = values.contains(index + 1);
        return Semantics(
          label: AppText.tileSemantics(index + 1, active),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [Color.lerp(accent, Colors.white, .35)!, accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: active ? null : context.brain.hud,
              border: Border.all(
                color: active ? accent : context.brain.outline,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? accent.withValues(alpha: .42)
                      : context.brain.shadow.withValues(alpha: .12),
                  offset: const Offset(0, 4),
                  blurRadius: active ? 8 : 0,
                ),
              ],
            ),
            child: active
                ? Icon(
                    Icons.brightness_1_rounded,
                    color: context.onColor(accent),
                    size: 16,
                  )
                : Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        );
      },
    ),
  );
}

class _SignalConsole extends StatelessWidget {
  const _SignalConsole({required this.stop, required this.waiting});
  final bool stop;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final active = waiting
        ? context.brain.warning
        : stop
        ? context.brain.danger
        : context.brain.success;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.brain.shadow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.brain.outline, width: 2),
            boxShadow: [
              BoxShadow(color: active.withValues(alpha: .42), blurRadius: 18),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < 3; index++) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index ==
                            (waiting
                                ? 1
                                : stop
                                ? 0
                                : 2)
                        ? active
                        : Colors.white.withValues(alpha: .12),
                    border: Border.all(color: Colors.white54),
                  ),
                ),
                if (index < 2) const SizedBox(height: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          waiting
              ? 'READY'
              : stop
              ? 'STOP'
              : 'GO',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: active,
          ),
        ),
      ],
    );
  }
}

class _PeripheralConsole extends StatelessWidget {
  const _PeripheralConsole({
    required this.shape,
    required this.direction,
    required this.accent,
  });
  final int shape;
  final int direction;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 150,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(106),
          painter: _RadarPainter(accent),
        ),
        _ShapeToken(id: shape, color: accent, size: 52),
        Align(
          alignment: const [
            Alignment.topCenter,
            Alignment.centerRight,
            Alignment.bottomCenter,
            Alignment.centerLeft,
          ][direction],
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.brain.reward,
              border: Border.all(color: context.brain.text, width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.brain.reward.withValues(alpha: .5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PositionBoard extends StatelessWidget {
  const _PositionBoard({
    required this.position,
    required this.n,
    required this.accent,
  });
  final int position;
  final int n;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: context.brain.shadow.withValues(alpha: .84),
          borderRadius: BorderRadius.circular(18),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: index == position
                  ? accent
                  : Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: index == position ? Colors.white : Colors.white24,
              ),
              boxShadow: index == position
                  ? [BoxShadow(color: accent, blurRadius: 10)]
                  : null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text('$n-BACK', style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _RuleToken extends StatelessWidget {
  const _RuleToken({required this.visual, required this.accent});
  final RuleVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.brain.reward,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'RULE: ${visual.useShape ? 'SHAPE' : 'COLOR'}',
          style: TextStyle(
            color: context.onColor(context.brain.reward),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _ShapeToken(
        id: visual.shape,
        color: visual.color == 0
            ? context.brain.danger
            : context.brain.secondary,
        size: 78,
      ),
    ],
  );
}

class _ArrowLane extends StatelessWidget {
  const _ArrowLane({required this.visual, required this.accent});
  final ArrowVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final center = index == 2;
        final right = center || visual.congruent ? visual.right : !visual.right;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: center ? 52 : 40,
          height: center ? 58 : 46,
          decoration: BoxDecoration(
            gradient: center
                ? LinearGradient(
                    colors: [Color.lerp(accent, Colors.white, .3)!, accent],
                  )
                : null,
            color: center ? null : context.brain.hud,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: center ? accent : context.brain.outline,
              width: center ? 2 : 1,
            ),
            boxShadow: center
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .36),
                      offset: const Offset(0, 5),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            right ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            size: center ? 34 : 26,
            color: center ? context.onColor(accent) : context.brain.textMuted,
          ),
        );
      }),
    ),
  );
}

class _PairCards extends StatelessWidget {
  const _PairCards({required this.visual, required this.accent});
  final PairVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TokenCard(id: visual.left, accent: accent),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            visual.recall ? Icons.link_rounded : Icons.add_rounded,
            size: 32,
            color: accent,
          ),
        ),
        visual.partner == null
            ? _MysteryCard(accent: accent)
            : _TokenCard(id: visual.partner!, accent: accent),
      ],
    ),
  );
}

class _SymbolConsole extends StatelessWidget {
  const _SymbolConsole({required this.visual, required this.accent});
  final SymbolKeyVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        spacing: 8,
        children: List.generate(
          4,
          (index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: context.brain.hud,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.brain.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShapeToken(id: index, color: accent, size: 24),
                const SizedBox(width: 5),
                Text(
                  '= ${visual.values[index]}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      _TokenCard(id: visual.target, accent: accent, large: true),
    ],
  );
}

class _DualConsole extends StatelessWidget {
  const _DualConsole({required this.visual, required this.accent});
  final DualTaskVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    runAlignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      _ConsoleTile(
        child: Text(
          '${visual.value}',
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 46,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      _ConsoleTile(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            visual.stars,
            (_) =>
                Icon(Icons.star_rounded, color: context.brain.reward, size: 28),
          ),
        ),
      ),
    ],
  );
}

class _SeriesTrack extends StatelessWidget {
  const _SeriesTrack({required this.visual, required this.accent});
  final SeriesVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 5,
    children: [
      for (final (index, value) in visual.values.indexed) ...[
        Container(
          width: 43,
          height: 43 + index * 6,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.lerp(accent, Colors.white, .3)!, accent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .3),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: context.onColor(accent),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
      _MysteryCard(accent: accent, compact: true),
    ],
  );
}

class _RotationBoard extends StatelessWidget {
  const _RotationBoard({required this.visual, required this.accent});
  final RotationVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(82, 82),
              painter: _CubeClusterPainter(
                accent: accent,
                mirrored: false,
                quarterTurns: 0,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.compare_arrows_rounded),
            ),
            CustomPaint(
              size: const Size(82, 82),
              painter: _CubeClusterPainter(
                accent: accent,
                mirrored: !visual.same,
                quarterTurns: visual.angle ~/ 90,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'ROTATED ${visual.angle}°',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _TowerBoard extends StatelessWidget {
  const _TowerBoard({
    required this.pegs,
    required this.target,
    required this.accent,
  });

  final List<List<int>> pegs;
  final int target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'BUILD ON PEG ${target + 1}',
        style: TextStyle(
          color: accent,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (peg) {
            final disks = pegs[peg];
            final targetPeg = peg == target;
            return Expanded(
              child: Semantics(
                label: AppText.pegSemantics(peg + 1, targetPeg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final disk in disks.reversed)
                      Container(
                        width: 30.0 + disk * 22,
                        height: 18,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(accent, Colors.white, .42)!,
                              accent,
                              Color.lerp(accent, Colors.black, .2)!,
                            ],
                          ),
                          border: Border.all(color: context.brain.outline),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .28),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: 7,
                      height: 25,
                      decoration: BoxDecoration(
                        color: targetPeg
                            ? context.brain.reward
                            : context.brain.outline,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 8,
                      decoration: BoxDecoration(
                        color: targetPeg
                            ? context.brain.reward
                            : context.brain.outline,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${peg + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    ],
  );
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({
    required this.id,
    required this.accent,
    this.large = false,
  });
  final int id;
  final Color accent;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    width: large ? 82 : 68,
    height: large ? 92 : 78,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          context.brain.surface,
          Color.lerp(context.brain.surface, accent, .16)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent, width: 2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .3),
          offset: const Offset(0, 6),
          blurRadius: 3,
        ),
      ],
    ),
    child: _ShapeToken(id: id, color: accent, size: large ? 48 : 40),
  );
}

class _MysteryCard extends StatelessWidget {
  const _MysteryCard({required this.accent, this.compact = false});
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 46 : 68,
    height: compact ? 52 : 78,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.brain.hud,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent, width: 2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .25),
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Text(
      '?',
      style: TextStyle(
        fontFamily: 'Fredoka',
        color: accent,
        fontSize: compact ? 28 : 38,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ConsoleTile extends StatelessWidget {
  const _ConsoleTile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 100,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: context.brain.hud,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.brain.outline, width: 2),
      boxShadow: [
        BoxShadow(
          color: context.brain.shadow.withValues(alpha: .22),
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _ShapeToken extends StatelessWidget {
  const _ShapeToken({
    required this.id,
    required this.color,
    required this.size,
  });
  final int id;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ShapeTokenPainter(id: id, color: color),
  );
}

class _ShapeTokenPainter extends CustomPainter {
  const _ShapeTokenPainter({required this.id, required this.color});
  final int id;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shadow = Paint()..color = Colors.black.withValues(alpha: .25);
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(color, Colors.white, .42)!,
          color,
          Color.lerp(color, Colors.black, .18)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    final path = _tokenPath(id, rect.deflate(size.width * .08));
    canvas.save();
    canvas.translate(0, size.width * .09);
    canvas.drawPath(path, shadow);
    canvas.restore();
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Path _tokenPath(int value, Rect rect) {
    switch (value % 8) {
      case 0:
        return Path()..addOval(rect);
      case 1:
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case 2:
        return Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.width * .18)),
        );
      case 3:
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case 4:
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.top + rect.height * .35)
          ..lineTo(rect.right - rect.width * .2, rect.bottom)
          ..lineTo(rect.left + rect.width * .2, rect.bottom)
          ..lineTo(rect.left, rect.top + rect.height * .35)
          ..close();
      case 5:
        return Path()
          ..moveTo(rect.left, rect.center.dy)
          ..quadraticBezierTo(
            rect.left,
            rect.top,
            rect.center.dx,
            rect.top + rect.height * .24,
          )
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.center.dy)
          ..quadraticBezierTo(
            rect.right,
            rect.bottom * .78,
            rect.center.dx,
            rect.bottom,
          )
          ..quadraticBezierTo(
            rect.left,
            rect.bottom * .78,
            rect.left,
            rect.center.dy,
          )
          ..close();
      case 6:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: rect.center,
                width: rect.width * .42,
                height: rect.height,
              ),
              Radius.circular(rect.width * .2),
            ),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: rect.center,
                width: rect.width,
                height: rect.height * .42,
              ),
              Radius.circular(rect.width * .2),
            ),
          );
      default:
        final path = Path();
        for (var index = 0; index < 10; index++) {
          final radius = index.isEven ? rect.width / 2 : rect.width / 4;
          final angle = -1.5708 + index * .6283;
          final point = Offset(
            rect.center.dx + radius * math.cos(angle),
            rect.center.dy + radius * math.sin(angle),
          );
          index == 0
              ? path.moveTo(point.dx, point.dy)
              : path.lineTo(point.dx, point.dy);
        }
        return path..close();
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeTokenPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.color != color;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color.withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final factor in [.32, .62, .94]) {
      canvas.drawCircle(center, size.width * factor / 2, paint);
    }
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CubeClusterPainter extends CustomPainter {
  const _CubeClusterPainter({
    required this.accent,
    required this.mirrored,
    required this.quarterTurns,
  });
  final Color accent;
  final bool mirrored;
  final int quarterTurns;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(quarterTurns * 1.5708);
    if (mirrored) canvas.scale(-1, 1);
    const cells = [(0, 0), (1, 0), (0, 1), (-1, 1)];
    for (final cell in cells) {
      _cube(canvas, Offset(cell.$1 * 21.0 - 10, cell.$2 * 18.0 - 20));
    }
    canvas.restore();
  }

  void _cube(Canvas canvas, Offset origin) {
    final top = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + 11, origin.dy - 6)
      ..lineTo(origin.dx + 22, origin.dy)
      ..lineTo(origin.dx + 11, origin.dy + 6)
      ..close();
    final left = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + 11, origin.dy + 6)
      ..lineTo(origin.dx + 11, origin.dy + 21)
      ..lineTo(origin.dx, origin.dy + 15)
      ..close();
    final right = Path()
      ..moveTo(origin.dx + 11, origin.dy + 6)
      ..lineTo(origin.dx + 22, origin.dy)
      ..lineTo(origin.dx + 22, origin.dy + 15)
      ..lineTo(origin.dx + 11, origin.dy + 21)
      ..close();
    canvas.drawPath(
      top,
      Paint()..color = Color.lerp(accent, Colors.white, .38)!,
    );
    canvas.drawPath(left, Paint()..color = accent);
    canvas.drawPath(
      right,
      Paint()..color = Color.lerp(accent, Colors.black, .22)!,
    );
  }

  @override
  bool shouldRepaint(covariant _CubeClusterPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.quarterTurns != quarterTurns;
}

class _TrackingField extends StatefulWidget {
  const _TrackingField({
    super.key,
    required this.targetCount,
    required this.accent,
    required this.movement,
    required this.revealFinal,
  });

  final int targetCount;
  final Color accent;
  final List<int> movement;
  final bool revealFinal;

  @override
  State<_TrackingField> createState() => _TrackingFieldState();
}

class _TrackingFieldState extends State<_TrackingField> {
  bool moved = false;
  bool showTargets = true;
  Timer? labelTimer;

  static const starts = <Alignment>[
    Alignment(-.9, -.75),
    Alignment(-.2, -.85),
    Alignment(.65, -.65),
    Alignment(-.65, .45),
    Alignment(.1, .75),
    Alignment(.85, .35),
  ];
  static const ends = <Alignment>[
    Alignment(.55, .65),
    Alignment(.85, -.2),
    Alignment(-.7, .7),
    Alignment(.2, -.75),
    Alignment(-.9, -.3),
    Alignment(-.05, .15),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.revealFinal) {
      moved = true;
      showTargets = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => moved = true);
    });
    labelTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => showTargets = false);
    });
  }

  @override
  void dispose() {
    labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Stack(
        children: List.generate(6, (index) {
          final target = index < widget.targetCount;
          return AnimatedAlign(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            alignment: moved ? ends[widget.movement[index]] : starts[index],
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: showTargets && target
                      ? [
                          Color.lerp(widget.accent, Colors.white, .5)!,
                          widget.accent,
                          Color.lerp(widget.accent, Colors.black, .2)!,
                        ]
                      : [
                          Color.lerp(
                            context.brain.surfaceHigh,
                            Colors.white,
                            .18,
                          )!,
                          context.brain.surfaceHigh,
                          Color.lerp(
                            context.brain.surfaceHigh,
                            Colors.black,
                            .12,
                          )!,
                        ],
                ),
                border: Border.all(color: context.brain.outline, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: showTargets && target
                        ? widget.accent.withValues(alpha: .5)
                        : context.brain.shadow.withValues(alpha: .2),
                    offset: const Offset(0, 4),
                    blurRadius: showTargets && target ? 9 : 2,
                  ),
                ],
              ),
              child: widget.revealFinal
                  ? Text(
                      String.fromCharCode(65 + widget.movement[index]),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    )
                  : showTargets
                  ? Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
