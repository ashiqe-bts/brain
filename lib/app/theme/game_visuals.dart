import 'package:flutter/material.dart';

import '../../core/models/brain_models.dart';
import 'brain_theme.dart';

@immutable
class GameVisualSpec {
  const GameVisualSpec({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;
}

GameVisualSpec gameVisualFor(GameType type) => switch (type) {
  GameType.colorClash => const GameVisualSpec(
    icon: Icons.palette_outlined,
    semanticLabel: 'Color palette',
  ),
  GameType.mathBlitz => const GameVisualSpec(
    icon: Icons.calculate_outlined,
    semanticLabel: 'Calculator',
  ),
  GameType.memoryTiles => const GameVisualSpec(
    icon: Icons.grid_view_rounded,
    semanticLabel: 'Memory grid',
  ),
  GameType.reflexTap => const GameVisualSpec(
    icon: Icons.bolt_rounded,
    semanticLabel: 'Reaction bolt',
  ),
  GameType.visualSearch => const GameVisualSpec(
    icon: Icons.search_rounded,
    semanticLabel: 'Visual search',
  ),
  GameType.signalStop => const GameVisualSpec(
    icon: Icons.front_hand_outlined,
    semanticLabel: 'Stop signal',
  ),
  GameType.peripheralFocus => const GameVisualSpec(
    icon: Icons.center_focus_strong_rounded,
    semanticLabel: 'Peripheral focus',
  ),
  GameType.nBackNavigator => const GameVisualSpec(
    icon: Icons.history_toggle_off_rounded,
    semanticLabel: 'Working memory history',
  ),
  GameType.ruleSwitch => const GameVisualSpec(
    icon: Icons.swap_horiz_rounded,
    semanticLabel: 'Switching rules',
  ),
  GameType.arrowGuard => const GameVisualSpec(
    icon: Icons.compare_arrows_rounded,
    semanticLabel: 'Conflicting arrows',
  ),
  GameType.pairLink => const GameVisualSpec(
    icon: Icons.link_rounded,
    semanticLabel: 'Linked pair',
  ),
  GameType.symbolSprint => const GameVisualSpec(
    icon: Icons.pin_outlined,
    semanticLabel: 'Symbol key',
  ),
  GameType.objectTracker => const GameVisualSpec(
    icon: Icons.track_changes_rounded,
    semanticLabel: 'Tracking target',
  ),
  GameType.towerPlanner => const GameVisualSpec(
    icon: Icons.account_tree_outlined,
    semanticLabel: 'Planning tree',
  ),
  GameType.dualTaskDash => const GameVisualSpec(
    icon: Icons.dashboard_customize_outlined,
    semanticLabel: 'Two simultaneous tasks',
  ),
  GameType.logicSeries => const GameVisualSpec(
    icon: Icons.functions_rounded,
    semanticLabel: 'Logic sequence',
  ),
  GameType.spatialRotation => const GameVisualSpec(
    icon: Icons.threed_rotation_rounded,
    semanticLabel: 'Spatial rotation',
  ),
};

class GameIcon extends StatelessWidget {
  const GameIcon({
    super.key,
    required this.game,
    this.size = 24,
    this.decorated = false,
    this.semantic = false,
  });

  final GameType game;
  final double size;
  final bool decorated;
  final bool semantic;

  @override
  Widget build(BuildContext context) {
    final visual = gameVisualFor(game);
    final accent = context.gameAccent(game);
    final icon = Icon(
      visual.icon,
      size: size,
      color: accent,
      semanticLabel: semantic ? visual.semanticLabel : null,
    );
    if (!decorated) return ExcludeSemantics(excluding: !semantic, child: icon);
    return Semantics(
      label: semantic ? visual.semanticLabel : null,
      excludeSemantics: !semantic,
      child: Container(
        width: size + 24,
        height: size + 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: icon,
      ),
    );
  }
}
