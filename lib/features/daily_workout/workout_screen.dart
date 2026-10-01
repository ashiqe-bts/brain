import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../games/game_launcher.dart';
import '../progress/session_result_screen.dart';

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
          () => status = AppText.workoutStatus(
            type.domain,
            index + 1,
            draft.order.length,
          ),
        );
      }
      if (!mounted) return;
      final result = await launchGameSession(
        context: context,
        type: type,
        mode: GameMode.official,
        difficulty: cubit.data.difficulties[type.name] ?? 1,
        randomSeed: stableSeed(
          '${draft.date}|${type.name}|${cubit.data.difficulties[type.name] ?? 1}|${type.rulesVersion}',
        ),
      );
      if (result == null) {
        if (mounted) setState(() => running = false);
        return;
      }
      await cubit.recordResult(result);
      draft = cubit.data.draft!;
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionResultScreen(
            result: result,
            actionLabel: index == draft.order.length - 1
                ? AppText.workout.finish
                : AppText.continueToGame(index + 2),
          ),
        ),
      );
      if (!mounted) return;
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
    final total = draft?.order.length ?? AppSettings.workoutGameCount;
    final displayRound = total == 0 ? 0 : (complete + 1).clamp(1, total);
    final nextGame = draft != null && complete < draft.order.length
        ? draft.order[complete]
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(AppText.workout.dailyPractice)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              SizedBox.square(
                dimension: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 132,
                      child: CircularProgressIndicator(
                        value: total == 0 ? 0 : complete / total,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: context.brain.success,
                        backgroundColor: context.brain.hud,
                      ),
                    ),
                    if (nextGame != null)
                      GameIcon(
                        game: nextGame,
                        size: 42,
                        decorated: true,
                        semantic: true,
                      )
                    else
                      Icon(
                        Icons.check_rounded,
                        size: 46,
                        color: context.brain.success,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PageEyebrow(AppText.roundProgress(displayRound, total)),
              const SizedBox(height: 8),
              Text(
                nextGame?.title ?? AppText.workout.dailyWorkout,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status ?? AppText.workout.dailyReset,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.brain.textMuted),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  total,
                  (index) => AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    width: index == complete ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index < complete
                          ? context.brain.success
                          : index == complete
                          ? context.brain.primary
                          : context.brain.frame,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (!running)
                PrimaryAction(
                  onPressed: _run,
                  icon: Icons.play_arrow,
                  label: AppText.workout.resume,
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
        title: Text(AppText.workout.sessionReview),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.brain.success.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: context.brain.success,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppText.workout.completeTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              baselineStatus(data.history).isComplete
                  ? AppText.workout.compatibleResults
                  : AppText.readyGameBaselines(
                      baselineStatus(data.history).readyGames,
                      activeGames.length,
                    ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppCard(
              tonal: true,
              child: Column(
                children: [
                  for (final (index, result) in summary.results.indexed) ...[
                    if (index > 0) const Divider(height: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GameIcon(
                              game: result.type,
                              size: 26,
                              decorated: true,
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
                              trainingLevel(
                                difficulty: result.difficulty,
                                score: result.normalized,
                              ).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(AppText.workout.resultDisclaimer, textAlign: TextAlign.center),
          ],
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
                constraints: const BoxConstraints(
                  maxWidth: AppSettings.resultContentWidth,
                ),
                child: PrimaryAction(
                  expanded: true,
                  color: context.brain.success,
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.done_rounded,
                  label: AppText.workout.done,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _rawMetrics(GameResult result) {
    final accuracy = AppText.accuracy((result.accuracy * 100).round());
    if (result.type == GameType.reflexTap && result.reactionMs != null) {
      return '$accuracy · ${AppText.medianReaction(result.reactionMs!)}';
    }
    final falseStarts = result.metrics['falseStarts']?.round() ?? 0;
    if (result.type == GameType.signalStop) {
      return '$accuracy · ${AppText.falseStarts(falseStarts)}';
    }
    final span = result.metrics['span']?.round() ?? 0;
    if (span > 0 &&
        const {
          GameType.memoryTiles,
          GameType.nBackNavigator,
          GameType.pairLink,
          GameType.objectTracker,
          GameType.towerPlanner,
        }.contains(result.type)) {
      return '$accuracy · ${AppText.span(span)}';
    }
    final response = result.metrics['medianResponseMs']?.round() ?? 0;
    return response > 0
        ? '$accuracy · ${AppText.medianResponse(response)}'
        : accuracy;
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
        ? AppText.baselinePending()
        : AppText.baselineChange(delta(comparison.baselineDelta!));
    final previous = selfComparisonMessage(
      comparison,
      currentAt: result.completedAt ?? DateTime.now(),
    );
    return '$baseline\n$previous';
  }
}
