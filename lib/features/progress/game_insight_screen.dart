import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/game_catalog.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import 'progress_chart.dart';

class GameInsightScreen extends StatefulWidget {
  const GameInsightScreen({super.key, required this.game});

  final GameType game;

  @override
  State<GameInsightScreen> createState() => _GameInsightScreenState();
}

class _GameInsightScreenState extends State<GameInsightScreen> {
  late GameMetricDefinition selectedMetric;

  @override
  void initState() {
    super.initState();
    selectedMetric = gameMetricDefinitions(widget.game).first;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final trend = skillTrend(widget.game, data.history);
    final metrics = gameMetricDefinitions(widget.game).where((metric) {
      return data.history.any(
        (result) => result.type == widget.game && metric.value(result) != null,
      );
    }).toList();
    if (!metrics.any((metric) => metric.key == selectedMetric.key)) {
      metrics.insert(0, selectedMetric);
    }
    final points = progressPoints(
      game: widget.game,
      metric: selectedMetric,
      history: data.history,
    );
    final baseline = baselineStatus(data.history).forGame(widget.game);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.title} insights')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GameIcon(
                  game: widget.game,
                  size: 34,
                  decorated: true,
                  semantic: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.domain,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${trend.samples} comparable sessions · Baseline ${baseline.completed}/3',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SectionHeader('Metric'),
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
                    selectedMetric.key == GameMetricDefinition.trainingLevelKey
                    ? 1
                    : selectedMetric.percent
                    ? 0
                    : null,
                maximum:
                    selectedMetric.key == GameMetricDefinition.trainingLevelKey
                    ? 10
                    : selectedMetric.percent
                    ? 100
                    : null,
                series: [
                  ProgressChartSeries(
                    label: widget.game.title,
                    color: context.gameAccent(widget.game),
                    points: [
                      for (final point in points)
                        ProgressChartPoint(
                          at: point.result.completedAt!,
                          value: point.value,
                          label: selectedMetric.formatValue(point.result),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              tonal: true,
              child: Text(
                trend.direction == TrendDirection.insufficient
                    ? 'Complete at least three post-baseline comparable sessions before BrainFlex labels a direction.'
                    : '${trend.delta >= 0 ? '+' : ''}${trend.delta.toStringAsFixed(1)} levels from your baseline median. Rolling medians reduce the effect of one unusually fast or slow day.',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Charts describe performance in this practiced task and are not a medical or IQ assessment.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
