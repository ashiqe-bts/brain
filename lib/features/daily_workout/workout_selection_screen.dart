import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
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
      appBar: AppBar(title: const Text('Choose today’s five')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ResponsiveContent(
                maxWidth: 820,
                child: Column(
                  children: [
                    Text(
                      '${selected.length} of 5 selected',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick any five different games, or let BrainFlex create a balanced mix.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        selected
                          ..clear()
                          ..addAll(coverageAwareDailySelection(data.history));
                      }),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(
                        selected.isEmpty ? 'Random 5' : 'Reshuffle 5',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: activeGames.length,
                itemBuilder: (context, index) {
                  final game = activeGames[index];
                  final chosen = selected.contains(game);
                  final progress = baseline.forGame(game);
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          color: chosen ? context.brain.surfaceHigh : null,
                          onTap: chosen || selected.length < 5
                              ? () => setState(() {
                                  chosen
                                      ? selected.remove(game)
                                      : selected.add(game);
                                })
                              : null,
                          child: Semantics(
                            selected: chosen,
                            button: true,
                            label:
                                '${game.title}, ${game.domain}, level ${data.difficulties[game.name] ?? 1}, baseline ${progress.completed} of 3',
                            child: CheckboxListTile(
                              value: chosen,
                              onChanged: chosen || selected.length < 5
                                  ? (_) => setState(() {
                                      chosen
                                          ? selected.remove(game)
                                          : selected.add(game);
                                    })
                                  : null,
                              secondary: GameIcon(game: game, decorated: true),
                              title: Text(
                                game.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ResponsiveContent(
                maxWidth: 820,
                child: PrimaryAction(
                  expanded: true,
                  color: context.brain.success,
                  onPressed: selected.length == 5 ? _start : null,
                  icon: Icons.play_arrow_rounded,
                  label: 'Start selected workout',
                ),
              ),
            ),
          ],
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
