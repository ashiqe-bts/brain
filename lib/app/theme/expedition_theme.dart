import 'package:flutter/material.dart';

import '../../core/models/brain_models.dart';

abstract final class MotionTokens {
  static const touch = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const emphasized = Duration(milliseconds: 420);
  static const celebration = Duration(milliseconds: 900);
  static const curve = Curves.easeOutCubic;
}

@immutable
class ExpeditionRegionVisual {
  const ExpeditionRegionVisual({
    required this.accent,
    required this.secondary,
    required this.icon,
    required this.tagline,
  });

  final Color accent;
  final Color secondary;
  final IconData icon;
  final String tagline;
}

ExpeditionRegionVisual expeditionRegionVisual(ExpeditionRegion region) =>
    switch (region) {
      ExpeditionRegion.focusFrontier => const ExpeditionRegionVisual(
        accent: Color(0xFFFF6B6B),
        secondary: Color(0xFFFFD166),
        icon: Icons.rocket_launch_rounded,
        tagline: 'React, focus, and stay in control',
      ),
      ExpeditionRegion.memoryGrove => const ExpeditionRegionVisual(
        accent: Color(0xFF8D68E8),
        secondary: Color(0xFF5ED6B3),
        icon: Icons.park_rounded,
        tagline: 'Grow stronger memory pathways',
      ),
      ExpeditionRegion.puzzlePeaks => const ExpeditionRegionVisual(
        accent: Color(0xFF3188D9),
        secondary: Color(0xFF7ED8F6),
        icon: Icons.landscape_rounded,
        tagline: 'Climb with numbers and spatial puzzles',
      ),
    };

IconData expeditionRewardIcon(RewardDefinition reward) => switch (reward.id) {
  'scout-cap' => Icons.explore_rounded,
  'prism-pin' => Icons.palette_rounded,
  'memory-leaf' => Icons.eco_rounded,
  'orbit-ring' => Icons.public_rounded,
  'focus-lens' => Icons.center_focus_strong_rounded,
  'forge-spark' => Icons.local_fire_department_rounded,
  'portal-patch' => Icons.hub_rounded,
  'firefly-jar' => Icons.lightbulb_rounded,
  'totem-crown' => Icons.workspace_premium_rounded,
  'crystal-star' => Icons.star_rounded,
  'night-cape' => Icons.dark_mode_rounded,
  'star-trail' => Icons.auto_awesome_rounded,
  _ => Icons.extension_rounded,
};
