import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';
import '../../app/theme/game_visuals.dart';
import 'game_launcher.dart';
import 'research_basis_sheet.dart';
import '../progress/session_result_screen.dart';

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
      appBar: AppBar(toolbarHeight: 70, title: Text(AppText.navigation.train)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                children: [
                  Center(child: PageEyebrow(AppText.train.chooseGame)),
                  const SizedBox(height: 14),
                  Text(AppText.train.intro, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  Semantics(
                    label: AppText.train.filterSemantics,
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
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSettings.trainContentWidth,
                      ),
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
      final wide = box.maxWidth >= AppSettings.gameGridBreakpoint;
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppText.gameLevel(game.domain, difficulty),
                      style: TextStyle(color: context.brain.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: AppText.playGame(game.title),
                onPressed: () => _chooseMode(context, game),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            best == null
                ? AppText.train.firstResult
                : AppText.personalLevel(
                    trainingLevel(
                      difficulty: best.difficulty,
                      score: best.normalized,
                    ).toStringAsFixed(1),
                    (best.accuracy * 100).round(),
                  ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            children: [
              Tooltip(
                message: AppText.tutorialFor(game.title),
                child: TextButton.icon(
                  onPressed: () => replayGameTutorial(context, game),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(AppText.train.tutorial),
                ),
              ),
              Tooltip(
                message: AppText.researchFor(game.title),
                child: TextButton.icon(
                  onPressed: () => showResearchBasisSheet(context, game),
                  icon: const Icon(Icons.science_outlined),
                  label: Text(AppText.train.researchBasis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _domainLabel(SkillDomain domain) =>
      AppText.skillDomainLabels[domain.name]!;

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
                  AppText.gameModeLabels[GameMode.standard.name]!,
                  AppText.train.standardBody,
                ),
                (
                  GameMode.personalBest,
                  AppText.gameModeLabels[GameMode.personalBest.name]!,
                  AppText.train.personalBestBody,
                ),
                (
                  GameMode.relaxed,
                  AppText.gameModeLabels[GameMode.relaxed.name]!,
                  AppText.train.relaxedBody,
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
    await cubit.recordResult(result);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionResultScreen(result: result)),
    );
  }
}
