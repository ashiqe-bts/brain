import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/training/game_catalog.dart';
import '../../core/widgets/common.dart';
import '../games/research_basis_sheet.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int monthOffset = 0;
  SkillDomain? selectedDomain;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final baseline = baselineStatus(data.history);
    final review = weeklyReview(daily: data.daily, history: data.history);
    final domains = activeGames.map((game) => game.skill).toSet().toList();
    return Scaffold(
      appBar: AppBar(toolbarHeight: 70, title: const Text('Insights')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    _baseline(context, baseline),
                    const SectionHeader('Fifteen-game profile'),
                    Semantics(
                      label: 'Filter insights by cognitive domain',
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: selectedDomain == null,
                            onSelected: (_) =>
                                setState(() => selectedDomain = null),
                          ),
                          for (final domain in domains)
                            FilterChip(
                              label: Text(_domainLabel(domain)),
                              selected: selectedDomain == domain,
                              onSelected: (_) =>
                                  setState(() => selectedDomain = domain),
                            ),
                        ],
                      ),
                    ),
                    for (final domain in domains)
                      if (selectedDomain == null ||
                          selectedDomain == domain) ...[
                        SectionHeader(_domainLabel(domain)),
                        ...activeGames
                            .where((game) => game.skill == domain)
                            .map(
                              (game) => _skillCard(
                                context,
                                game,
                                review.trends[game]!,
                                data,
                              ),
                            ),
                      ],
                    const SectionHeader('Weekly review'),
                    _weeklyReview(context, review, baseline.isComplete),
                    const SectionHeader('Recent sessions'),
                    _history(context, data),
                    const SectionHeader('Activity calendar'),
                    AppCard(child: _calendar(context, data)),
                    const SectionHeader('Achievements'),
                    _achievements(context, data),
                    const SizedBox(height: 16),
                    const Text(
                      'BrainFlex measures practice performance in these tasks. It does not measure IQ, diagnose a condition, or prove changes in everyday cognition.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baseline(BuildContext context, BaselineStatus baseline) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                baseline.isComplete
                    ? 'All game baselines complete'
                    : '${baseline.readyGames} of ${activeGames.length} game baselines ready',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: baseline.completed / baseline.required),
        const SizedBox(height: 10),
        Text(
          baseline.isComplete
              ? 'Trends use comparable, versioned sessions and rolling medians.'
              : '${baseline.remaining} compatible game round${baseline.remaining == 1 ? '' : 's'} remain. Individual games unlock after three official results.',
        ),
      ],
    ),
  );

  Widget _skillCard(
    BuildContext context,
    GameType game,
    SkillTrend trend,
    BrainState data,
  ) {
    final eligible =
        data.history
            .where(
              (result) => result.type == game && result.contributesToTrends,
            )
            .where((result) => result.rulesVersion == game.rulesVersion)
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? DateTime(1970)).compareTo(
              a.completedAt ?? DateTime(1970),
            ),
          );
    final latest = eligible.firstOrNull;
    final (icon, label) = switch (trend.direction) {
      TrendDirection.improving => (Icons.trending_up_rounded, 'Improving'),
      TrendDirection.needsAttention => (
        Icons.trending_down_rounded,
        'Needs attention',
      ),
      TrendDirection.stable => (Icons.trending_flat_rounded, 'Steady'),
      TrendDirection.insufficient => (
        Icons.more_horiz_rounded,
        'More sessions needed',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameIcon(game: game, size: 28, decorated: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${game.domain} · ${trend.samples} comparable sessions',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Research basis for ${game.title}',
                  onPressed: () => showResearchBasisSheet(context, game),
                  icon: const Icon(Icons.science_outlined),
                ),
                Icon(icon),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              latest == null
                  ? 'No comparable result yet'
                  : 'Training level ${trainingLevel(difficulty: latest.difficulty, score: latest.normalized).toStringAsFixed(1)} · ${(latest.accuracy * 100).round()}% accuracy${_metric(latest)}',
            ),
            if (trend.direction != TrendDirection.insufficient)
              Text(
                '${trend.delta >= 0 ? '+' : ''}${trend.delta.toStringAsFixed(1)} levels from your baseline median',
              ),
          ],
        ),
      ),
    );
  }

  String _domainLabel(SkillDomain domain) => switch (domain) {
    SkillDomain.focus => 'Focus and attention',
    SkillDomain.calculation => 'Calculation',
    SkillDomain.memory => 'Memory',
    SkillDomain.reaction => 'Reaction',
    SkillDomain.visualSearch => 'Visual search',
    SkillDomain.executiveControl => 'Executive control',
    SkillDomain.processingSpeed => 'Processing speed',
    SkillDomain.reasoning => 'Reasoning and planning',
    SkillDomain.spatial => 'Spatial reasoning',
  };

  String _metric(GameResult result) {
    if (result.type == GameType.reflexTap && result.reactionMs != null) {
      return ' · ${result.reactionMs} ms median';
    }
    return gameDefinition(result.type).rawMetricFormatter(result.metrics);
  }

  Widget _weeklyReview(
    BuildContext context,
    WeeklyReview review,
    bool baselineReady,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${review.workouts} workout${review.workouts == 1 ? '' : 's'} in the last 7 days',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          baselineReady
              ? 'Next week, prioritize ${review.recommendations.map((item) => item.game.domain).join(' and ')}.'
              : 'Recommendations unlock after all per-game baselines are ready.',
        ),
        const SizedBox(height: 8),
        const Text(
          'A single fast or slow day is normal. BrainFlex waits for repeated comparable results before labeling a trend.',
        ),
      ],
    ),
  );

  Widget _history(BuildContext context, BrainState data) {
    final recent = data.history.where((result) => !result.isLegacy).toList()
      ..sort(
        (a, b) => (b.completedAt ?? DateTime(1970)).compareTo(
          a.completedAt ?? DateTime(1970),
        ),
      );
    if (recent.isEmpty) {
      return const AppCard(
        child: Text(
          'Complete a Standard or daily session to start your history.',
        ),
      );
    }
    return AppCard(
      child: Column(
        children: recent.take(20).map((result) {
          final time = result.completedAt?.toLocal();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: GameIcon(game: result.type, decorated: true),
            title: Text(result.type.title),
            subtitle: Text(
              '${result.mode.displayTitle} · ${time == null ? 'Earlier version' : DateFormat.MMMd().add_jm().format(time)}',
            ),
            trailing: Text(
              trainingLevel(
                difficulty: result.difficulty,
                score: result.normalized,
              ).toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _calendar(BuildContext context, BrainState data) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month + monthOffset);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final start = DateTime(month.year, month.month, 1).weekday - 1;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(() => monthOffset--),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM().format(month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: monthOffset < 0
                  ? () => setState(() => monthOffset++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: start + days,
          itemBuilder: (context, index) {
            if (index < start) return const SizedBox();
            final day = index - start + 1;
            final date = localDate(DateTime(month.year, month.month, day));
            final complete = data.daily.any((summary) => summary.date == date);
            final today = date == localDate();
            return Semantics(
              label: '$date, ${complete ? 'workout complete' : 'no workout'}',
              child: Container(
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete
                      ? context.brain.success.withValues(alpha: .25)
                      : null,
                  border: today
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Text(complete ? '✓' : '$day'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _achievements(BuildContext context, BrainState data) {
    const all = {
      'First Spark': 'Complete your first workout',
      'One Week Strong': 'Maintain a 7-day streak',
      'Lightning Fingers': 'React in under 250 ms',
      'Memory Machine': 'Perfect five Memory Tiles rounds',
      'Math Wizard': 'Get 25 Calculation answers correct',
      'Unstoppable': 'Reach a 30-day streak',
      'Perfectionist': 'Finish a workout above 95% accuracy',
    };
    return AppCard(
      child: Column(
        children: all.entries.map((entry) {
          final earned = data.achievements.contains(entry.key);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              earned ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            ),
            title: Text(entry.key),
            subtitle: Text(entry.value),
            trailing: earned ? const Text('Complete') : null,
          );
        }).toList(),
      ),
    );
  }
}
