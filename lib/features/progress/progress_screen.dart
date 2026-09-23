import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/demo_ads.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int monthOffset = 0;
  final recapKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Progress',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      StatPill(
                        icon: Icons.local_fire_department,
                        label: 'current streak',
                        value: '${d.currentStreak}',
                      ),
                      const SizedBox(width: 10),
                      StatPill(
                        icon: Icons.emoji_events,
                        label: 'best streak',
                        value: '${d.longestStreak}',
                      ),
                      const SizedBox(width: 10),
                      StatPill(
                        icon: Icons.fitness_center,
                        label: 'workouts',
                        value: '${d.workouts}',
                      ),
                    ],
                  ),
                  const SectionTitle('Activity calendar'),
                  BrainCard(child: _calendar(context, d)),
                  const SectionTitle('Personal records'),
                  _records(context, d),
                  const SectionTitle('Achievements'),
                  _achievements(context, d),
                  if (d.daily.length >= 7) ...[
                    const SectionTitle('Your Brain Week'),
                    RepaintBoundary(
                      key: recapKey,
                      child: _recapCard(context, d),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _shareRecap,
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE RECAP'),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const DemoBanner(),
          ],
        ),
      ),
    );
  }

  Widget _calendar(BuildContext context, BrainState d) {
    final now = DateTime.now(),
        month = DateTime(now.year, now.month + monthOffset),
        days = DateUtils.getDaysInMonth(month.year, month.month),
        start = DateTime(month.year, month.month, 1).weekday - 1;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
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
              onPressed: monthOffset < 0
                  ? () => setState(() => monthOffset++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final s in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
          itemBuilder: (context, i) {
            if (i < start) return const SizedBox();
            final day = i - start + 1,
                date = localDate(DateTime(month.year, month.month, day)),
                complete = d.daily.any((e) => e.date == date),
                today = date == localDate();
            return Container(
              margin: const EdgeInsets.all(3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: .3)
                    : null,
                border: today
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Text(complete ? '✓' : '$day'),
            );
          },
        ),
      ],
    );
  }

  Widget _records(BuildContext context, BrainState d) {
    if (d.history.isEmpty) {
      return const BrainCard(
        child: Text('Play a game to set your first record.'),
      );
    }
    return Column(
      children: GameType.values.map((g) {
        final list = d.history.where((e) => e.type == g).toList();
        if (list.isEmpty) return const SizedBox();
        list.sort(
          (a, b) => g == GameType.reflexTap
              ? (a.reactionMs ?? 9999).compareTo(b.reactionMs ?? 9999)
              : b.score.compareTo(a.score),
        );
        final r = list.first;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BrainCard(
            padding: const EdgeInsets.all(13),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(g.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(g.title),
              trailing: Text(
                g == GameType.reflexTap
                    ? '${r.reactionMs} ms'
                    : '${r.score} pts',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _achievements(BuildContext context, BrainState d) {
    const all = {
      'First Spark': 'Complete your first workout',
      'One Week Strong': 'Maintain a 7-day streak',
      'Lightning Fingers': 'React in under 250 ms',
      'Memory Machine': 'Perfect a Memory Tiles round',
      'Math Wizard': 'Get 25 Math answers correct',
      'Unstoppable': 'Reach a 30-day streak',
      'Perfectionist': 'Finish a workout above 95% accuracy',
    };
    return BrainCard(
      child: Column(
        children: all.entries.map((e) {
          final got = d.achievements.contains(e.key);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(got ? Icons.emoji_events : Icons.lock_outline),
            ),
            title: Text(
              e.key,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: got ? null : Theme.of(context).disabledColor,
              ),
            ),
            subtitle: Text(e.value),
            trailing: got ? const Text('DONE') : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _recapCard(BuildContext context, BrainState d) {
    final recent = d.daily.reversed.take(7).toList(),
        best = recent.reduce((a, b) => a.brainScore > b.brainScore ? a : b),
        reaction = recent
            .map((e) => e.reactionMs ?? 9999)
            .reduce((a, b) => a < b ? a : b);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: .8),
            Theme.of(context).colorScheme.secondary.withValues(alpha: .65),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 YOUR BRAIN WEEK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${recent.length} workouts completed',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          Text(
            '🏆 Best Brain Score  ${best.brainScore}',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          if (reaction < 9999)
            Text(
              '⚡ Fastest Reaction  $reaction ms',
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          Text(
            '🔥 Best streak  ${d.longestStreak} days',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 14),
          const Text(
            'BrainFlex · Small games. Bright sparks.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _shareRecap() async {
    try {
      final boundary =
          recapKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'brainflex_week.png',
            ),
          ],
          text: 'My BrainFlex week!',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the share card.')),
        );
      }
    }
  }
}
