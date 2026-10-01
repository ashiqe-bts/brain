import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import 'brain_theme.dart';

@immutable
class GameVisualSpec {
  const GameVisualSpec({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;
}

GameVisualSpec gameVisualFor(GameType type) => GameVisualSpec(
  icon: switch (type) {
    GameType.colorClash => Icons.palette_outlined,
    GameType.mathBlitz => Icons.calculate_outlined,
    GameType.memoryTiles => Icons.grid_view_rounded,
    GameType.reflexTap => Icons.bolt_rounded,
    GameType.visualSearch => Icons.search_rounded,
    GameType.signalStop => Icons.front_hand_outlined,
    GameType.peripheralFocus => Icons.center_focus_strong_rounded,
    GameType.nBackNavigator => Icons.history_toggle_off_rounded,
    GameType.ruleSwitch => Icons.swap_horiz_rounded,
    GameType.arrowGuard => Icons.compare_arrows_rounded,
    GameType.pairLink => Icons.link_rounded,
    GameType.symbolSprint => Icons.pin_outlined,
    GameType.objectTracker => Icons.track_changes_rounded,
    GameType.towerPlanner => Icons.account_tree_outlined,
    GameType.dualTaskDash => Icons.dashboard_customize_outlined,
    GameType.logicSeries => Icons.functions_rounded,
    GameType.spatialRotation => Icons.threed_rotation_rounded,
  },
  semanticLabel: gameContent[type.name]!.semanticLabel,
);

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
