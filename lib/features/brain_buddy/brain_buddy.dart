import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/brain_models.dart';
import '../../app/theme/brain_theme.dart';

class BrainBuddy extends StatefulWidget {
  const BrainBuddy({
    super.key,
    required this.mood,
    required this.level,
    required this.equipped,
    this.size = 190,
    this.reducedMotion = false,
    this.onTap,
  });
  final BuddyMood mood;
  final int level;
  final Map<String, String> equipped;
  final double size;
  final bool reducedMotion;
  final VoidCallback? onTap;
  @override
  State<BrainBuddy> createState() => _BrainBuddyState();
}

class _BrainBuddyState extends State<BrainBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Flex the Brain Buddy is ${widget.mood.name}',
    button: true,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final t = widget.reducedMotion ? 0.0 : c.value;
          return Transform.translate(
            offset: Offset(0, -4 * math.sin(t * math.pi)),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _BuddyPainter(
                context.brain,
                widget.mood,
                widget.level,
                widget.equipped,
                t,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter(this.p, this.mood, this.level, this.equipped, this.t);
  final BrainPalette p;
  final BuddyMood mood;
  final int level;
  final Map<String, String> equipped;
  final double t;
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2, cy = s.height * .48;
    final glow = Paint()
      ..color = p.primary.withValues(alpha: .16 + .08 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(cx, cy), s.width * .39, glow);
    if (level >= 35 || equipped['effect'] != 'None') {
      final dots = Paint()..color = p.secondary;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + t;
        canvas.drawCircle(
          Offset(
            cx + math.cos(a) * s.width * .43,
            cy + math.sin(a) * s.width * .34,
          ),
          2 + (i % 3).toDouble(),
          dots,
        );
      }
    }
    final brain = Paint()..color = const Color(0xFFFF78C8);
    final outline = Paint()
      ..color = const Color(0xFF702D78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final body = Path()
      ..moveTo(cx, cy + s.height * .28)
      ..cubicTo(
        cx - s.width * .32,
        cy + s.height * .28,
        cx - s.width * .38,
        cy - s.height * .07,
        cx - s.width * .25,
        cy - s.height * .2,
      )
      ..cubicTo(
        cx - s.width * .15,
        cy - s.height * .38,
        cx,
        cy - s.height * .3,
        cx,
        cy - s.height * .22,
      )
      ..cubicTo(
        cx + s.width * .1,
        cy - s.height * .36,
        cx + s.width * .31,
        cy - s.height * .3,
        cx + s.width * .29,
        cy - s.height * .13,
      )
      ..cubicTo(
        cx + s.width * .43,
        cy,
        cx + s.width * .3,
        cy + s.height * .29,
        cx,
        cy + s.height * .28,
      )
      ..close();
    canvas.drawPath(body, brain);
    canvas.drawPath(body, outline);
    final fold = Paint()
      ..color = const Color(0xFFC84C9F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final off in [-.17, 0, .17]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx + s.width * off, cy - s.height * .05),
          width: s.width * .18,
          height: s.height * .26,
        ),
        -.7,
        3.6,
        false,
        fold,
      );
    }
    final eyeY = cy + s.height * .03;
    for (final x in [cx - s.width * .11, cx + s.width * .11]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, eyeY),
          width: s.width * .12,
          height: s.height * .15,
        ),
        Paint()..color = Colors.white,
      );
      final dx = mood == BuddyMood.confused ? (x < cx ? -2 : 2) : 0.0;
      canvas.drawCircle(
        Offset(x + dx, eyeY + 2),
        s.width * .033,
        Paint()..color = const Color(0xFF1A1733),
      );
    }
    final mouth = Paint()
      ..color = const Color(0xFF702D78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final happy = {
      BuddyMood.happy,
      BuddyMood.celebrate,
      BuddyMood.levelUp,
      BuddyMood.record,
      BuddyMood.workoutComplete,
      BuddyMood.fullEnergy,
    }.contains(mood);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy + s.height * .14),
        width: s.width * .16,
        height: s.height * .09,
      ),
      happy ? 0 : math.pi,
      happy ? math.pi : -math.pi,
      false,
      mouth,
    );
    final limb = Paint()
      ..color = const Color(0xFF702D78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - s.width * .22, cy + s.height * .18),
      Offset(cx - s.width * .29, cy + s.height * .36),
      limb,
    );
    canvas.drawLine(
      Offset(cx + s.width * .22, cy + s.height * .18),
      Offset(cx + s.width * .29, cy + s.height * .36),
      limb,
    );
    canvas.drawLine(
      Offset(cx - s.width * .27, cy + s.height * .36),
      Offset(cx - s.width * .36, cy + s.height * .36),
      Paint()
        ..color = p.secondary
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + s.width * .27, cy + s.height * .36),
      Offset(cx + s.width * .36, cy + s.height * .36),
      Paint()
        ..color = p.secondary
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    final glasses = equipped['glasses'];
    if (level >= 5 || glasses != null && glasses != 'None') {
      final g = Paint()
        ..color = glasses == 'Golden Glasses' ? p.reward : p.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(cx - s.width * .11, eyeY), s.width * .075, g);
      canvas.drawCircle(Offset(cx + s.width * .11, eyeY), s.width * .075, g);
      canvas.drawLine(
        Offset(cx - s.width * .035, eyeY),
        Offset(cx + s.width * .035, eyeY),
        g,
      );
    }
    if (level >= 10 || equipped['hat'] == 'Headphones') {
      final hp = Paint()
        ..color = p.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy - s.height * .13),
          width: s.width * .5,
          height: s.height * .4,
        ),
        math.pi,
        math.pi,
        false,
        hp,
      );
    }
    if (level >= 20) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - s.width * .2, cy + s.height * .23)
          ..lineTo(cx, cy + s.height * .42)
          ..lineTo(cx + s.width * .2, cy + s.height * .23),
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter old) =>
      old.mood != mood ||
      old.level != level ||
      old.t != t ||
      old.equipped != equipped;
}
