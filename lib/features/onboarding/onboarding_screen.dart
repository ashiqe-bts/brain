import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/brain_cubit.dart';
import '../brain_buddy/brain_buddy.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  TimeOfDay reminder = const TimeOfDay(hour: 19, minute: 0);
  bool reminders = false;
  int sampleScore = 0;
  final notifications = NotificationService();
  @override
  void initState() {
    super.initState();
    notifications.initialize();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (v) => setState(() => page = v),
              children: [_welcome(), _reminder(), _sample(), _ready()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (page > 0)
                  TextButton(
                    onPressed: () => controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: const Text('BACK'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(page == 3 ? 'ENTER THE LAB' : 'CONTINUE'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _frame(String eyebrow, String title, String body, Widget child) =>
      Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            child,
          ],
        ),
      );
  Widget _welcome() => _frame(
    'BRAINFlex LAB',
    'Hey! I’m Flex.',
    'A tiny brain buddy with big plans. Let’s train focus, memory, math, reaction, and visual speed together.',
    BrainBuddy(
      mood: BuddyMood.wave,
      level: 1,
      equipped: const {
        'hat': 'None',
        'glasses': 'None',
        'effect': 'None',
        'background': 'Brain Laboratory',
      },
      size: 220,
    ),
  );
  Widget _reminder() => _frame(
    'ONE GENTLE NUDGE',
    'When should I wait for you?',
    'BrainFlex sends at most one local reminder each day. You can change this anytime.',
    Column(
      children: [
        SwitchListTile(
          value: reminders,
          onChanged: (v) => setState(() => reminders = v),
          title: const Text('Daily reminder'),
          subtitle: const Text('Stored and scheduled only on this device'),
        ),
        ListTile(
          enabled: reminders,
          leading: const Icon(Icons.schedule),
          title: Text(reminder.format(context)),
          trailing: const Icon(Icons.chevron_right),
          onTap: reminders
              ? () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: reminder,
                  );
                  if (picked != null) setState(() => reminder = picked);
                }
              : null,
        ),
      ],
    ),
  );
  Widget _sample() => _frame(
    '15-SECOND SAMPLE',
    'Tap the ink color',
    'The word can be sneaky. This one is written in blue.',
    Column(
      children: [
        const Text(
          'RED',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.w900,
            fontSize: 52,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['RED', 'BLUE', 'GREEN', 'YELLOW']
              .map(
                (e) => FilledButton.tonal(
                  onPressed: () =>
                      setState(() => sampleScore += e == 'BLUE' ? 1 : 0),
                  child: Text(e),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          sampleScore > 0
              ? 'Perfect! Flex likes your focus.'
              : 'Choose BLUE to try it.',
        ),
      ],
    ),
  );
  Widget _ready() => _frame(
    'YOU’RE READY',
    'Your lab is waiting.',
    'No login. No pressure. Just a few playful minutes whenever you want them.',
    BrainBuddy(
      mood: BuddyMood.celebrate,
      level: 1,
      equipped: const {
        'hat': 'None',
        'glasses': 'None',
        'effect': 'None',
        'background': 'Brain Laboratory',
      },
      size: 200,
    ),
  );
  Future<void> _next() async {
    if (page < 3) {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    if (reminders) {
      final ok = await notifications.requestPermission();
      if (ok) {
        await notifications.scheduleDaily(
          hour: reminder.hour,
          minute: reminder.minute,
          streakWarning: true,
        );
      }
    }
    if (!mounted) return;
    await context.read<BrainCubit>().finishOnboarding(
      hour: reminder.hour,
      minute: reminder.minute,
      reminders: reminders,
    );
  }
}
