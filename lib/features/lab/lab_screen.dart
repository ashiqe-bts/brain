import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../brain_buddy/brain_buddy.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});
  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  String category = 'hat';
  static const categoryIcons = {
    'hat': Icons.school_rounded,
    'glasses': Icons.visibility_rounded,
    'effect': Icons.auto_awesome_rounded,
    'background': Icons.wallpaper_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('FLEX LAB'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.brain.reward,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.brain.outline, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: context.brain.shadow,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hexagon_rounded,
                      color: context.brain.outline,
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.tokens}',
                      style: TextStyle(
                        color: context.brain.outline,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final wide = box.maxWidth >= 720;
                    final preview = _preview(context, d);
                    final inventory = _inventory(context, d);
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: box.maxWidth * .4,
                                child: preview,
                              ),
                              const SizedBox(width: 18),
                              Expanded(child: inventory),
                            ],
                          )
                        : Column(
                            children: [
                              preview,
                              const SizedBox(height: 18),
                              inventory,
                            ],
                          );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: BrainCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: TitlePlaque('Evolution path')),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          '1 Tiny',
                          '5 Curious 👓',
                          '10 Smart 🎧',
                          '20 Professor 🥼',
                          '35 Cosmic ✨',
                          '50 Quantum ⚛',
                        ].map((s) => Chip(label: Text(s))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, BrainState d) => BrainCard(
    color: _backgroundColor(d.equipped['background']) ?? context.brain.hud,
    style: GamePanelStyle.inset,
    child: Column(
      children: [
        const TitlePlaque('Player one'),
        BrainBuddy(
          mood: BuddyMood.happy,
          level: d.level,
          equipped: d.equipped,
          reducedMotion: d.reducedMotion,
          size: 210,
        ),
        Text(
          'LEVEL ${d.level} · ${d.rank.toUpperCase()}',
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ResourceBar(
          label: 'XP',
          value: d.level >= 50 ? 1 : d.xp / d.xpNeeded,
          trailing: d.level >= 50 ? 'MAX' : '${d.xp}/${d.xpNeeded}',
        ),
      ],
    ),
  );

  Widget _inventory(BuildContext context, BrainState d) {
    final light = Theme.of(context).brightness == Brightness.light;
    return BrainCard(
      color: Color.lerp(
        context.brain.primary,
        context.brain.surface,
        light ? .72 : .22,
      ),
      style: GamePanelStyle.purple,
      child: Column(
        children: [
          const TitlePlaque('Inventory'),
          const SizedBox(height: 16),
          Row(
            children: categoryIcons.entries
                .map(
                  (e) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        label: e.key,
                        selected: category == e.key,
                        button: true,
                        child: InkWell(
                          onTap: () => setState(() => category = e.key),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 50,
                            decoration: BoxDecoration(
                              color: category == e.key
                                  ? context.brain.reward
                                  : context.brain.hud,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.brain.outline,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              e.value,
                              color: category == e.key
                                  ? context.brain.outline
                                  : context.brain.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .9,
            ),
            itemCount: cosmeticCatalog[category]!.length,
            itemBuilder: (context, i) =>
                _cosmetic(context, d, category, cosmeticCatalog[category]![i]),
          ),
        ],
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
        item == 'Brain Laboratory';
    final equipped = d.equipped[category] == item;
    final cost = category == 'background'
        ? 5
        : category == 'effect'
        ? 4
        : category == 'hat'
        ? 3
        : 2;
    return Semantics(
      label:
          '$item${equipped
              ? ', equipped'
              : unlocked
              ? ', unlocked'
              : ', locked, $cost tokens'}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _select(context, d, category, item, unlocked, cost),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: equipped
                  ? context.brain.reward
                  : context.brain.surfaceHigh,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: context.brain.outline,
                width: equipped ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.brain.shadow,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  equipped
                      ? Icons.check_circle_rounded
                      : unlocked
                      ? Icons.auto_awesome_rounded
                      : Icons.lock_rounded,
                  color: equipped
                      ? context.brain.outline
                      : unlocked
                      ? context.brain.secondary
                      : context.brain.frame,
                ),
                const SizedBox(height: 5),
                Text(
                  item,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: equipped ? context.brain.outline : null,
                  ),
                ),
                if (!unlocked)
                  Text(
                    '$cost ◆',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: context.rewardInk,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    BrainState d,
    String category,
    String item,
    bool unlocked,
    int cost,
  ) async {
    final cubit = context.read<BrainCubit>();
    if (unlocked) {
      await cubit.equip(category, item);
      return;
    }
    final buy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: TitlePlaque('Unlock item')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(item, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('$cost cosmetic tokens'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ArcadeButton(
            label: 'UNLOCK',
            onPressed: d.tokens >= cost
                ? () => Navigator.pop(context, true)
                : null,
          ),
        ],
      ),
    );
    if (buy == true) await cubit.unlock(item, cost);
  }
}
