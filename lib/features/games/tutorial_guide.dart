import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';

const tutorialHelperHandKey = ValueKey('tutorial-helper-hand');

enum TutorialGuideKind { answer, passive }

class TutorialGuide {
  const TutorialGuide.answer(this.answerIndex)
    : kind = TutorialGuideKind.answer;

  const TutorialGuide.passive()
    : kind = TutorialGuideKind.passive,
      answerIndex = null;

  final TutorialGuideKind kind;
  final int? answerIndex;

  bool pointsTo(int index) =>
      kind == TutorialGuideKind.answer && answerIndex == index;
}

class TutorialGuidedControl extends StatelessWidget {
  const TutorialGuidedControl({
    super.key,
    required this.showGuide,
    required this.child,
    this.passive = false,
  });

  final bool showGuide;
  final Widget child;
  final bool passive;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      if (showGuide)
        Positioned(
          right: -8,
          top: -18,
          child: TutorialHelperHand(passive: passive),
        ),
    ],
  );
}

class TutorialHelperHand extends StatefulWidget {
  const TutorialHelperHand({super.key, this.passive = false});

  final bool passive;

  @override
  State<TutorialHelperHand> createState() => _TutorialHelperHandState();
}

class _TutorialHelperHandState extends State<TutorialHelperHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          key: tutorialHelperHandKey,
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              still ? 0 : 4 * math.sin(_controller.value * math.pi),
            ),
            child: child,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.brain.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.brain.outline, width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.brain.shadow.withValues(alpha: .2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                widget.passive
                    ? Icons.pan_tool_alt_rounded
                    : Icons.touch_app_rounded,
                size: 26,
                color: context.brain.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
