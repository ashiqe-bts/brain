import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/game_catalog.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import 'progress_chart.dart';
import '../games/game_experience.dart';

class SessionResultScreen extends StatefulWidget {
  const SessionResultScreen({
    super.key,
    required this.result,
    this.actionLabel = AppText.backToTrain,
  });

  final GameResult result;
  final String actionLabel;

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen> {
  late GameMetricDefinition selectedMetric;

  @override
  void initState() {
    super.initState();
    selectedMetric = gameMetricDefinitions(widget.result.type).first;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final metrics = gameMetricDefinitions(
      widget.result.type,
    ).where((metric) => metric.value(widget.result) != null).toList();
    final comparison = sessionComparison(
      result: widget.result,
      history: data.history,
      daily: data.daily,
    );
    final points = progressPoints(
      game: widget.result.type,
      metric: selectedMetric,
      history: data.history,
      currentOverlay: widget.result.contributesToTrends ? null : widget.result,
    );
    final previous = _previousResult(data.history);
    final baseline = _baselineValue(data.history);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppText.workout.sessionReview),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                PageEyebrow(AppText.results.roundComplete),
                const SizedBox(height: 14),
                Center(
                  child: GameIcon(
                    game: widget.result.type,
                    size: 38,
                    decorated: true,
                    semantic: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.result.type.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.result.mode == GameMode.relaxed
                      ? AppText.results.relaxed
                      : selfComparisonMessage(
                          comparison,
                          currentAt:
                              widget.result.completedAt ?? DateTime.now(),
                        ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                AppCard(
                  tonal: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageEyebrow(AppText.results.current),
                      const SizedBox(height: 8),
                      Text(
                        selectedMetric.formatValue(widget.result),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: context.gameAccent(widget.result.type),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(selectedMetric.label),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ComparisonTile(
                            label: AppText.results.previous,
                            value: previous == null
                                ? AppText.results.unavailable
                                : selectedMetric.formatValue(previous),
                          ),
                          _ComparisonTile(
                            label: AppText.results.baselineMedian,
                            value: baseline == null
                                ? AppText.afterBaselineResults()
                                : _formatNumber(baseline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionHeader(AppText.results.progressGraph),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final metric in metrics)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(metric.label),
                            selected: selectedMetric.key == metric.key,
                            onSelected: (_) =>
                                setState(() => selectedMetric = metric),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: ProgressLineChart(
                    valueLabel: selectedMetric.label,
                    minimum:
                        selectedMetric.key ==
                            GameMetricDefinition.trainingLevelKey
                        ? AppSettings.minimumDifficulty.toDouble()
                        : selectedMetric.percent
                        ? 0
                        : null,
                    maximum:
                        selectedMetric.key ==
                            GameMetricDefinition.trainingLevelKey
                        ? AppSettings.maximumDifficulty.toDouble()
                        : selectedMetric.percent
                        ? 100
                        : null,
                    series: [
                      ProgressChartSeries(
                        label: widget.result.type.title,
                        color: context.gameAccent(widget.result.type),
                        points: [
                          for (final point in points)
                            ProgressChartPoint(
                              at: point.result.completedAt ?? DateTime.now(),
                              value: point.value,
                              label: selectedMetric.formatValue(point.result),
                              note: !point.includedInTrend
                                  ? widget.result.mode == GameMode.relaxed
                                        ? AppText.results.relaxedNote
                                        : AppText.results.challengeNote
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionHeader(AppText.results.measuredSkills),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final metric in metrics)
                      _MetricTile(
                        label: metric.label,
                        value: metric.formatValue(widget.result),
                        direction: metric.direction,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(child: Text(sessionTip(widget.result))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: CelebrationOverlay(level: CelebrationLevel.round),
          ),
        ],
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
                  icon: Icons.arrow_forward_rounded,
                  label: widget.actionLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GameResult? _previousResult(List<GameResult> history) {
    final currentAt = widget.result.completedAt;
    final candidates = history.where((result) {
      return result.type == widget.result.type &&
          result.rulesVersion == widget.result.rulesVersion &&
          result.mode != GameMode.relaxed &&
          result.completedAt != null &&
          (currentAt == null || result.completedAt!.isBefore(currentAt));
    }).toList()..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return candidates.firstOrNull;
  }

  double? _baselineValue(List<GameResult> history) {
    final values =
        history
            .where(
              (result) =>
                  result.type == widget.result.type &&
                  result.rulesVersion == widget.result.rulesVersion &&
                  result.mode == GameMode.official &&
                  result.completedAt != null &&
                  selectedMetric.value(result) != null,
            )
            .toList()
          ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    if (values.length < AppSettings.baselineSessionCount) return null;
    final first =
        values
            .take(AppSettings.baselineSessionCount)
            .map((result) => selectedMetric.value(result)!)
            .toList()
          ..sort();
    return first.length.isOdd
        ? first[first.length ~/ 2]
        : (first[first.length ~/ 2 - 1] + first[first.length ~/ 2]) / 2;
  }

  String _formatNumber(double value) {
    if (selectedMetric.percent) return '${value.round()}%';
    if (selectedMetric.unit.isNotEmpty) {
      return '${value.round()} ${selectedMetric.unit}';
    }
    return value.toStringAsFixed(selectedMetric.decimals);
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 132),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.brain.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.brain.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.brain.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.direction,
  });

  final String label;
  final String value;
  final MetricDirection direction;

  @override
  Widget build(BuildContext context) => Container(
    width: 158,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.brain.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.brain.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.brain.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(switch (direction) {
          MetricDirection.higherIsBetter => AppText.results.higherBetter,
          MetricDirection.lowerIsBetter => AppText.results.lowerBetter,
          MetricDirection.neutral => AppText.results.contextMeasure,
        }, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
