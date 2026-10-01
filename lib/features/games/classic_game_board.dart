import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/common.dart';
import 'game_engine.dart';
import 'tutorial_guide.dart';

const colorNames = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
const colorAnswerLabels = ['● RED', '◆ BLUE', '■ GREEN', '▲ YELLOW'];

class ColorClashBoard extends StatelessWidget {
  const ColorClashBoard({
    super.key,
    required this.trial,
    required this.onAnswer,
    this.guide,
  });

  final ColorTrial trial;
  final ValueChanged<int> onAnswer;
  final TutorialGuide? guide;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(gameContent[GameType.colorClash]!.instructions),
        const SizedBox(height: 20),
        Semantics(
          label: AppText.colorStimulus(
            colorNames[trial.wordIndex],
            colorNames[trial.colorIndex],
          ),
          child: Text(
            colorNames[trial.wordIndex],
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: context.clashColor(trial.colorIndex),
            ),
          ),
        ),
        const SizedBox(height: 30),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2 / textScale,
          children: List.generate(
            4,
            (index) => TutorialGuidedControl(
              showGuide: guide?.pointsTo(index) ?? false,
              child: PrimaryAction(
                expanded: true,
                color: context.clashColor(index),
                onPressed: () => onAnswer(index),
                label: colorAnswerLabels[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MathBlitzBoard extends StatelessWidget {
  const MathBlitzBoard({
    super.key,
    required this.trial,
    required this.onAnswer,
    this.guide,
  });

  final MathTrial trial;
  final ValueChanged<bool> onAnswer;
  final TutorialGuide? guide;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(gameContent[GameType.mathBlitz]!.instructions),
      const SizedBox(height: 28),
      Semantics(
        label: AppText.gameStimulus(trial.expression),
        child: Text(
          trial.expression,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 34),
      Row(
        children: [
          Expanded(
            child: TutorialGuidedControl(
              showGuide: guide?.pointsTo(0) ?? false,
              child: PrimaryAction(
                expanded: true,
                color: context.brain.success,
                onPressed: () => onAnswer(true),
                icon: Icons.check_rounded,
                label: AppText.gameplay.trueLabel,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TutorialGuidedControl(
              showGuide: guide?.pointsTo(1) ?? false,
              child: PrimaryAction(
                expanded: true,
                color: context.brain.danger,
                onPressed: () => onAnswer(false),
                icon: Icons.close_rounded,
                label: AppText.gameplay.falseLabel,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
