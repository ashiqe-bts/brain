import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../brain_buddy/brain_buddy.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flex Lab',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Chip(
              avatar: const Icon(Icons.hexagon, size: 16),
              label: Text('${d.tokens} tokens'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BrainCard(
              color: _backgroundColor(d.equipped['background']),
              child: Column(
                children: [
                  BrainBuddy(
                    mood: BuddyMood.happy,
                    level: d.level,
                    equipped: d.equipped,
                    reducedMotion: d.reducedMotion,
                    size: 220,
                  ),
                  Text(
                    'Level ${d.level} · ${d.rank}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: d.level >= 50 ? 1 : d.xp / d.xpNeeded,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    d.level >= 50
                        ? 'Maximum evolution'
                        : '${d.xp} / ${d.xpNeeded} XP',
                  ),
                ],
              ),
            ),
            const SectionTitle('Evolution path'),
            const BrainCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('1 Tiny')),
                  Chip(label: Text('5 Curious 👓')),
                  Chip(label: Text('10 Smart 🎧')),
                  Chip(label: Text('20 Professor 🥼')),
                  Chip(label: Text('35 Cosmic ✨')),
                  Chip(label: Text('50 Quantum ⚛')),
                ],
              ),
            ),
            ...cosmeticCatalog.entries.map(
              (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(e.key[0].toUpperCase() + e.key.substring(1)),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: e.value.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) =>
                          _cosmetic(context, d, e.key, e.value[i]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color? _backgroundColor(String? value) => switch (value) {
    'Space Lab' => const Color(0xFF151047),
    'Classroom' => const Color(0xFF334C3D),
    'Neon Arcade' => const Color(0xFF42134C),
    'Dream World' => const Color(0xFF3A315E),
    _ => null,
  };
  Widget _cosmetic(
    BuildContext context,
    BrainState d,
    String category,
    String item,
  ) {
    final unlocked =
            d.unlocked.contains(item) ||
            item == 'None' ||
            item == 'Brain Laboratory',
        equipped = d.equipped[category] == item,
        cost = category == 'background'
            ? 5
            : category == 'effect'
            ? 4
            : category == 'hat'
            ? 3
            : 2;
    return SizedBox(
      width: 130,
      child: Card(
        color: equipped
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .24)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            final cubit = context.read<BrainCubit>();
            if (unlocked) {
              await cubit.equip(category, item);
            } else {
              final buy = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Unlock $item?'),
                  content: Text('$cost cosmetic tokens'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    FilledButton(
                      onPressed: d.tokens >= cost
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: const Text('UNLOCK'),
                    ),
                  ],
                ),
              );
              if (buy == true) await cubit.unlock(item, cost);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  equipped
                      ? Icons.check_circle
                      : unlocked
                      ? Icons.auto_awesome
                      : Icons.lock_outline,
                  color: equipped
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  item,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (!unlocked)
                  Text(
                    '$cost tokens',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
