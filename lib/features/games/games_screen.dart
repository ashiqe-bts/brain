import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/demo_ads.dart';
import 'game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Practice Lab',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Choose a challenge',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'Practice can improve records and earns reduced XP.',
                  ),
                  const SizedBox(height: 14),
                  ...GameType.values.map((g) => _gameCard(context, g)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BrainCard(
        onTap: () => _chooseMode(context, game),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(18),
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
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseMode(BuildContext context, GameType game) async {
    final mode = await showModalBottomSheet<GameMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
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
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    m.$1 == GameMode.zen ? Icons.spa : Icons.play_circle,
                  ),
                  title: Text(m.$2),
                  subtitle: Text(m.$3),
                  onTap: () => Navigator.pop(context, m.$1),
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
