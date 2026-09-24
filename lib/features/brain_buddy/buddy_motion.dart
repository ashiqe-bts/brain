import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/brain_models.dart';

enum BuddyVariant { stage, compact, celebration }

enum BuddyProp { none, bulb, trophy, chest, flame, hearts, medal }

enum BuddyMouth { smile, openSmile, small, surprised, sleepy, determined }

@immutable
class BuddyArmPose {
  const BuddyArmPose(this.elbow, this.hand, {this.openHand = false});

  final Offset elbow;
  final Offset hand;
  final bool openHand;
}

@immutable
class BuddyPose {
  const BuddyPose({
    this.bodyOffset = Offset.zero,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.leftEye = 1,
    this.rightEye = 1,
    this.pupil = Offset.zero,
    this.leftBrow = 0,
    this.rightBrow = 0,
    this.mouth = BuddyMouth.smile,
    this.leftArm = const BuddyArmPose(Offset(-76, 14), Offset(-82, 42)),
    this.rightArm = const BuddyArmPose(Offset(76, 14), Offset(82, 42)),
    this.leftFootLift = 0,
    this.rightFootLift = 0,
    this.prop = BuddyProp.none,
    this.effect = 0,
  });

  final Offset bodyOffset;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final double leftEye;
  final double rightEye;
  final Offset pupil;
  final double leftBrow;
  final double rightBrow;
  final BuddyMouth mouth;
  final BuddyArmPose leftArm;
  final BuddyArmPose rightArm;
  final double leftFootLift;
  final double rightFootLift;
  final BuddyProp prop;
  final double effect;
}

class BuddyMotion {
  const BuddyMotion._();

  static BuddyPose pose({
    required BuddyMood mood,
    required double idle,
    required double action,
    required bool reducedMotion,
  }) {
    final breath = reducedMotion ? 0.0 : math.sin(idle * math.pi * 2);
    final pulse = reducedMotion ? 1.0 : math.sin(action * math.pi);
    final blinking = (idle > .2 && idle < .225) || (idle > .73 && idle < .765);
    final blink = reducedMotion || !blinking ? 1.0 : .08;
    final glanceAmount = idle > .34 && idle < .58
        ? math.sin((idle - .34) / .24 * math.pi)
        : 0.0;
    final gesture = reducedMotion || idle < .82
        ? 0.0
        : math.sin((idle - .82) / .18 * math.pi).clamp(0.0, 1.0);
    final glance = reducedMotion ? Offset.zero : Offset(glanceAmount * 3, 0);
    var base = BuddyPose(
      bodyOffset: Offset(0, breath * 1.8),
      scaleX: 1 + breath * .008,
      scaleY: 1 - breath * .012,
      leftEye: blink,
      rightEye: blink,
      pupil: glance,
      rightArm: BuddyArmPose(
        Offset(76, 14 - gesture * 2),
        Offset(82 + gesture * 3, 42 - gesture * 7),
        openHand: gesture > .35,
      ),
    );

    switch (mood) {
      case BuddyMood.idle:
        return base;
      case BuddyMood.blink:
        return _copy(base, leftEye: .08, rightEye: .08);
      case BuddyMood.wave:
      case BuddyMood.returning:
        return _copy(
          base,
          bodyOffset: Offset(-2, -3 * pulse),
          rotation: -.035,
          mouth: BuddyMouth.openSmile,
          rightArm: BuddyArmPose(
            const Offset(76, -35),
            Offset(76 + pulse * 7, -78),
            openHand: true,
          ),
          pupil: const Offset(1.5, -1),
          effect: pulse,
        );
      case BuddyMood.thinking:
        return _copy(
          base,
          rotation: -.045,
          pupil: const Offset(3, -4),
          leftBrow: -2,
          rightBrow: 2,
          mouth: BuddyMouth.small,
          rightArm: const BuddyArmPose(Offset(71, 20), Offset(35, 18)),
          prop: BuddyProp.bulb,
          effect: .55 + pulse * .45,
        );
      case BuddyMood.happy:
        return _copy(
          base,
          bodyOffset: Offset(0, -6 * pulse),
          scaleX: 1 + .03 * pulse,
          scaleY: 1 - .03 * pulse,
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(Offset(-72, 5), Offset(-91, -9)),
          rightArm: const BuddyArmPose(Offset(72, 5), Offset(91, -9)),
        );
      case BuddyMood.confused:
        return _copy(
          base,
          rotation: -.075,
          pupil: const Offset(-3, -1),
          leftBrow: -4,
          rightBrow: 4,
          mouth: BuddyMouth.small,
          leftArm: const BuddyArmPose(Offset(-74, 17), Offset(-88, 38)),
          rightArm: const BuddyArmPose(Offset(70, 20), Offset(45, 28)),
          effect: .7,
        );
      case BuddyMood.celebrate:
        return _copy(
          base,
          bodyOffset: Offset(0, -12 * pulse),
          rotation: math.sin(action * math.pi * 2) * .025,
          scaleX: 1 + .04 * pulse,
          scaleY: 1 - .04 * pulse,
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(
            Offset(-75, -30),
            Offset(-72, -76),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(75, -30),
            Offset(72, -76),
            openHand: true,
          ),
          leftFootLift: 7 * pulse,
          rightFootLift: 10 * pulse,
          effect: pulse,
        );
      case BuddyMood.sleepy:
        return _copy(
          base,
          bodyOffset: const Offset(0, 5),
          rotation: .045,
          leftEye: .18,
          rightEye: .18,
          mouth: BuddyMouth.sleepy,
          effect: .45 + pulse * .35,
        );
      case BuddyMood.energized:
        return _copy(
          base,
          bodyOffset: Offset(0, -5 * pulse),
          scaleX: 1 + .045 * pulse,
          scaleY: 1 + .045 * pulse,
          mouth: BuddyMouth.determined,
          leftArm: const BuddyArmPose(Offset(-74, -5), Offset(-91, -26)),
          rightArm: const BuddyArmPose(Offset(74, -5), Offset(91, -26)),
          effect: .7 + pulse * .3,
        );
      case BuddyMood.levelUp:
        return _copy(
          base,
          bodyOffset: Offset(0, -15 * pulse),
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(
            Offset(-74, -18),
            Offset(-93, -55),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(74, -18),
            Offset(93, -55),
            openHand: true,
          ),
          effect: pulse,
        );
      case BuddyMood.streak:
        return _copy(
          base,
          rotation: -.025,
          mouth: BuddyMouth.determined,
          leftArm: const BuddyArmPose(Offset(-75, 5), Offset(-91, -9)),
          rightArm: const BuddyArmPose(
            Offset(75, -30),
            Offset(80, -69),
            openHand: true,
          ),
          prop: BuddyProp.flame,
          effect: .65 + pulse * .35,
        );
      case BuddyMood.record:
        return _copy(
          base,
          bodyOffset: Offset(0, -5 * pulse),
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(
            Offset(-75, -18),
            Offset(-74, -56),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(75, -18),
            Offset(74, -56),
            openHand: true,
          ),
          prop: BuddyProp.trophy,
          effect: pulse,
        );
      case BuddyMood.chest:
        return _copy(
          base,
          leftEye: 1.08,
          rightEye: 1.08,
          pupil: const Offset(0, 3),
          mouth: BuddyMouth.surprised,
          leftArm: const BuddyArmPose(Offset(-72, 16), Offset(-48, 44)),
          rightArm: const BuddyArmPose(Offset(72, 16), Offset(48, 44)),
          prop: BuddyProp.chest,
          effect: pulse,
        );
      case BuddyMood.fullEnergy:
        return _copy(
          base,
          bodyOffset: Offset(0, -6 * pulse),
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(
            Offset(-74, -12),
            Offset(-93, -42),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(74, -12),
            Offset(93, -42),
            openHand: true,
          ),
          prop: BuddyProp.hearts,
          effect: .6 + pulse * .4,
        );
      case BuddyMood.surprised:
        return _copy(
          base,
          bodyOffset: Offset(0, 3 * pulse),
          scaleX: 1 + .06 * pulse,
          scaleY: 1 - .06 * pulse,
          leftEye: 1.12,
          rightEye: 1.12,
          mouth: BuddyMouth.surprised,
          leftArm: const BuddyArmPose(
            Offset(-75, -10),
            Offset(-92, -40),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(75, -10),
            Offset(92, -40),
            openHand: true,
          ),
        );
      case BuddyMood.tapped:
        return _copy(
          base,
          bodyOffset: Offset(0, 5 * pulse),
          scaleX: 1 + .09 * pulse,
          scaleY: 1 - .09 * pulse,
          rightEye: .08,
          mouth: BuddyMouth.openSmile,
          rightArm: const BuddyArmPose(
            Offset(76, -28),
            Offset(92, -65),
            openHand: true,
          ),
        );
      case BuddyMood.workoutComplete:
        return _copy(
          base,
          bodyOffset: Offset(0, -10 * pulse),
          mouth: BuddyMouth.openSmile,
          leftArm: const BuddyArmPose(
            Offset(-75, -24),
            Offset(-88, -65),
            openHand: true,
          ),
          rightArm: const BuddyArmPose(
            Offset(75, -24),
            Offset(88, -65),
            openHand: true,
          ),
          prop: BuddyProp.medal,
          effect: pulse,
        );
    }
  }

  static BuddyPose _copy(
    BuddyPose p, {
    Offset? bodyOffset,
    double? rotation,
    double? scaleX,
    double? scaleY,
    double? leftEye,
    double? rightEye,
    Offset? pupil,
    double? leftBrow,
    double? rightBrow,
    BuddyMouth? mouth,
    BuddyArmPose? leftArm,
    BuddyArmPose? rightArm,
    double? leftFootLift,
    double? rightFootLift,
    BuddyProp? prop,
    double? effect,
  }) => BuddyPose(
    bodyOffset: bodyOffset ?? p.bodyOffset,
    rotation: rotation ?? p.rotation,
    scaleX: scaleX ?? p.scaleX,
    scaleY: scaleY ?? p.scaleY,
    leftEye: leftEye ?? p.leftEye,
    rightEye: rightEye ?? p.rightEye,
    pupil: pupil ?? p.pupil,
    leftBrow: leftBrow ?? p.leftBrow,
    rightBrow: rightBrow ?? p.rightBrow,
    mouth: mouth ?? p.mouth,
    leftArm: leftArm ?? p.leftArm,
    rightArm: rightArm ?? p.rightArm,
    leftFootLift: leftFootLift ?? p.leftFootLift,
    rightFootLift: rightFootLift ?? p.rightFootLift,
    prop: prop ?? p.prop,
    effect: effect ?? p.effect,
  );
}
