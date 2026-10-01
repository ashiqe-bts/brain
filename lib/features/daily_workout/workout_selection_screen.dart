import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
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
  final selected = <GameType>{};

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final baseline = baselineStatus(data.history);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily workout')),
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          itemCount: activeGames.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ResponsiveContent(
                maxWidth: 820,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build your daily mix',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose 5 games',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.brain.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    selected.length /
                                    AppSettings.workoutGameCount,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selected.length} / ${AppSettings.workoutGameCount}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          selected
                            ..clear()
                            ..addAll(coverageAwareDailySelection(data.history));
                        }),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          selected.isEmpty ? 'Random 5' : 'Reshuffle 5',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final gameIndex = index - 1;
            final game = activeGames[gameIndex];
            final chosen = selected.contains(game);
            final progress = baseline.forGame(game);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: chosen
                        ? context.brain.surfaceHigh
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Semantics(
                      selected: chosen,
                      button: true,
                      label:
                          '${game.title}, ${game.domain}, level ${data.difficulties[game.name] ?? 1}, baseline ${progress.completed} of 3',
                      child: CheckboxListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        value: chosen,
                        onChanged:
                            chosen ||
                                selected.length < AppSettings.workoutGameCount
                            ? (_) => setState(() {
                                chosen
                                    ? selected.remove(game)
                                    : selected.add(game);
                              })
                            : null,
                        secondary: GameIcon(game: game, decorated: true),
                        title: Text(
                          game.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${game.domain} · Level ${data.difficulties[game.name] ?? 1} · Baseline ${progress.completed}/3',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.brain.background,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: PrimaryAction(
                  expanded: true,
                  color: context.brain.success,
                  onPressed: selected.length == AppSettings.workoutGameCount
                      ? _start
                      : null,
                  icon: Icons.play_arrow_rounded,
                  label: 'Start workout',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final cubit = context.read<BrainCubit>();
    await cubit.startWorkout(order: selected.toList());
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
    );
  }
}
