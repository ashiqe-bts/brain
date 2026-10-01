import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/training/game_catalog.dart';
import '../../core/widgets/common.dart';
import '../games/research_basis_sheet.dart';
import 'game_insight_screen.dart';
import 'progress_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int monthOffset = 0;
  SkillDomain? selectedDomain;
  final selectedGames = <GameType>{};
  bool overviewInitialized = false;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BrainCubit>().state.data;
    final baseline = baselineStatus(data.history);
    final review = weeklyReview(daily: data.daily, history: data.history);
    final domains = activeGames.map((game) => game.skill).toSet().toList();
    _initializeOverview(data.history);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(AppText.navigation.insights),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSettings.standardContentWidth,
                ),
                child: Column(
                  children: [
                    _baseline(context, baseline),
                    SectionHeader(AppText.progress.combined),
                    _overviewChart(context, data),
                    SectionHeader(AppText.progress.profile),
                    Semantics(
                      label: AppText.progress.filterSemantics,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: Text(AppText.train.all),
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
                    SectionHeader(AppText.progress.weeklyReview),
                    _weeklyReview(context, review, baseline.isComplete),
                    SectionHeader(AppText.progress.recentSessions),
                    _history(context, data),
                    SectionHeader(AppText.progress.activityCalendar),
                    AppCard(child: _calendar(context, data)),
                    SectionHeader(AppText.progress.achievements),
                    _achievements(context, data),
                    const SizedBox(height: 16),
                    Text(
                      AppText.progress.disclaimer,
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

  void _initializeOverview(List<GameResult> history) {
    if (overviewInitialized) return;
    final recent =
        history
            .where(
              (result) => result.contributesToTrends && result.type.isActive,
            )
            .toList()
          ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    for (final result in recent) {
      selectedGames.add(result.type);
      if (selectedGames.length == AppSettings.maximumOverviewGames) break;
    }
    if (selectedGames.isEmpty) {
      selectedGames.addAll(activeGames.take(AppSettings.maximumOverviewGames));
    }
    overviewInitialized = true;
  }

  Widget _overviewChart(BuildContext context, BrainState data) {
    final level = gameMetricDefinitions(GameType.colorClash).firstWhere(
      (metric) => metric.key == GameMetricDefinition.trainingLevelKey,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.progress.compareScale,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            AppText.progress.selectGames,
            style: TextStyle(color: context.brain.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeGames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final game = activeGames[index];
                final chosen = selectedGames.contains(game);
                return FilterChip(
                  avatar: Icon(gameVisualFor(game).icon, size: 18),
                  label: Text(game.title),
                  selected: chosen,
                  onSelected:
                      chosen ||
                          selectedGames.length <
                              AppSettings.maximumOverviewGames
                      ? (_) => setState(() {
                          if (chosen && selectedGames.length > 1) {
                            selectedGames.remove(game);
                          } else if (!chosen) {
                            selectedGames.add(game);
                          }
                        })
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          ProgressLineChart(
            valueLabel: AppText.metricTrainingLevel,
            minimum: 1,
            maximum: 10,
            series: [
              for (final game in selectedGames)
                ProgressChartSeries(
                  label: game.title,
                  color: context.gameAccent(game),
                  points: [
                    for (final point in progressPoints(
                      game: game,
                      metric: level,
                      history: data.history,
                    ))
                      ProgressChartPoint(
                        at: point.result.completedAt!,
                        value: point.value,
                        label: level.formatValue(point.result),
                      ),
                  ],
                ),
            ],
          ),
        ],
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
                    ? AppText.progress.allBaselines
                    : AppText.baselineReady(
                        baseline.readyGames,
                        activeGames.length,
                      ),
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
              ? AppText.progress.trendMethod
              : AppText.baselineRemaining(baseline.remaining),
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
      TrendDirection.improving => (
        Icons.trending_up_rounded,
        AppText.progress.improving,
      ),
      TrendDirection.needsAttention => (
        Icons.trending_down_rounded,
        AppText.progress.needsAttention,
      ),
      TrendDirection.stable => (
        Icons.trending_flat_rounded,
        AppText.progress.steady,
      ),
      TrendDirection.insufficient => (
        Icons.more_horiz_rounded,
        AppText.progress.moreNeeded,
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
                        AppText.comparableDomain(game.domain, trend.samples),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppText.researchFor(game.title),
                  onPressed: () => showResearchBasisSheet(context, game),
                  icon: const Icon(Icons.science_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 20, color: context.brain.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              latest == null
                  ? AppText.progress.noResult
                  : AppText.trainingResult(
                      trainingLevel(
                        difficulty: latest.difficulty,
                        score: latest.normalized,
                      ).toStringAsFixed(1),
                      (latest.accuracy * 100).round(),
                      _metric(latest),
                    ),
            ),
            if (trend.direction != TrendDirection.insufficient)
              Text(
                AppText.trendDelta(
                  '${trend.delta >= 0 ? '+' : ''}${trend.delta.toStringAsFixed(1)}',
                ),
              ),
            if (eligible.isNotEmpty) ...[
              const SizedBox(height: 10),
              ProgressSparkline(
                color: context.gameAccent(game),
                semanticLabel: AppText.chartSemantics(
                  game.title,
                  eligible.length,
                ),
                points: [
                  for (final result
                      in eligible.reversed
                          .take(AppSettings.maximumChartResults)
                          .toList()
                          .reversed)
                    ProgressChartPoint(
                      at: result.completedAt!,
                      value: trainingLevel(
                        difficulty: result.difficulty,
                        score: result.normalized,
                      ),
                      label: AppText.level(
                        trainingLevel(
                          difficulty: result.difficulty,
                          score: result.normalized,
                        ).toStringAsFixed(1),
                      ),
                    ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameInsightScreen(game: game),
                  ),
                ),
                icon: const Icon(Icons.show_chart_rounded),
                label: Text(AppText.progress.viewDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _domainLabel(SkillDomain domain) =>
      AppText.skillDomainLabels[domain.name]!;

  String _metric(GameResult result) {
    if (result.type == GameType.reflexTap && result.reactionMs != null) {
      return AppText.medianMilliseconds(result.reactionMs!);
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
          AppText.weeklyWorkouts(review.workouts),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          baselineReady
              ? AppText.nextWeek(
                  review.recommendations
                      .map((item) => item.game.domain)
                      .join(' and '),
                )
              : AppText.progress.recommendationsLocked,
        ),
        const SizedBox(height: 8),
        Text(AppText.progress.naturalVariation),
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
      return AppCard(child: Text(AppText.progress.emptyHistory));
    }
    return AppCard(
      child: Column(
        children: recent.take(AppSettings.maximumRecentSessions).map((result) {
          final time = result.completedAt?.toLocal();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: GameIcon(game: result.type, decorated: true),
            title: Text(result.type.title),
            subtitle: Text(
              AppText.sessionSubtitle(
                result.mode.displayTitle,
                time == null
                    ? AppText.progress.earlierVersion
                    : DateFormat.MMMd().add_jm().format(time),
              ),
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
              tooltip: AppText.progress.previousMonth,
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
              tooltip: AppText.progress.nextMonth,
              onPressed: monthOffset < 0
                  ? () => setState(() => monthOffset++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in AppText.calendarWeekdays)
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
              label: AppText.calendarDay(date, complete),
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
    const all = AppText.achievementDescriptions;
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
            trailing: earned ? Text(AppText.progress.complete) : null,
          );
        }).toList(),
      ),
    );
  }
}
