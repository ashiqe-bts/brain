import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/expedition_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../daily_workout/workout_screen.dart';
import '../daily_workout/workout_selection_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final today = localDate();
    final summary = data.daily.where((item) => item.date == today).firstOrNull;
    final done = summary != null;
    final generated = dailyExpeditionSelection(
      data.history,
      random: Random(stableSeed('$today|expedition-route')),
    );
    final games =
        data.draft?.order ??
        summary?.results.map((result) => result.type).take(3).toList() ??
        generated.coreGames;
    final completed = data.draft?.results.length ?? (done ? games.length : 0);
    final progress = data.explorerProgress;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppText.greeting(data.displayName!)),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppText.navigation.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<BrainCubit>().bootstrap(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    context.brain.background,
                    const Color(0xFF65C9FF),
                    .16,
                  )!,
                  context.brain.background,
                ],
              ),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                ResponsiveContent(
                  maxWidth: AppSettings.resultContentWidth,
                  child: Column(
                    children: [
                      _Hero(
                        done: done,
                        stars: progress.totalMapStars,
                        streak: data.currentStreak,
                      ),
                      const SizedBox(height: 18),
                      _ExpeditionMap(
                            games: games,
                            completed: completed,
                            done: done,
                          )
                          .animate(target: reducedMotion ? 0 : 1)
                          .fadeIn(duration: MotionTokens.standard)
                          .slideY(begin: .04, end: 0),
                      const SizedBox(height: 18),
                      PrimaryAction(
                        expanded: true,
                        color: done
                            ? context.brain.frame
                            : context.brain.success,
                        onPressed: done
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => data.draft == null
                                      ? const WorkoutSelectionScreen()
                                      : const WorkoutScreen(),
                                ),
                              ),
                        icon: data.draft == null
                            ? Icons.rocket_launch_rounded
                            : Icons.play_arrow_rounded,
                        label: data.draft == null
                            ? AppText.home.startWorkout
                            : AppText.home.continueWorkout,
                      ),
                      const SizedBox(height: 22),
                      _RewardShelf(progress: progress),
                      const SizedBox(height: 22),
                      _QuestStrip(missions: data.missions),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.done, required this.stars, required this.streak});

  final bool done;
  final int stars;
  final int streak;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    constraints: const BoxConstraints(minHeight: 164),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2368C4),
          Color.lerp(const Color(0xFF2368C4), context.brain.primary, .55)!,
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: .65), width: 2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF173B75).withValues(alpha: .35),
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          done ? 'ROUTE COMPLETE' : 'DAILY EXPEDITION',
          style: const TextStyle(
            color: Color(0xFFFFE781),
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done ? 'The worlds are glowing!' : AppText.home.readyTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Fredoka',
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done ? AppText.home.completeBody : AppText.home.duration,
          style: const TextStyle(
            color: Color(0xFFEAF4FF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _HeroPill(icon: Icons.star_rounded, label: '$stars stars'),
            _HeroPill(
              icon: Icons.local_fire_department_rounded,
              label: '$streak day streak',
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFE781), size: 17),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExpeditionMap extends StatelessWidget {
  const _ExpeditionMap({
    required this.games,
    required this.completed,
    required this.done,
  });

  final List<GameType> games;
  final int completed;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
    decoration: BoxDecoration(
      color: context.brain.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: context.brain.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's route",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          done
              ? 'All three map stars collected'
              : 'Complete each world to light the path',
          style: TextStyle(color: context.brain.textMuted),
        ),
        const SizedBox(height: 18),
        for (final (index, game) in games.indexed)
          _MapNode(
            game: game,
            index: index,
            completed: done || index < completed,
            current: !done && index == completed,
            last: index == games.length - 1,
          ),
      ],
    ),
  );
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.game,
    required this.index,
    required this.completed,
    required this.current,
    required this.last,
  });

  final GameType game;
  final int index;
  final bool completed;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final world = expeditionRegionVisual(game.region);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed
                      ? context.brain.success
                      : current
                      ? world.accent
                      : context.brain.frame,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.brain.text, width: 2),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: world.accent.withValues(alpha: .35),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  completed ? Icons.star_rounded : world.icon,
                  color: context.onColor(
                    completed
                        ? context.brain.success
                        : current
                        ? world.accent
                        : context.brain.frame,
                  ),
                ),
              ),
              if (!last)
                Container(
                  width: 5,
                  height: 38,
                  color: completed
                      ? context.brain.success
                      : context.brain.frame,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Row(
              children: [
                GameThumbnail(game: game, width: 56, height: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.region.title,
                        style: TextStyle(
                          color: world.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  completed
                      ? 'DONE'
                      : current
                      ? 'NEXT'
                      : '${index + 1}',
                  style: TextStyle(
                    color: completed
                        ? context.brain.success
                        : context.brain.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardShelf extends StatelessWidget {
  const _RewardShelf({required this.progress});
  final ExplorerProgress progress;

  @override
  Widget build(BuildContext context) {
    final unlocked = unlockedExpeditionRewards(progress.totalMapStars);
    final next = expeditionRewards
        .where((reward) => reward.requiredStars > progress.totalMapStars)
        .firstOrNull;
    return AppCard(
      tonal: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: context.brain.reward),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Expedition rewards',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text('${unlocked.length}/12'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reward in expeditionRewards.take(6))
                Tooltip(
                  message: reward.title,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: unlocked.contains(reward)
                          ? context.brain.reward
                          : context.brain.frame,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expeditionRewardIcon(reward),
                      color: context.onColor(
                        unlocked.contains(reward)
                            ? context.brain.reward
                            : context.brain.frame,
                      ),
                      size: 21,
                    ),
                  ),
                ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            ProgressMeter(
              label: 'Next: ${next.title}',
              value: progress.totalMapStars / next.requiredStars,
              trailing: '${progress.totalMapStars}/${next.requiredStars}',
              color: context.brain.reward,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestStrip extends StatelessWidget {
  const _QuestStrip({required this.missions});
  final List<Mission> missions;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Side quests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (missions.isEmpty)
          Text(
            'Fresh quests appear with your next expedition.',
            style: TextStyle(color: context.brain.textMuted),
          )
        else
          for (final mission in missions.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    mission.complete
                        ? Icons.check_circle_rounded
                        : Icons.flag_rounded,
                    color: mission.complete
                        ? context.brain.success
                        : context.brain.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(mission.title)),
                  Text('${mission.progress}/${mission.target}'),
                ],
              ),
            ),
      ],
    ),
  );
}
