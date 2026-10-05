import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';

const gameStageKey = Key('game-stage');
const roundCelebrationKey = Key('round-celebration');
const dailyCelebrationKey = Key('daily-celebration');
const stillCelebrationKey = Key('still-celebration');
const completionBadgeKey = Key('completion-badge');

class GameStage extends StatelessWidget {
  const GameStage({
    super.key,
    required this.game,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final GameType game;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final visual = gameVisualFor(game);
    final accent = context.gameAccent(game);
    final highContrast = context.brain.background == Colors.black;
    return Semantics(
      label: visual.sceneLabel,
      container: true,
      child: Container(
        key: gameStageKey,
        decoration: BoxDecoration(
          gradient: highContrast
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(context.brain.surface, accent, .08)!,
                    Color.lerp(context.brain.surfaceHigh, accent, .16)!,
                  ],
                ),
          color: highContrast ? context.brain.surface : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: highContrast ? Colors.white : accent),
          boxShadow: highContrast
              ? const []
              : [
                  BoxShadow(
                    color: context.brain.shadow.withValues(alpha: .18),
                    offset: const Offset(0, 9),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: .12),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _ScenePainter(
                    accent: accent,
                    motif: visual.motif,
                    highContrast: highContrast,
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedHeight) {
                  return Padding(padding: padding, child: child);
                }
                return SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - padding.vertical,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GameDepthPanel extends StatelessWidget {
  const GameDepthPanel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.brain.primary;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.brain.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .75), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .28),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: context.brain.shadow.withValues(alpha: .13),
            offset: const Offset(0, 10),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}

class GameAnswerButton extends StatelessWidget {
  const GameAnswerButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(color),
      foregroundColor: WidgetStatePropertyAll(context.onColor(color)),
      minimumSize: const WidgetStatePropertyAll(Size(88, 54)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
      elevation: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed) ? 1 : 7,
      ),
      shadowColor: WidgetStatePropertyAll(color.withValues(alpha: .58)),
      side: WidgetStatePropertyAll(
        BorderSide(color: context.onColor(color).withValues(alpha: .48)),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(label, textAlign: TextAlign.center),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: buttonStyle,
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum CelebrationLevel { round, daily }

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.level});

  final CelebrationLevel level;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.level == CelebrationLevel.round
          ? const Duration(milliseconds: 900)
          : const Duration(milliseconds: 2200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daily = widget.level == CelebrationLevel.daily;
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      key: daily ? dailyCelebrationKey : roundCelebrationKey,
      child: Semantics(
        label: daily ? 'Daily workout complete' : 'Round complete',
        liveRegion: true,
        container: true,
        child: still
            ? Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  key: stillCelebrationKey,
                  size: daily ? 88 : 64,
                  color: context.brain.reward,
                ),
              )
            : AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final entrance = Curves.easeOutBack.transform(
                    (controller.value / .28).clamp(0, 1),
                  );
                  final exit = ((1 - controller.value) / .22)
                      .clamp(0.0, 1.0)
                      .toDouble();
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConfettiPainter(
                            progress: controller.value,
                            daily: daily,
                            colors: [
                              context.brain.reward,
                              context.brain.primary,
                              context.brain.secondary,
                              context.brain.success,
                              context.brain.danger,
                            ],
                            outlined: context.brain.background == Colors.black,
                          ),
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: math.min(1.0, math.min(entrance, exit)),
                          child: Transform.scale(
                            scale: .72 + entrance * .28,
                            child: Container(
                              key: completionBadgeKey,
                              width: daily ? 112 : 88,
                              height: daily ? 112 : 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.brain.surface,
                                border: Border.all(
                                  color: context.brain.reward,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.brain.reward.withValues(
                                      alpha: .42,
                                    ),
                                    blurRadius: 22,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                daily
                                    ? Icons.emoji_events_rounded
                                    : Icons.check_rounded,
                                size: daily ? 58 : 48,
                                color: context.brain.reward,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.accent,
    required this.motif,
    required this.highContrast,
  });

  final Color accent;
  final GameMotif motif;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: highContrast ? .16 : .09)
      ..style = PaintingStyle.fill;
    final seed = motif.index + 3;
    for (var index = 0; index < 8; index++) {
      final x = ((index * 71 + seed * 37) % 100) / 100 * size.width;
      final y = ((index * 47 + seed * 19) % 100) / 100 * size.height;
      final radius = 5.0 + ((index + seed) % 4) * 3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    final line = Paint()
      ..color = accent.withValues(alpha: highContrast ? .18 : .07)
      ..strokeWidth = 2;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), line);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.motif != motif ||
      oldDelegate.highContrast != highContrast;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.daily,
    required this.colors,
    required this.outlined,
  });

  final double progress;
  final bool daily;
  final List<Color> colors;
  final bool outlined;

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = daily ? 72 : 34;
    final waves = daily ? 3 : 1;
    for (var index = 0; index < particleCount; index++) {
      final wave = index % waves;
      final local = ((progress * waves) - wave).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final fromLeft = index.isEven;
      final origin = Offset(fromLeft ? 18 : size.width - 18, size.height - 20);
      final spread = ((index * 37) % 100) / 100;
      final direction = fromLeft ? 1.0 : -1.0;
      final distance = size.width * (.18 + spread * .68);
      final x = origin.dx + direction * distance * local;
      final rise = size.height * (.34 + spread * .48);
      final y = origin.dy - rise * math.sin(local * math.pi) - local * 30;
      final particle = Paint()
        ..color = colors[index % colors.length]
        ..strokeWidth = 2
        ..style = outlined ? PaintingStyle.stroke : PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * math.pi * (2 + index % 3));
      final width = 5.0 + index % 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: width * 1.8,
          ),
          const Radius.circular(2),
        ),
        particle,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.daily != daily;
}
