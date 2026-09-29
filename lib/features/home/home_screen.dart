import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../daily_workout/workout_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final done = data.daily.any((summary) => summary.date == localDate());
    final baseline = baselineStatus(data.history);
    final review = weeklyReview(daily: data.daily, history: data.history);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight:
            (72 + 16 * (MediaQuery.textScalerOf(context).scale(1) - 1)).clamp(
              72,
              104,
            ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hey, ${data.displayName}'),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      _workoutCard(context, data, done),
                      const SizedBox(height: 14),
                      _baselineCard(context, baseline),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          MetricTile(
                            icon: Icons.local_fire_department_rounded,
                            label: 'day streak',
                            value: '${data.currentStreak}',
                          ),
                          const SizedBox(width: 10),
                          MetricTile(
                            icon: Icons.fitness_center_rounded,
                            label: 'workouts',
                            value: '${data.workouts}',
                          ),
                          const SizedBox(width: 10),
                          MetricTile(
                            icon: Icons.tune_rounded,
                            label: 'baselines',
                            value: '${baseline.readyGames}/15',
                          ),
                        ],
                      ),
                      if (baseline.isComplete) ...[
                        const SectionHeader('Recommended practice'),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Based on your least-trained recent skills',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              for (final recommendation
                                  in review.recommendations)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: GameIcon(
                                    game: recommendation.game,
                                    decorated: true,
                                  ),
                                  title: Text(recommendation.game.title),
                                  subtitle: Text(
                                    '${recommendation.game.domain} · ${recommendation.reason}',
                                  ),
                                ),
                              const Text(
                                'Open Train to start a Standard session.',
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SectionHeader("Today's goals"),
                      ...data.missions.map(
                        (mission) => _mission(context, mission),
                      ),
                      const SectionHeader('This week'),
                      _weekStrip(context, data),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workoutCard(BuildContext context, BrainState data, bool done) =>
      AppCard(
        tonal: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageEyebrow(
              done
                  ? 'Practice complete'
                  : data.draft != null
                  ? 'Continue where you left off'
                  : "Today's practice",
            ),
            const SizedBox(height: 12),
            Text(
              done
                  ? 'Five research-informed tasks trained today'
                  : '5 of 15 rotating tasks · about 5 minutes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('A balanced three-workout cycle covers every game.'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final game
                    in data.draft?.order ?? dailyOrderForWorkout(data.workouts))
                  Tooltip(
                    message: game.title,
                    child: GameIcon(game: game, decorated: true),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryAction(
              expanded: true,
              color: done ? context.brain.frame : context.brain.success,
              onPressed: done
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                    ),
              icon: data.draft == null
                  ? Icons.play_arrow_rounded
                  : Icons.replay_rounded,
              label: data.draft == null
                  ? 'Start practice'
                  : 'Continue practice',
            ),
          ],
        ),
      );

  Widget _baselineCard(
    BuildContext context,
    BaselineStatus baseline,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              baseline.isComplete ? Icons.insights_rounded : Icons.tune_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                baseline.isComplete
                    ? 'Personal baseline ready'
                    : 'Building your personal baseline',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text('${baseline.readyGames}/${activeGames.length} games'),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: baseline.required == 0
              ? 0
              : baseline.completed / baseline.required,
        ),
        const SizedBox(height: 10),
        Text(
          baseline.isComplete
              ? 'Insights compare you with your own compatible sessions.'
              : '${baseline.remaining} more compatible game round${baseline.remaining == 1 ? '' : 's'} across the rotation. Each game unlocks its own baseline after three rounds.',
        ),
      ],
    ),
  );

  Widget _mission(BuildContext context, Mission mission) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            mission.complete ? Icons.check_circle : Icons.adjust,
            color: mission.complete ? context.brain.success : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('${mission.progress} of ${mission.target} complete'),
              ],
            ),
          ),
          if (mission.complete && !mission.claimed)
            TextButton(
              onPressed: () =>
                  context.read<BrainCubit>().claimMission(mission.id),
              child: const Text('Collect'),
            ),
        ],
      ),
    ),
  );

  Widget _weekStrip(BuildContext context, BrainState data) {
    final now = DateTime.now();
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = now.subtract(Duration(days: now.weekday - 1 - index));
          final date = localDate(day);
          final complete = data.daily.any((summary) => summary.date == date);
          final isToday = date == localDate();
          return Semantics(
            label:
                '${DateFormat.EEEE().format(day)}, ${complete ? 'complete' : 'not complete'}',
            child: Column(
              children: [
                Text(DateFormat.E().format(day).substring(0, 1)),
                const SizedBox(height: 6),
                Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete
                        ? context.brain.success.withValues(alpha: .24)
                        : null,
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    complete ? Icons.check_rounded : Icons.remove_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
