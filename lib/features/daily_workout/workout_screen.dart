import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../games/game_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool running = false;
  String? status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (running) return;
    setState(() => running = true);
    final cubit = context.read<BrainCubit>();
    await cubit.startWorkout();
    if (cubit.data.draft == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    var draft = cubit.data.draft!;
    for (
      var index = draft.results.length;
      index < draft.order.length;
      index++
    ) {
      final type = draft.order[index];
      if (mounted) {
        setState(
          () => status =
              '${type.domain} · round ${index + 1} of ${draft.order.length}',
        );
      }
      if (!mounted) return;
      final result = await Navigator.push<GameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            type: type,
            mode: GameMode.official,
            difficulty: cubit.data.difficulties[type.name] ?? 1,
            randomSeed: stableSeed(
              '${draft.date}|${type.name}|${cubit.data.difficulties[type.name] ?? 1}|2',
            ),
          ),
        ),
      );
      if (result == null) {
        if (mounted) setState(() => running = false);
        return;
      }
      await cubit.recordResult(result);
      draft = cubit.data.draft!;
    }
    final summary = await cubit.completeWorkout();
    if (summary != null && mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutResultScreen(summary: summary),
        ),
      );
    } else if (mounted) {
      setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BrainCubit>().state.data.draft;
    final complete = draft?.results.length ?? 0;
    final total = draft?.order.length ?? GameType.values.length;
    return Scaffold(
      appBar: AppBar(title: const Text('DAILY TRAINING')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.fitness_center_rounded, size: 72),
              const SizedBox(height: 18),
              Text(
                status ?? 'Five standardized skill rounds',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              ResourceBar(
                label: 'Workout progress',
                value: total == 0 ? 0 : complete / total,
                color: context.brain.success,
                trailing: '$complete / $total',
              ),
              const SizedBox(height: 20),
              const Text(
                'Each completed round is saved. You can safely leave and continue later.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (!running)
                ArcadeButton(
                  onPressed: _run,
                  icon: Icons.play_arrow,
                  label: 'RESUME WORKOUT',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutResultScreen extends StatelessWidget {
  const WorkoutResultScreen({super.key, required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SESSION REVIEW'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.check_circle_rounded, size: 72),
            const SizedBox(height: 12),
            Text(
              'Daily training complete',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              baselineStatus(data.daily).isComplete
                  ? 'Results are compared only with compatible sessions.'
                  : 'Baseline ${baselineStatus(data.daily).completed} of 3 complete.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final result in summary.results)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BrainCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            result.type.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result.type.domain,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            'Level ${trainingLevel(difficulty: result.difficulty, score: result.normalized).toStringAsFixed(1)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_rawMetrics(result)),
                      const SizedBox(height: 6),
                      Text(_comparison(result, data)),
                      const SizedBox(height: 6),
                      Text(sessionTip(result)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'These results describe performance in BrainFlex tasks, not IQ or a medical assessment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ArcadeButton(
              expanded: true,
              color: context.brain.success,
              onPressed: () => Navigator.pop(context),
              icon: Icons.done_rounded,
              label: 'DONE',
            ),
          ],
        ),
      ),
    );
  }

  String _rawMetrics(GameResult result) {
    final accuracy = '${(result.accuracy * 100).round()}% accuracy';
    if (result.type == GameType.reflexTap && result.reactionMs != null) {
      return '$accuracy · ${result.reactionMs} ms median reaction';
    }
    final span = result.metrics['span']?.round() ?? 0;
    if (result.type == GameType.memoryTiles && span > 0) {
      return '$accuracy · span $span';
    }
    final response = result.metrics['medianResponseMs']?.round() ?? 0;
    return response > 0 ? '$accuracy · $response ms median response' : accuracy;
  }

  String _comparison(GameResult result, BrainState data) {
    final comparison = sessionComparison(
      result: result,
      history: data.history,
      daily: data.daily,
    );
    String delta(double value) =>
        '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';
    final baseline = comparison.baselineDelta == null
        ? 'Baseline change: available after 3 compatible daily results'
        : 'Baseline change: ${delta(comparison.baselineDelta!)} levels';
    final previous = comparison.previousDelta == null
        ? 'Previous change: no earlier compatible attempt'
        : 'Previous change: ${delta(comparison.previousDelta!)} levels';
    return '$baseline\n$previous';
  }
}
