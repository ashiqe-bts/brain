import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/training/training_analytics.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';
import 'game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
                  const Center(child: TitlePlaque('Choose a challenge')),
                  const SizedBox(height: 14),
                  const Text(
                    'Standard sessions contribute to your skill trends. Relaxed practice is never scored.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final wide = box.maxWidth >= 680;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 16,
                            children: GameType.values
                                .map(
                                  (g) => SizedBox(
                                    width: wide
                                        ? (box.maxWidth - 14) / 2
                                        : box.maxWidth,
                                    child: _gameCard(context, g),
                                  ),
                                )
                                .toList(),
                          );
                        },
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

  Widget _gameCard(BuildContext context, GameType game) {
    final cubit = context.read<BrainCubit>(), d = cubit.data;
    final items = d.history.where((e) => e.type == game).toList();
    final best = items.isEmpty
        ? null
        : (items..sort(
                (a, b) => game == GameType.reflexTap
                    ? (a.reactionMs ?? 9999).compareTo(b.reactionMs ?? 9999)
                    : b.score.compareTo(a.score),
              ))
              .first;
    final accent = context.gameAccent(game);
    return BrainCard(
      color: Color.lerp(accent, context.brain.surface, .68),
      onTap: () => _chooseMode(context, game),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.brain.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: context.brain.shadow,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(game.emoji, style: const TextStyle(fontSize: 28)),
          ),
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
                Text(
                  '${game.domain} · Level ${d.difficulties[game.name] ?? 1}',
                ),
                Text(
                  best == null
                      ? 'No standard result yet'
                      : game == GameType.reflexTap
                      ? 'Best ${best.reactionMs} ms'
                      : 'Training ${trainingLevel(difficulty: best.difficulty, score: best.normalized).toStringAsFixed(1)} · ${(best.accuracy * 100).round()}%',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: context.brain.outline, width: 2),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: context.onColor(accent),
            ),
          ),
        ],
      ),
    );
  }

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
                child: TitlePlaque(game.title, color: context.gameAccent(game)),
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
                  'Personal Best',
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
                  child: BrainCard(
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
    final result = await Navigator.push<GameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          type: game,
          mode: mode,
          difficulty: difficulty,
          personalBest: pb,
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final record = await cubit.recordResult(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          record
              ? 'New comparable personal best'
              : mode == GameMode.relaxed
              ? 'Relaxed practice complete · not added to trends'
              : 'Standard practice saved',
        ),
      ),
    );
  }
}
