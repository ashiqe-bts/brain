import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  final notifications = NotificationService();
  int page = 0;
  int sampleScore = 0;
  TimeOfDay reminder = const TimeOfDay(hour: 19, minute: 0);
  bool reminders = false;

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
              onPageChanged: (value) => setState(() => page = value),
              children: [_welcome(), _baseline(), _sample(), _reminder()],
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
                ArcadeButton(
                  onPressed: _next,
                  color: page == 3
                      ? context.brain.success
                      : context.brain.primary,
                  icon: page == 3
                      ? Icons.fitness_center_rounded
                      : Icons.arrow_forward_rounded,
                  label: page == 3 ? 'START TRAINING' : 'CONTINUE',
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
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: BrainCard(
              style: GamePanelStyle.inset,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TitlePlaque(eyebrow),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(body, textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ),
      );

  Widget _welcome() => _frame(
    'BRAINFLEX',
    'A personal cognitive gym',
    'Practice focus, calculation, memory, reaction, and visual search in short daily sessions.',
    const Icon(Icons.psychology_alt_rounded, size: 120),
  );

  Widget _baseline() => _frame(
    'YOUR OWN STARTING POINT',
    'Three workouts build your baseline',
    'BrainFlex compares compatible sessions with your own history. It does not compare you with an age group or claim to measure IQ.',
    const Column(
      children: [
        LinearProgressIndicator(value: 1 / 3),
        SizedBox(height: 12),
        Text('Workout 1 of 3 begins after onboarding'),
      ],
    ),
  );

  Widget _sample() => _frame(
    'QUICK SAMPLE',
    'Tap the ink color',
    'The word says RED, but the ink is blue.',
    Column(
      children: [
        Text(
          'RED',
          style: TextStyle(
            color: context.clashColor(1),
            fontWeight: FontWeight.w900,
            fontSize: 52,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['RED', 'BLUE', 'GREEN', 'YELLOW']
              .map(
                (label) => ArcadeButton(
                  color: context.clashColor(
                    const ['RED', 'BLUE', 'GREEN', 'YELLOW'].indexOf(label),
                  ),
                  onPressed: () =>
                      setState(() => sampleScore = label == 'BLUE' ? 1 : -1),
                  label: label,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          sampleScore == 1
              ? 'Correct—the ink is blue.'
              : sampleScore == -1
              ? 'Look at the ink rather than the word.'
              : 'Choose the ink color.',
        ),
      ],
    ),
  );

  Widget _reminder() => _frame(
    'PRIVATE BY DEFAULT',
    'Train on your schedule',
    'Your results stay on this device. A single optional local reminder can help you build a routine.',
    Column(
      children: [
        SwitchListTile(
          value: reminders,
          onChanged: (value) => setState(() => reminders = value),
          title: const Text('Daily reminder'),
          subtitle: const Text('Scheduled only on this device'),
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

  Future<void> _next() async {
    if (page < 3) {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    if (reminders) {
      final allowed = await notifications.requestPermission();
      if (allowed) {
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
