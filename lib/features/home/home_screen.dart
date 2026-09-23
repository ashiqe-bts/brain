import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/demo_ads.dart';
import '../brain_buddy/brain_buddy.dart';
import '../daily_workout/workout_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    final today = localDate(), done = d.daily.any((e) => e.date == today);
    final micro =
        stableSeed('$today|micro') % 20 == 0 && d.lastMicroEventDate != today;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BrainFlex',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<BrainCubit>().bootstrap(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          BrainBuddy(
                            mood: d.mood,
                            level: d.level,
                            equipped: d.equipped,
                            reducedMotion: d.reducedMotion,
                            onTap: () => context.read<BrainCubit>().react(
                              BuddyMood.tapped,
                            ),
                          ),
                          if (micro)
                            IconButton.filled(
                              tooltip: 'Catch the neuron for 5 XP',
                              onPressed: () => _micro(context),
                              icon: const Icon(Icons.bubble_chart),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _greeting(d),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _workoutCard(context, d, done),
                    if (_canRescue(d)) ...[
                      const SizedBox(height: 12),
                      _rescueCard(context, d),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatPill(
                          icon: Icons.local_fire_department,
                          label: 'day streak',
                          value: '${d.currentStreak}',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          icon: Icons.psychology,
                          label: d.rank,
                          value: 'Lv ${d.level}',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          icon: Icons.ac_unit,
                          label: 'freezes',
                          value: '${d.freezes}',
                        ),
                      ],
                    ),
                    const SectionTitle('Brain energy'),
                    BrainCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt),
                              const SizedBox(width: 8),
                              Text(
                                '${d.energy} / 100',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Text('${d.tokens} tokens'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: d.energy / 100,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),
                    const SectionTitle('Daily missions'),
                    ...d.missions.map((m) => _mission(context, m)),
                    if (d.missions.any((m) => m.id != 'workout' && !m.complete))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _reroll(context),
                          icon: const Icon(Icons.ondemand_video),
                          label: const Text('REROLL A MISSION · DEMO AD'),
                        ),
                      ),
                    const SectionTitle('This week'),
                    _weekStrip(context, d),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const DemoBanner(),
          ],
        ),
      ),
    );
  }

  void _micro(BuildContext context) {
    context.read<BrainCubit>().claimMicroEvent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('+5 XP · You caught a runaway neuron!')),
    );
  }

  bool _canRescue(BrainState d) =>
      d.lastCompletedDate != null &&
      d.currentStreak > 0 &&
      DateTime.now().difference(DateTime.parse(d.lastCompletedDate!)).inDays ==
          2;

  Widget _rescueCard(BuildContext context, BrainState d) => BrainCard(
    color: Theme.of(context).colorScheme.error.withValues(alpha: .12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR STREAK NEEDS A RESCUE',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        Text(
          'Protect your ${d.currentStreak}-day streak before today’s workout.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: d.freezes > 0
                  ? () => context.read<BrainCubit>().rescueStreak(
                      consumeFreeze: true,
                    )
                  : null,
              child: Text('USE FREEZE (${d.freezes})'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                if (await showRewardedDemo(context, reward: 'Streak rescue') &&
                    context.mounted) {
                  await context.read<BrainCubit>().rescueStreak(
                    consumeFreeze: false,
                  );
                }
              },
              icon: const Icon(Icons.ondemand_video),
              label: const Text('DEMO RESCUE'),
            ),
          ],
        ),
      ],
    ),
  );

  String _greeting(BrainState d) => d.workouts == 0
      ? 'Flex is ready for your first spark!'
      : d.lastCompletedDate == localDate()
      ? 'Flex is glowing after that workout!'
      : d.currentStreak > 0
      ? 'Keep your ${d.currentStreak}-day spark alive.'
      : 'A fresh little brain boost is waiting.';
  Widget _workoutCard(
    BuildContext context,
    BrainState d,
    bool done,
  ) => BrainCard(
    color: Theme.of(context).colorScheme.primary.withValues(alpha: .16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          done
              ? 'DAILY WORKOUT COMPLETE ✓'
              : d.draft != null
              ? 'WORKOUT IN PROGRESS'
              : "TODAY'S BRAIN WORKOUT",
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done
              ? 'Brain Score ${d.daily.lastWhere((e) => e.date == localDate()).brainScore}'
              : '5 challenges · ~4 min',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text('${dailyModifier(localDate())} modifier'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: done
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                ),
          icon: Icon(d.draft == null ? Icons.play_arrow : Icons.replay),
          label: Text(d.draft == null ? 'START WORKOUT' : 'CONTINUE WORKOUT'),
        ),
      ],
    ),
  );
  Widget _mission(BuildContext context, Mission m) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: BrainCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            m.complete ? Icons.check_circle : Icons.adjust,
            color: m.complete ? Colors.greenAccent : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('${m.progress}/${m.target} · +${m.reward} XP'),
              ],
            ),
          ),
          if (m.complete && !m.claimed)
            TextButton(
              onPressed: () => context.read<BrainCubit>().claimMission(m.id),
              child: const Text('CLAIM'),
            ),
        ],
      ),
    ),
  );

  Future<void> _reroll(BuildContext context) async {
    if (await showRewardedDemo(context, reward: 'One mission reroll') &&
        context.mounted) {
      await context.read<BrainCubit>().rerollMission();
    }
  }

  Widget _weekStrip(BuildContext context, BrainState d) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: now.weekday - 1 - i)),
            date = localDate(day),
            complete = d.daily.any((e) => e.date == date),
            isToday = date == localDate();
        return Column(
          children: [
            Text(DateFormat.E().format(day).substring(0, 1)),
            const SizedBox(height: 6),
            Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: .25)
                    : null,
                border: Border.all(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Text(
                complete
                    ? '✓'
                    : isToday
                    ? '●'
                    : '○',
              ),
            ),
          ],
        );
      }),
    );
  }
}
