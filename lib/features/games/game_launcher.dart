import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import 'game_screen.dart';
import 'game_tutorial_screen.dart';

/// The single entry point for scored and relaxed game sessions.
///
/// Keeping tutorial gating here prevents daily workouts and free training from
/// drifting into different first-play behavior.
Future<GameResult?> launchGameSession({
  required BuildContext context,
  required GameType type,
  required GameMode mode,
  required int difficulty,
  GameResult? personalBest,
  int? randomSeed,
}) async {
  final cubit = context.read<BrainCubit>();
  if (!cubit.hasCompletedTutorial(type)) {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GameTutorialScreen(type: type)),
    );
    if (completed != true || !context.mounted) return null;
    await cubit.completeTutorial(type);
  }
  if (!context.mounted) return null;
  return Navigator.push<GameResult>(
    context,
    MaterialPageRoute(
      builder: (_) => GameScreen(
        type: type,
        mode: mode,
        difficulty: difficulty,
        personalBest: personalBest,
        randomSeed: randomSeed,
      ),
    ),
  );
}

Future<void> replayGameTutorial(BuildContext context, GameType type) async {
  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => GameTutorialScreen(
        type: type,
        completionActionLabel: 'RETURN TO TRAIN',
      ),
    ),
  );
}
