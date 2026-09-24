import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../games/game_screen.dart';
import '../../app/theme/brain_theme.dart';

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
    for (var i = draft.results.length; i < draft.order.length; i++) {
      final type = draft.order[i];
      if (mounted) {
        setState(
          () => status = dailyModifier(draft.date) == 'Mystery'
              ? 'Mystery challenge ${i + 1} of 5'
              : 'Challenge ${i + 1} of 5 · ${type.title}',
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
            modifier: dailyModifier(draft.date),
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
    return Scaffold(
      appBar: AppBar(title: const Text('DAILY QUEST')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              TitlePlaque('${dailyModifier(localDate())} modifier'),
              const SizedBox(height: 14),
              Text(
                status ?? 'Five quick challenges',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text('$complete / 5 complete'),
              const SizedBox(height: 20),
              ResourceBar(
                label: 'Quest progress',
                value: complete / 5,
                color: context.brain.success,
                trailing: '$complete / 5',
              ),
              const Spacer(),
              BrainCard(
                style: GamePanelStyle.inset,
                child: Icon(
                  Icons.bolt_rounded,
                  size: 110,
                  color: context.rewardInk,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Every round is saved when it ends. You can safely leave and continue later.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (!running)
                ArcadeButton(
                  onPressed: _run,
                  icon: Icons.play_arrow,
                  label: 'RESUME QUEST',
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
    final previous = data.daily.where((e) => e.date != summary.date).lastOrNull;
    final delta = previous == null
        ? null
        : summary.brainScore - previous.brainScore;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('QUEST COMPLETE'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: TitlePlaque('Victory!')),
            const SizedBox(height: 8),
            const Text(
              "TODAY'S BRAIN SCORE",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            Text(
              '${summary.brainScore}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            if (delta != null)
              Text(
                '${delta >= 0 ? '+' : ''}$delta compared with your previous workout',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 22),
            BrainCard(
              child: Column(
                children: [
                  _bar(context, 'Focus', summary.focus),
                  _bar(context, 'Memory', summary.memory),
                  _bar(context, 'Speed', summary.speed),
                  _bar(context, 'Math', summary.math),
                  _bar(context, 'Accuracy', summary.accuracy),
                  if (summary.reactionMs != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt),
                      title: const Text('Reaction median'),
                      trailing: Text(
                        '${summary.reactionMs} ms',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Brain Score reflects your game performance and personal progress. It is not an IQ score or medical assessment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ArcadeButton(
              expanded: true,
              color: context.brain.success,
              onPressed: () => Navigator.pop(context),
              icon: Icons.redeem_rounded,
              label: 'COLLECT 100 XP',
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext c, String name, int v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(width: 76, child: Text(name)),
        Expanded(
          child: ResourceBar(label: '', value: v / 100),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            '$v',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
