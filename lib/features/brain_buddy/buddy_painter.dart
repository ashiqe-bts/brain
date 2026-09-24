import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import 'buddy_motion.dart';

class BuddyPainter extends CustomPainter {
  BuddyPainter({
    required this.palette,
    required this.theme,
    required this.mood,
    required this.pose,
    required this.level,
    required this.equipped,
    required this.variant,
    required this.phase,
  });

  final BrainPalette palette;
  final BrainTheme theme;
  final BuddyMood mood;
  final BuddyPose pose;
  final int level;
  final Map<String, String> equipped;
  final BuddyVariant variant;
  final double phase;

  static const _brain = Color(0xFFF47CAF);
  static const _brainLight = Color(0xFFFFB3D0);
  static const _brainShade = Color(0xFFD94D88);
  static const _pupil = Color(0xFF24233F);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 220;
    final dx = (size.width - 220 * scale) / 2;
    final dy = (size.height - 220 * scale) / 2;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    _drawStage(canvas);
    _drawAmbientEffects(canvas);
    canvas.drawOval(
      const Rect.fromLTWH(49, 190, 122, 14),
      Paint()..color = palette.shadow.withValues(alpha: .24),
    );

    canvas
      ..save()
      ..translate(110 + pose.bodyOffset.dx, 103 + pose.bodyOffset.dy)
      ..rotate(pose.rotation)
      ..scale(pose.scaleX, pose.scaleY);
    _drawPropBehind(canvas);
    _drawLegs(canvas);
    _drawArm(canvas, const Offset(-53, 5), pose.leftArm);
    _drawArm(canvas, const Offset(53, 5), pose.rightArm);
    _drawBody(canvas);
    _drawEvolution(canvas);
    _drawFace(canvas);
    _drawGlasses(canvas);
    _drawHat(canvas);
    _drawPropFront(canvas);
    canvas.restore();
    _drawForegroundEffects(canvas);
    canvas.restore();
  }

  void _drawStage(Canvas canvas) {
    final highContrast = theme == BrainTheme.highContrast;
    final light = theme == BrainTheme.daydream;
    final color = highContrast
        ? palette.surface
        : light
        ? const Color(0xFFE2E7FF)
        : Color.lerp(palette.hud, palette.secondary, .12)!;
    final radius = switch (variant) {
      BuddyVariant.compact => 84.0,
      BuddyVariant.stage => 91.0,
      BuddyVariant.celebration => 96.0,
    };
    canvas.drawCircle(Offset(110, 101), radius, Paint()..color = color);
    if (!highContrast) {
      canvas.drawCircle(
        const Offset(110, 101),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = palette.secondary.withValues(alpha: .2),
      );
    }
  }

  void _drawAmbientEffects(Canvas canvas) {
    final active =
        pose.effect > .05 ||
        level >= 35 ||
        equipped['effect'] != null && equipped['effect'] != 'None';
    if (!active) return;
    final count = variant == BuddyVariant.compact ? 5 : 10;
    final effect = equipped['effect'];
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + phase * math.pi * 2;
      final radius = 79 + (i % 3) * 7;
      final point = Offset(
        110 + math.cos(angle) * radius,
        100 + math.sin(angle) * radius * .8,
      );
      final color = switch (effect) {
        'Fire Aura' => i.isEven ? const Color(0xFFFF7A24) : palette.reward,
        'Electric Sparks' => palette.secondary,
        'Neon Glow' => palette.primary,
        _ => i.isEven ? palette.reward : palette.secondary,
      };
      if (effect == 'Floating Equations') {
        _text(canvas, i.isEven ? '+' : '÷', point, color, 13);
      } else {
        _spark(canvas, point, 3 + (i % 2) * 2, color);
      }
    }
  }

  void _drawLegs(Canvas canvas) {
    _leg(canvas, -27, pose.leftFootLift, -1);
    _leg(canvas, 27, pose.rightFootLift, 1);
  }

  void _leg(Canvas canvas, double x, double lift, int direction) {
    final path = Path()
      ..moveTo(x, 39)
      ..quadraticBezierTo(x + direction * 2, 61, x + direction * 3, 79 - lift);
    canvas.drawPath(path, _stroke(palette.outline, 10));
    canvas.drawPath(path, _stroke(_brainShade, 6));
    final foot = Path()
      ..moveTo(x + direction * 3, 79 - lift)
      ..quadraticBezierTo(
        x + direction * 15,
        85 - lift,
        x + direction * 20,
        78 - lift,
      );
    canvas.drawPath(foot, _stroke(palette.outline, 11));
    canvas.drawPath(foot, _stroke(_brainShade, 7));
  }

  void _drawArm(Canvas canvas, Offset shoulder, BuddyArmPose arm) {
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(arm.elbow.dx, arm.elbow.dy, arm.hand.dx, arm.hand.dy);
    canvas.drawPath(path, _stroke(palette.outline, 11));
    canvas.drawPath(path, _stroke(_brainShade, 7));
    canvas.drawCircle(arm.hand, 5.2, Paint()..color = palette.outline);
    canvas.drawCircle(arm.hand, 3.4, Paint()..color = _brainShade);
    if (arm.openHand) {
      for (var i = -1; i <= 1; i++) {
        final finger = Path()
          ..moveTo(arm.hand.dx + i * 2.2, arm.hand.dy)
          ..lineTo(arm.hand.dx + i * 3.5, arm.hand.dy - 8);
        canvas.drawPath(finger, _stroke(palette.outline, 4.5));
        canvas.drawPath(finger, _stroke(_brainShade, 2.4));
      }
    }
  }

  void _drawBody(Canvas canvas) {
    final body = Path()
      ..moveTo(-61, 24)
      ..cubicTo(-75, 17, -77, -1, -64, -13)
      ..cubicTo(-70, -29, -55, -44, -39, -39)
      ..cubicTo(-32, -57, -13, -60, 0, -47)
      ..cubicTo(13, -62, 34, -57, 42, -39)
      ..cubicTo(59, -44, 74, -30, 68, -13)
      ..cubicTo(81, -4, 78, 19, 65, 27)
      ..cubicTo(64, 44, 46, 55, 25, 49)
      ..cubicTo(9, 61, -8, 58, -21, 50)
      ..cubicTo(-42, 56, -64, 46, -61, 24)
      ..close();
    canvas.drawPath(
      body.shift(const Offset(0, 6)),
      Paint()..color = palette.shadow.withValues(alpha: .34),
    );
    canvas.drawPath(body, Paint()..color = _brain);
    canvas.drawPath(
      body,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme == BrainTheme.highContrast ? 6 : 4.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-47, -39, 27, 10),
      Paint()..color = _brainLight.withValues(alpha: .82),
    );
    canvas.drawOval(
      const Rect.fromLTWH(22, -43, 19, 7),
      Paint()..color = _brainLight.withValues(alpha: .55),
    );
    _drawFolds(canvas);
  }

  void _drawFolds(Canvas canvas) {
    final fold = _stroke(_brainShade.withValues(alpha: .82), 2.7);
    final paths = <Path>[
      Path()
        ..moveTo(-48, -18)
        ..cubicTo(-31, -26, -38, -5, -47, 0),
      Path()
        ..moveTo(-25, -42)
        ..cubicTo(-13, -35, -19, -20, -29, -16),
      Path()
        ..moveTo(-3, -45)
        ..cubicTo(-10, -29, -1, -22, -1, -9),
      Path()
        ..moveTo(22, -43)
        ..cubicTo(34, -33, 23, -23, 17, -19),
      Path()
        ..moveTo(48, -24)
        ..cubicTo(57, -13, 45, -4, 39, 1),
      Path()
        ..moveTo(-49, 24)
        ..cubicTo(-38, 14, -29, 24, -34, 35),
      Path()
        ..moveTo(38, 25)
        ..cubicTo(48, 15, 57, 25, 49, 36),
      Path()
        ..moveTo(0, -47)
        ..cubicTo(-4, -27, 5, -13, 0, 4),
    ];
    for (final path in paths) {
      canvas.drawPath(path, fold);
    }
  }

  void _drawEvolution(Canvas canvas) {
    if (level < 20) return;
    final coat = Path()
      ..moveTo(-49, 29)
      ..lineTo(-37, 51)
      ..quadraticBezierTo(-15, 59, 0, 48)
      ..quadraticBezierTo(15, 59, 37, 51)
      ..lineTo(49, 29)
      ..lineTo(31, 25)
      ..lineTo(0, 44)
      ..lineTo(-31, 25)
      ..close();
    canvas.drawPath(coat, Paint()..color = const Color(0xFFF7F7F2));
    canvas.drawPath(coat, _stroke(palette.outline, 3));
    canvas.drawLine(
      const Offset(0, 44),
      const Offset(0, 54),
      _stroke(palette.outline, 2),
    );
  }

  void _drawFace(Canvas canvas) {
    _eye(canvas, const Offset(-23, -4), pose.leftEye);
    _eye(canvas, const Offset(23, -4), pose.rightEye);
    _brow(canvas, -23, pose.leftBrow, false);
    _brow(canvas, 23, pose.rightBrow, true);
    _mouth(canvas);
    canvas.drawOval(
      const Rect.fromLTWH(-51, 17, 16, 7),
      Paint()..color = const Color(0xFFE95891).withValues(alpha: .52),
    );
    canvas.drawOval(
      const Rect.fromLTWH(35, 17, 16, 7),
      Paint()..color = const Color(0xFFE95891).withValues(alpha: .52),
    );
  }

  void _eye(Canvas canvas, Offset center, double openness) {
    if (openness < .16) {
      canvas.drawLine(
        center.translate(-11, 1),
        center.translate(11, 1),
        _stroke(palette.outline, 3.5),
      );
      return;
    }
    final rect = Rect.fromCenter(
      center: center,
      width: 27,
      height: 34 * openness.clamp(.2, 1.15),
    );
    canvas.drawOval(rect, Paint()..color = Colors.white);
    canvas.drawOval(rect, _outline(3));
    final pupil = center + pose.pupil;
    canvas.drawCircle(pupil.translate(0, 2), 7.8, Paint()..color = _pupil);
    canvas.drawCircle(
      pupil.translate(-2.2, -.7),
      2.3,
      Paint()..color = Colors.white,
    );
  }

  void _brow(Canvas canvas, double x, double lift, bool right) {
    final y = -28 - lift;
    final tilt = (right ? pose.rightBrow : pose.leftBrow) * .45;
    canvas.drawLine(
      Offset(x - 9, y + tilt),
      Offset(x + 9, y - tilt),
      _stroke(_brainShade, 3.2),
    );
  }

  void _mouth(Canvas canvas) {
    switch (pose.mouth) {
      case BuddyMouth.smile:
        canvas.drawArc(
          const Rect.fromLTWH(-17, 12, 34, 21),
          .12,
          math.pi - .24,
          false,
          _stroke(palette.outline, 4),
        );
      case BuddyMouth.openSmile:
        final mouth = Path()
          ..moveTo(-18, 14)
          ..quadraticBezierTo(0, 35, 18, 14)
          ..quadraticBezierTo(0, 23, -18, 14)
          ..close();
        canvas.drawPath(mouth, Paint()..color = palette.outline);
        canvas.drawArc(
          const Rect.fromLTWH(-11, 20, 22, 11),
          math.pi,
          math.pi,
          false,
          _stroke(const Color(0xFFFF769A), 4),
        );
      case BuddyMouth.small:
        canvas.drawArc(
          const Rect.fromLTWH(-8, 18, 16, 8),
          math.pi,
          math.pi,
          false,
          _stroke(palette.outline, 3.5),
        );
      case BuddyMouth.surprised:
        canvas.drawOval(
          const Rect.fromLTWH(-7, 16, 14, 18),
          Paint()..color = palette.outline,
        );
      case BuddyMouth.sleepy:
        canvas.drawArc(
          const Rect.fromLTWH(-11, 17, 22, 10),
          0,
          math.pi,
          false,
          _stroke(palette.outline, 3.5),
        );
      case BuddyMouth.determined:
        canvas.drawArc(
          const Rect.fromLTWH(-15, 13, 30, 17),
          .2,
          math.pi - .4,
          false,
          _stroke(palette.outline, 4),
        );
        canvas.drawLine(
          const Offset(-12, 13),
          const Offset(12, 13),
          _stroke(palette.outline, 3),
        );
    }
  }

  void _drawGlasses(Canvas canvas) {
    final item = equipped['glasses'];
    if (level < 5 && (item == null || item == 'None')) return;
    final color = item == 'Golden Glasses' ? palette.reward : palette.outline;
    final futuristic = item == 'Futuristic Visor';
    if (futuristic) {
      final visor = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-43, -21, 86, 34),
        const Radius.circular(13),
      );
      canvas.drawRRect(
        visor,
        Paint()..color = palette.secondary.withValues(alpha: .42),
      );
      canvas.drawRRect(visor, _stroke(color, 4));
      return;
    }
    if (item == 'Sunglasses') {
      canvas.drawOval(
        const Rect.fromLTWH(-39, -20, 31, 29),
        Paint()..color = _pupil,
      );
      canvas.drawOval(
        const Rect.fromLTWH(8, -20, 31, 29),
        Paint()..color = _pupil,
      );
    }
    canvas.drawOval(const Rect.fromLTWH(-39, -20, 31, 29), _stroke(color, 4));
    canvas.drawOval(const Rect.fromLTWH(8, -20, 31, 29), _stroke(color, 4));
    canvas.drawLine(
      const Offset(-8, -7),
      const Offset(8, -7),
      _stroke(color, 4),
    );
  }

  void _drawHat(Canvas canvas) {
    final hat = equipped['hat'];
    final shown = hat != null && hat != 'None'
        ? hat
        : level >= 10
        ? 'Headphones'
        : 'None';
    switch (shown) {
      case 'Graduation Cap':
        final cap = Path()
          ..moveTo(-39, -52)
          ..lineTo(0, -70)
          ..lineTo(41, -52)
          ..lineTo(0, -35)
          ..close();
        canvas.drawPath(cap, Paint()..color = palette.secondary);
        canvas.drawPath(cap, _stroke(palette.outline, 4));
        canvas.drawLine(
          const Offset(31, -56),
          const Offset(42, -31),
          _stroke(palette.reward, 3),
        );
      case 'Wizard Hat':
        final hatPath = Path()
          ..moveTo(-38, -42)
          ..quadraticBezierTo(-5, -91, 17, -91)
          ..quadraticBezierTo(5, -60, 39, -42)
          ..close();
        canvas.drawPath(hatPath, Paint()..color = palette.primary);
        canvas.drawPath(hatPath, _stroke(palette.outline, 4));
        _spark(canvas, const Offset(2, -67), 5, palette.reward);
      case 'Crown':
        final crown = Path()
          ..moveTo(-34, -44)
          ..lineTo(-29, -72)
          ..lineTo(-10, -56)
          ..lineTo(0, -78)
          ..lineTo(13, -56)
          ..lineTo(31, -72)
          ..lineTo(35, -44)
          ..close();
        canvas.drawPath(crown, Paint()..color = palette.reward);
        canvas.drawPath(crown, _stroke(palette.outline, 4));
      case 'Detective Hat':
        canvas.drawOval(
          const Rect.fromLTWH(-46, -52, 92, 18),
          Paint()..color = const Color(0xFF9B643B),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-27, -70, 54, 29),
            const Radius.circular(12),
          ),
          Paint()..color = const Color(0xFFB77B4F),
        );
        canvas.drawLine(
          const Offset(-28, -49),
          const Offset(28, -49),
          _stroke(palette.outline, 4),
        );
      case '7-Day Headband':
        canvas.drawArc(
          const Rect.fromLTWH(-61, -50, 122, 48),
          math.pi,
          math.pi,
          false,
          _stroke(palette.reward, 9),
        );
        canvas.drawLine(
          const Offset(58, -31),
          const Offset(76, -22),
          _stroke(palette.reward, 7),
        );
      case 'Headphones':
        canvas.drawArc(
          const Rect.fromLTWH(-67, -62, 134, 82),
          math.pi,
          math.pi,
          false,
          _stroke(palette.secondary, 9),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-70, -20, 15, 35),
            const Radius.circular(6),
          ),
          Paint()..color = palette.secondary,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(55, -20, 15, 35),
            const Radius.circular(6),
          ),
          Paint()..color = palette.secondary,
        );
      default:
        break;
    }
  }

  void _drawPropBehind(Canvas canvas) {
    switch (pose.prop) {
      case BuddyProp.bulb:
        final glow = Paint()
          ..color = palette.reward.withValues(alpha: .25 + pose.effect * .28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
        canvas.drawCircle(const Offset(73, -77), 20, glow);
        canvas.drawCircle(
          const Offset(73, -77),
          12,
          Paint()..color = palette.reward,
        );
        canvas.drawCircle(const Offset(73, -77), 12, _outline(2.5));
        canvas.drawRect(
          const Rect.fromLTWH(68, -65, 10, 9),
          Paint()..color = palette.secondary,
        );
        for (var i = 0; i < 5; i++) {
          final a = -math.pi + i * math.pi / 4;
          canvas.drawLine(
            Offset(73 + math.cos(a) * 18, -77 + math.sin(a) * 18),
            Offset(73 + math.cos(a) * 25, -77 + math.sin(a) * 25),
            _stroke(palette.reward, 3),
          );
        }
      case BuddyProp.flame:
        final flame = Path()
          ..moveTo(79, -73)
          ..cubicTo(60, -55, 75, -39, 84, -43)
          ..cubicTo(103, -51, 92, -68, 88, -84)
          ..cubicTo(84, -77, 82, -75, 79, -73)
          ..close();
        canvas.drawPath(flame, Paint()..color = const Color(0xFFFF7A24));
        canvas.drawPath(flame, _stroke(palette.outline, 3));
      case BuddyProp.hearts:
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + phase * math.pi * 2;
          _heart(canvas, Offset(math.cos(a) * 85, math.sin(a) * 63 - 4), 8);
        }
      default:
        break;
    }
  }

  void _drawPropFront(Canvas canvas) {
    switch (pose.prop) {
      case BuddyProp.trophy:
        final cup = Path()
          ..moveTo(-18, -72)
          ..lineTo(18, -72)
          ..quadraticBezierTo(15, -48, 0, -45)
          ..quadraticBezierTo(-15, -48, -18, -72)
          ..close();
        canvas.drawPath(cup, Paint()..color = palette.reward);
        canvas.drawPath(cup, _stroke(palette.outline, 3));
        canvas.drawLine(
          const Offset(0, -45),
          const Offset(0, -36),
          _stroke(palette.outline, 5),
        );
        canvas.drawLine(
          const Offset(-12, -34),
          const Offset(12, -34),
          _stroke(palette.outline, 4),
        );
      case BuddyProp.chest:
        final chest = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-36, 46, 72, 38),
          const Radius.circular(7),
        );
        canvas.drawRRect(chest, Paint()..color = const Color(0xFFB86132));
        canvas.drawRRect(chest, _stroke(palette.outline, 4));
        canvas.drawRect(
          const Rect.fromLTWH(-36, 55, 72, 9),
          Paint()..color = palette.reward,
        );
        canvas.drawRect(
          const Rect.fromLTWH(-6, 56, 12, 17),
          Paint()..color = palette.outline,
        );
      case BuddyProp.medal:
        final ribbon = Path()
          ..moveTo(-13, 25)
          ..lineTo(-5, 45)
          ..lineTo(0, 38)
          ..lineTo(6, 45)
          ..lineTo(14, 25);
        canvas.drawPath(ribbon, _stroke(palette.secondary, 8));
        canvas.drawCircle(
          const Offset(0, 45),
          11,
          Paint()..color = palette.reward,
        );
        canvas.drawCircle(const Offset(0, 45), 11, _outline(3));
        _text(canvas, '★', const Offset(0, 44), palette.outline, 11);
      default:
        break;
    }
  }

  void _drawForegroundEffects(Canvas canvas) {
    if (mood == BuddyMood.confused) {
      _text(canvas, '?', const Offset(185, 53), palette.primary, 25);
    }
    if (mood == BuddyMood.sleepy) {
      _text(canvas, 'Z', const Offset(171, 64), palette.secondary, 21);
      _text(canvas, 'z', const Offset(188, 45), palette.secondary, 15);
    }
    if ({
      BuddyMood.celebrate,
      BuddyMood.levelUp,
      BuddyMood.workoutComplete,
    }.contains(mood)) {
      for (var i = 0; i < 8; i++) {
        final x = 25.0 + i * 24;
        final y = 33.0 + ((i * 29) % 45);
        final color = i.isEven ? palette.reward : palette.secondary;
        canvas.drawCircle(Offset(x, y), 3 + (i % 3), Paint()..color = color);
      }
    }
    if (mood == BuddyMood.energized) {
      _bolt(canvas, const Offset(25, 78));
      _bolt(canvas, const Offset(190, 88));
    }
    if (level >= 50) {
      canvas.drawArc(
        const Rect.fromLTWH(18, 20, 184, 178),
        phase * math.pi,
        1.8,
        false,
        _stroke(palette.reward.withValues(alpha: .7), 3),
      );
    }
  }

  void _bolt(Canvas canvas, Offset at) {
    final path = Path()
      ..moveTo(at.dx + 5, at.dy - 13)
      ..lineTo(at.dx - 4, at.dy)
      ..lineTo(at.dx + 2, at.dy)
      ..lineTo(at.dx - 5, at.dy + 14)
      ..lineTo(at.dx + 9, at.dy - 3)
      ..lineTo(at.dx + 2, at.dy - 3)
      ..close();
    canvas.drawPath(path, Paint()..color = palette.reward);
    canvas.drawPath(path, _stroke(palette.outline, 2));
  }

  void _heart(Canvas canvas, Offset center, double size) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size)
      ..cubicTo(
        center.dx - size * 1.5,
        center.dy,
        center.dx - size,
        center.dy - size,
        center.dx,
        center.dy - size * .25,
      )
      ..cubicTo(
        center.dx + size,
        center.dy - size,
        center.dx + size * 1.5,
        center.dy,
        center.dx,
        center.dy + size,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF23D5B));
    canvas.drawPath(path, _stroke(palette.outline, 2));
  }

  void _spark(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      _stroke(color, 2),
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      _stroke(color, 2),
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontFamily: 'Fredoka',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _outline(double width) => Paint()
    ..color = palette.outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant BuddyPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.pose != pose ||
      oldDelegate.level != level ||
      oldDelegate.equipped != equipped ||
      oldDelegate.variant != variant ||
      oldDelegate.phase != phase ||
      oldDelegate.palette != palette ||
      oldDelegate.theme != theme;
}
