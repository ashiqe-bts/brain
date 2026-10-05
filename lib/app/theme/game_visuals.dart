import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import 'brain_theme.dart';

@immutable
class GameVisualSpec {
  const GameVisualSpec({
    required this.icon,
    required this.semanticLabel,
    required this.motif,
    required this.sceneLabel,
  });

  final IconData icon;
  final String semanticLabel;
  final GameMotif motif;
  final String sceneLabel;
}

enum GameMotif {
  colorOrbs,
  numberBlocks,
  memoryGrid,
  lightning,
  searchLens,
  signalGate,
  focusRadar,
  memoryPath,
  switchTracks,
  arrowLane,
  linkedCards,
  symbolConsole,
  trackingArena,
  towerWorkshop,
  splitDashboard,
  sequenceSteps,
  isometricCubes,
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
  semanticLabel: gameContent[type]!.semanticLabel,
  motif: GameMotif.values[type.index],
  sceneLabel: '${type.title} game board',
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
    final icon = Icon(visual.icon, size: size, color: context.onColor(accent));
    if (!decorated) return ExcludeSemantics(excluding: !semantic, child: icon);
    return Semantics(
      label: semantic ? visual.semanticLabel : null,
      excludeSemantics: !semantic,
      child: Container(
        width: size + 24,
        height: size + 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(accent, Colors.white, .28)!, accent],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? accent.withValues(alpha: .72)
                : context.brain.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .24),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}

class GameThumbnail extends StatelessWidget {
  const GameThumbnail({
    super.key,
    required this.game,
    this.width = 76,
    this.height = 68,
    this.semantic = false,
  });

  final GameType game;
  final double width;
  final double height;
  final bool semantic;

  @override
  Widget build(BuildContext context) {
    final visual = gameVisualFor(game);
    final accent = context.gameAccent(game);
    return Semantics(
      label: semantic ? visual.semanticLabel : null,
      excludeSemantics: !semantic,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(accent, Colors.white, .34)!, accent],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: context.brain.outline),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .3),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .14),
                ),
              ),
            ),
            Icon(
              visual.icon,
              size: height * .48,
              color: context.onColor(accent),
            ),
          ],
        ),
      ),
    );
  }
}
