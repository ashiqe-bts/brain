import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import 'game_launcher.dart';
import 'research_basis_sheet.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  SkillDomain? selectedDomain;

  @override
  Widget build(BuildContext context) {
    final domains = activeGames.map((game) => game.skill).toSet().toList();
    return Scaffold(
      appBar: AppBar(toolbarHeight: 70, title: const Text('TRAIN')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                children: [
                  const Center(child: PageEyebrow('Choose a challenge')),
                  const SizedBox(height: 14),
                  const Text(
                    'You vs you: each game compares only with your own compatible practice. Relaxed sessions never affect trends.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    label: 'Filter games by cognitive domain',
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
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        children: [
                          for (final domain in domains)
                            if (selectedDomain == null ||
                                selectedDomain == domain) ...[
                              SectionHeader(_domainLabel(domain)),
                              _gameGrid(
                                context,
                                activeGames
                                    .where((game) => game.skill == domain)
                                    .toList(),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameGrid(BuildContext context, List<GameType> games) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 680;
      return Wrap(
        spacing: 14,
        runSpacing: 16,
        children: games
            .map(
              (game) => SizedBox(
                width: wide ? (box.maxWidth - 14) / 2 : box.maxWidth,
                child: _gameCard(context, game),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _gameCard(BuildContext context, GameType game) {
    final cubit = context.read<BrainCubit>(), d = cubit.data;
    final difficulty = d.difficulties[game.name] ?? 1;
    final best = cubit.personalBest(
      game,
      GameMode.personalBest,
      difficulty: difficulty,
    );
    final accent = context.gameAccent(game);
    return AppCard(
      color: Color.lerp(accent, context.brain.surface, .68),
      child: Row(
        children: [
          GameIcon(game: game, size: 28, decorated: true),
          const SizedBox(width: 14),
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
                Text('${game.domain} · Level $difficulty'),
                Text(
                  best == null
                      ? 'No standard result yet'
                      : 'Training ${trainingLevel(difficulty: best.difficulty, score: best.normalized).toStringAsFixed(1)} · ${(best.accuracy * 100).round()}%',
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Research basis for ${game.title}',
            onPressed: () => showResearchBasisSheet(context, game),
            icon: const Icon(Icons.science_outlined),
          ),
          IconButton(
            tooltip: 'Tutorial for ${game.title}',
            onPressed: () => replayGameTutorial(context, game),
            icon: const Icon(Icons.school_outlined),
          ),
          IconButton(
            tooltip: 'Play ${game.title}',
            onPressed: () => _chooseMode(context, game),
            style: IconButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: context.onColor(accent),
              side: BorderSide(color: context.brain.outline, width: 2),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
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

  Future<void> _chooseMode(BuildContext context, GameType game) async {
    final mode = await showModalBottomSheet<GameMode>(
      context: context,
      showDragHandle: false,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: PageEyebrow(game.title, color: context.gameAccent(game)),
              ),
              const SizedBox(height: 18),
              ...[
                (
                  GameMode.standard,
                  'Standard',
                  'Comparable practice that contributes to skill trends',
                ),
                (
                  GameMode.personalBest,
                  'Challenge My Best',
                  'Challenge a result with matching rules and difficulty',
                ),
                (
                  GameMode.relaxed,
                  'Relaxed',
                  'Untimed practice that does not affect your trends',
                ),
              ].map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    onTap: () => Navigator.pop(context, m.$1),
                    child: Row(
                      children: [
                        Icon(
                          m.$1 == GameMode.relaxed
                              ? Icons.spa
                              : Icons.play_circle,
                          color: context.gameAccent(game),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.$2,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              Text(m.$3),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null || !context.mounted) return;
    final cubit = context.read<BrainCubit>();
    final difficulty = cubit.data.difficulties[game.name] ?? 1;
    final pb = cubit.personalBest(game, mode, difficulty: difficulty);
    final result = await launchGameSession(
      context: context,
      type: game,
      mode: mode,
      difficulty: difficulty,
      personalBest: pb,
    );
    if (result == null || !context.mounted) return;
    final comparison = mode == GameMode.relaxed
        ? null
        : sessionComparison(
            result: result,
            history: cubit.data.history,
            daily: cubit.data.daily,
          );
    await cubit.recordResult(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == GameMode.relaxed
              ? 'Relaxed practice complete · not added to trends'
              : selfComparisonMessage(
                  comparison!,
                  currentAt: result.completedAt ?? DateTime.now(),
                ),
        ),
      ),
    );
  }
}
