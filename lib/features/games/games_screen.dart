import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/demo_ads.dart';
import '../../app/theme/brain_theme.dart';
import 'game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('ARCADE LAB'),
        actions: [
          if (d.boosted)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Chip(
                avatar: Icon(Icons.bolt, size: 16),
                label: Text('2× XP'),
              ),
            ),
        ],
      ),
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
                    'Practice can improve records and earns reduced XP.',
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
                  const SectionTitle('Optional boosts'),
                  BrainCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.ondemand_video),
                      title: const Text('10-minute Practice XP boost'),
                      subtitle: const Text(
                        'Watch a clearly labeled local Demo Ad',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: d.boosted ? null : () => _boost(context),
                        child: Text(d.boosted ? 'ACTIVE' : '2× XP'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 10),
            BrainCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.redeem),
                title: const Text('Bonus cosmetic chest'),
                subtitle: const Text('1 token + 25 XP from a local Demo Ad'),
                trailing: FilledButton.tonal(
                  onPressed: () => _bonusChest(context),
                  child: const Text('OPEN'),
                ),
              ),
            ),
            const DemoBanner(),
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
                  '${game.domain} · Difficulty ${d.difficulties[game.name] ?? 1}',
                ),
                Text(
                  best == null
                      ? 'No personal best yet'
                      : game == GameType.reflexTap
                      ? 'Best ${best.reactionMs} ms'
                      : 'Best ${best.score} · ${(best.accuracy * 100).round()}%',
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
                (GameMode.classic, 'Classic', 'Standard finite round'),
                (GameMode.endless, 'Endless', 'Continue until three mistakes'),
                (
                  GameMode.timeAttack,
                  'Time Attack',
                  'Score as much as possible in 30 seconds',
                ),
                (
                  GameMode.personalBest,
                  'PB Challenge',
                  'Race your best compatible run',
                ),
                (GameMode.zen, 'Zen', 'No timer, XP, ads, or pressure'),
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
                          m.$1 == GameMode.zen ? Icons.spa : Icons.play_circle,
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
    final cubit = context.read<BrainCubit>(),
        pb = cubit.personalBest(game, mode);
    final result = await Navigator.push<GameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          type: game,
          mode: mode,
          difficulty: cubit.data.difficulties[game.name] ?? 1,
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
              ? '🏆 New personal record!'
              : 'Practice saved · +${mode == GameMode.zen ? 0 : 5} XP',
        ),
      ),
    );
    if (mode != GameMode.zen && cubit.shouldInterstitial()) {
      await showInterstitialDemo(context);
      await cubit.markInterstitial();
    }
  }

  Future<void> _boost(BuildContext context) async {
    if (await showRewardedDemo(
          context,
          reward: '2× Practice XP for 10 minutes',
        ) &&
        context.mounted) {
      await context.read<BrainCubit>().activateBoost();
    }
  }

  Future<void> _bonusChest(BuildContext context) async {
    if (await showRewardedDemo(context, reward: '1 cosmetic token + 25 XP') &&
        context.mounted) {
      await context.read<BrainCubit>().awardBonusChest();
    }
  }
}
