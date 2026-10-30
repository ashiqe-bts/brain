import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/expedition_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import 'workout_screen.dart';

class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  ExpeditionPlan? plan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    plan ??= dailyExpeditionSelection(
      context.read<BrainCubit>().data.history,
      random: Random(stableSeed('${localDate()}|expedition-route')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = plan!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppText.workout.dailyWorkout)),
      body: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  context.brain.background,
                  const Color(0xFF87D8FF),
                  .14,
                )!,
                context.brain.background,
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              ResponsiveContent(
                maxWidth: AppSettings.standardContentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.workout.buildMix,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppText.workout.chooseGames,
                          style: TextStyle(color: context.brain.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final (index, game) in route.coreGames.indexed)
                      _RouteCard(index: index, game: game, bonus: false)
                          .animate(target: reducedMotion ? 0 : 1)
                          .fadeIn(
                            delay: Duration(milliseconds: index * 70),
                            duration: MotionTokens.standard,
                          )
                          .slideY(begin: .08, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      'Optional bonus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.rewardInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RouteCard(index: 3, game: route.bonusGame, bonus: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: context.brain.surface,
            border: Border(top: BorderSide(color: context.brain.outline)),
          ),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSettings.standardContentWidth,
              ),
              child: PrimaryAction(
                expanded: true,
                color: context.brain.success,
                onPressed: _start,
                icon: Icons.rocket_launch_rounded,
                label: AppText.workout.start,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    await context.read<BrainCubit>().startDailyExpedition(selectedPlan: plan);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.index,
    required this.game,
    required this.bonus,
  });

  final int index;
  final GameType game;
  final bool bonus;

  @override
  Widget build(BuildContext context) {
    final world = expeditionRegionVisual(game.region);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: bonus
            ? 'Optional bonus, ${game.title}, ${game.region.title}'
            : 'Stage ${index + 1}, ${game.title}, ${game.region.title}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color.lerp(context.brain.surface, world.accent, .08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: world.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: world.accent.withValues(alpha: .22),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              GameThumbnail(game: game, width: 66, height: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bonus ? game.title : game.region.title,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      bonus ? game.region.title : game.title,
                      style: TextStyle(color: context.brain.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bonus ? context.brain.reward : world.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bonus ? Icons.card_giftcard_rounded : world.icon,
                  color: context.onColor(
                    bonus ? context.brain.reward : world.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
