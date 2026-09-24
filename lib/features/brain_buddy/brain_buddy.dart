import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import 'buddy_motion.dart';
import 'buddy_painter.dart';

export 'buddy_motion.dart' show BuddyVariant;

class BrainBuddy extends StatefulWidget {
  const BrainBuddy({
    super.key,
    required this.mood,
    required this.level,
    required this.equipped,
    this.size = 220,
    this.reducedMotion = false,
    this.variant = BuddyVariant.stage,
    this.reactionKey = 0,
    this.onTap,
  });

  final BuddyMood mood;
  final int level;
  final Map<String, String> equipped;
  final double size;
  final bool reducedMotion;
  final BuddyVariant variant;
  final int reactionKey;
  final VoidCallback? onTap;

  @override
  State<BrainBuddy> createState() => _BrainBuddyState();
}

class _BrainBuddyState extends State<BrainBuddy> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  late final AnimationController _action = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  BuddyMood? _localMood;
  int _tapIndex = 0;
  int _actionRun = 0;

  BuddyMood get _displayMood => _localMood ?? widget.mood;

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _idle.repeat();
    _playAction();
  }

  @override
  void didUpdateWidget(covariant BrainBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      if (widget.reducedMotion) {
        _idle
          ..stop()
          ..value = 0;
      } else {
        _idle.repeat();
      }
    }
    if (oldWidget.mood != widget.mood ||
        oldWidget.reactionKey != widget.reactionKey) {
      _localMood = null;
      _playAction();
    }
  }

  Future<void> _playAction() async {
    final run = ++_actionRun;
    if (widget.reducedMotion) {
      _action.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      try {
        await _action.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || run != _actionRun || _localMood != null) return;
    if (widget.mood != BuddyMood.idle) {
      setState(() => _localMood = BuddyMood.idle);
    }
  }

  Future<void> _tap() async {
    const reactions = [BuddyMood.tapped, BuddyMood.surprised, BuddyMood.happy];
    setState(() {
      _localMood = reactions[_tapIndex % reactions.length];
      _tapIndex++;
    });
    widget.onTap?.call();
    final run = ++_actionRun;
    if (widget.reducedMotion) {
      _action.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      try {
        await _action.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || run != _actionRun) return;
    setState(
      () => _localMood = widget.mood == BuddyMood.idle ? null : BuddyMood.idle,
    );
  }

  @override
  void dispose() {
    _idle.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final character = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _action]),
        builder: (context, _) {
          final idle = widget.reducedMotion ? 0.0 : _idle.value;
          final action = widget.reducedMotion ? 1.0 : _action.value;
          final pose = BuddyMotion.pose(
            mood: _displayMood,
            idle: idle,
            action: action,
            reducedMotion: widget.reducedMotion,
          );
          return CustomPaint(
            size: Size.square(widget.size),
            painter: BuddyPainter(
              palette: context.brain,
              theme: _theme(context),
              mood: _displayMood,
              pose: pose,
              level: widget.level,
              equipped: widget.equipped,
              variant: widget.variant,
              phase: idle,
            ),
          );
        },
      ),
    );

    final result = Semantics(
      label: _semanticLabel(_displayMood),
      image: !interactive,
      button: interactive,
      child: interactive
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                customBorder: const CircleBorder(),
                focusColor: context.brain.secondary.withValues(alpha: .22),
                hoverColor: context.brain.primary.withValues(alpha: .1),
                onTap: _tap,
                child: character,
              ),
            )
          : character,
    );
    return widget.variant == BuddyVariant.compact
        ? ExcludeSemantics(child: result)
        : result;
  }

  BrainTheme _theme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return BrainTheme.daydream;
    }
    if (context.brain.outline == Colors.white) return BrainTheme.highContrast;
    if (context.brain.background == Colors.black) return BrainTheme.oled;
    return BrainTheme.midnight;
  }

  String _semanticLabel(BuddyMood mood) => switch (mood) {
    BuddyMood.idle => 'Flex the Brain Buddy is ready',
    BuddyMood.blink => 'Flex blinks',
    BuddyMood.wave => 'Flex waves hello',
    BuddyMood.thinking => 'Flex is thinking of an idea',
    BuddyMood.happy => 'Flex is happy',
    BuddyMood.confused => 'Flex pauses to think again',
    BuddyMood.celebrate => 'Flex celebrates',
    BuddyMood.sleepy => 'Flex is resting',
    BuddyMood.returning => 'Flex welcomes you back',
    BuddyMood.energized => 'Flex is energized',
    BuddyMood.levelUp => 'Flex celebrates a new level',
    BuddyMood.streak => 'Flex celebrates your streak',
    BuddyMood.record => 'Flex celebrates a new record',
    BuddyMood.chest => 'Flex opens a reward chest',
    BuddyMood.fullEnergy => 'Flex celebrates full Brain Energy',
    BuddyMood.surprised => 'Flex is pleasantly surprised',
    BuddyMood.tapped => 'Flex gives you a high five',
    BuddyMood.workoutComplete => 'Flex celebrates your completed workout',
  };
}
