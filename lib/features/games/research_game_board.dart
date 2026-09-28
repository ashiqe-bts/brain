import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import '../../core/widgets/common.dart';
import 'research_game_engine.dart';

class ResearchGameBoard extends StatelessWidget {
  const ResearchGameBoard({
    super.key,
    required this.type,
    required this.difficulty,
    required this.trial,
    required this.showingStimulus,
    required this.trialNumber,
    required this.onAnswer,
  });

  final GameType type;
  final int difficulty;
  final ResearchTrial trial;
  final bool showingStimulus;
  final int trialNumber;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final isStop = trial.condition == 'stop';
    final revealOptions = !showingStimulus && !isStop;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label:
              'Research game stimulus: ${showingStimulus ? trial.prompt : trial.cue}',
          child: BrainCard(
            style: GamePanelStyle.inset,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 150),
              child: Center(child: _stimulus(context)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (isStop && !showingStimulus)
          const Text(
            'Keep waiting…',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          )
        else if (isStop)
          ArcadeButton(
            color: context.brain.danger,
            onPressed: () => onAnswer(0),
            label: 'TAP',
          )
        else if (revealOptions || trial.exposureMs == 0)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              trial.options.length,
              (index) => Semantics(
                label: 'Answer option ${index + 1}',
                button: true,
                child: SizedBox(
                  width: 145,
                  child: ArcadeButton(
                    expanded: true,
                    color: context.gameAccent(type),
                    onPressed: () => onAnswer(index),
                    label: trial.options[index],
                  ),
                ),
              ),
            ),
          )
        else
          const Text('Study…'),
      ],
    );
  }

  Widget _stimulus(BuildContext context) {
    if (type == GameType.signalStop && showingStimulus) {
      return const Text(
        'WAIT…',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
      );
    }
    if (type == GameType.objectTracker) {
      return _TrackingField(
        key: ValueKey('$trialNumber-${trial.prompt}'),
        targetCount: trial.span,
        accent: context.gameAccent(type),
        movement: trial.movement,
        revealFinal: !showingStimulus,
      );
    }
    if (type == GameType.memoryTiles) {
      final values = (showingStimulus ? trial.prompt : trial.cue)
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(int.parse)
          .toSet();
      final count = difficulty >= 7 ? 16 : 9;
      return SizedBox(
        width: 190,
        height: 190,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count == 16 ? 4 : 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final active = values.contains(index + 1);
            return Semantics(
              label: 'Tile ${index + 1}${active ? ', marked' : ''}',
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? context.gameAccent(type)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: context.brain.outline, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: active
                    ? Icon(
                        Icons.star_rounded,
                        color: context.onColor(context.gameAccent(type)),
                      )
                    : Text('${index + 1}'),
              ),
            );
          },
        ),
      );
    }
    if (type == GameType.towerPlanner) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trial.prompt, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(3, (peg) {
                final disks = trial.towerPegs[peg];
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final disk in disks.reversed)
                        Container(
                          width: 28.0 + disk * 22,
                          height: 18,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: context.gameAccent(type),
                            border: Border.all(color: context.brain.outline),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      Container(
                        width: 4,
                        height: 18,
                        color: context.brain.outline,
                      ),
                      Text(
                        'Peg ${peg + 1}${peg == trial.towerTarget ? ' · goal' : ''}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }
    if (type == GameType.peripheralFocus && showingStimulus) {
      final parts = trial.prompt.split('|');
      return SizedBox(
        width: 220,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(parts.first, style: const TextStyle(fontSize: 44)),
            Align(
              alignment: switch (parts.last) {
                'TOP' => Alignment.topCenter,
                'RIGHT' => Alignment.centerRight,
                'BOTTOM' => Alignment.bottomCenter,
                _ => Alignment.centerLeft,
              },
              child: const Icon(Icons.circle, size: 18),
            ),
          ],
        ),
      );
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
      width: 240,
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
                color: showTargets && target
                    ? widget.accent
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: context.brain.outline, width: 2),
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
