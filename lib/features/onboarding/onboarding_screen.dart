import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final notifications = NotificationService();
  final nameController = TextEditingController();
  int page = 0;
  TimeOfDay reminder = const TimeOfDay(
    hour: AppSettings.defaultReminderHour,
    minute: AppSettings.defaultReminderMinute,
  );
  bool reminders = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          if (page > 0) _stepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: _motionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(page),
                child: [_welcome(), _name(), _routine()][page],
              ),
            ),
          ),
          if (page > 0) _navigation(),
        ],
      ),
    ),
  );

  Widget _stepIndicator() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
    child: Row(
      children: [
        Text('Set up BrainFlex', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 16),
        Expanded(child: LinearProgressIndicator(value: page / 2)),
        const SizedBox(width: 12),
        Text('$page of 2', style: TextStyle(color: context.brain.textMuted)),
      ],
    ),
  );

  Widget _welcome() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= AppSettings.onboardingWideBreakpoint;
      final message = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: wide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          const PageEyebrow('Research-informed daily practice'),
          const SizedBox(height: 16),
          Text(
            'A calmer way to challenge your focus.',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Five short games a day. Clear progress against your own previous practice. No rankings and no pressure.',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.brain.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryAction(
            label: 'Get started',
            icon: Icons.arrow_forward_rounded,
            expanded: !wide,
            onPressed: _next,
          ),
          const SizedBox(height: 28),
          const _Promise(
            icon: Icons.timer_outlined,
            title: 'A focused five-minute routine',
          ),
          const _Promise(
            icon: Icons.person_outline_rounded,
            title: 'Progress measured only against you',
          ),
          const _Promise(
            icon: Icons.lock_outline_rounded,
            title: 'Private by design',
          ),
          const SizedBox(height: 16),
          Text(
            'BrainFlex trains performance on its activities. It does not measure IQ or provide medical assessment.',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.brain.textMuted),
          ),
        ],
      );
      final visual = AppCard(
        tonal: true,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandMark(size: 132),
            const SizedBox(height: 24),
            Text(
              'BrainFlex',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                color: context.brain.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You versus yesterday',
              style: TextStyle(color: context.brain.textMuted),
            ),
          ],
        ),
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: ResponsiveContent(
            maxWidth: 1080,
            child: wide
                ? Row(
                    children: [
                      Expanded(child: message),
                      const SizedBox(width: 56),
                      Expanded(
                        child: AspectRatio(aspectRatio: 1, child: visual),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandMark(size: 88),
                      const SizedBox(height: 24),
                      message,
                    ],
                  ),
          ),
        ),
      );
    },
  );

  Widget _setupFrame({
    required String eyebrow,
    required String title,
    required String body,
    required Widget child,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= AppSettings.setupCardBreakpoint;
      final content = Column(
        crossAxisAlignment: wide
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          PageEyebrow(eyebrow),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: wide ? TextAlign.center : TextAlign.left,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: wide ? TextAlign.center : TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: context.brain.textMuted),
          ),
          const SizedBox(height: 32),
          child,
        ],
      );
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, wide ? 32 : 40, 24, 24),
        child: ResponsiveContent(
          maxWidth: AppSettings.narrowContentWidth,
          child: wide
              ? AppCard(padding: const EdgeInsets.all(32), child: content)
              : content,
        ),
      );
    },
  );

  Widget _name() => _setupFrame(
    eyebrow: 'Your profile',
    title: 'What should we call you?',
    body: 'Your display name stays on this device and can be changed later.',
    child: TextFormField(
      controller: nameController,
      autofocus: true,
      maxLength: 30,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Your name',
        hintText: 'Enter a display name',
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => displayNameError(value ?? ''),
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: (_) => _next(),
    ),
  );

  Widget _routine() => _setupFrame(
    eyebrow: 'Your routine',
    title: 'Practice on your schedule',
    body:
        'A single optional reminder can help you return. Your results remain on this device.',
    child: Column(
      children: [
        if (kIsWeb)
          const ListTile(
            leading: Icon(Icons.notifications_off_outlined),
            title: Text('Reminders unavailable in Chrome'),
            subtitle: Text('Daily reminders are supported on Android only.'),
          )
        else ...[
          SwitchListTile(
            value: reminders,
            onChanged: (value) => setState(() => reminders = value),
            secondary: const Icon(Icons.notifications_none_rounded),
            title: const Text('Daily reminder'),
            subtitle: const Text('Scheduled only on this Android device'),
          ),
          ListTile(
            enabled: reminders,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Reminder time'),
            subtitle: Text(reminder.format(context)),
            trailing: const Icon(Icons.chevron_right_rounded),
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
      ],
    ),
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: ResponsiveContent(
      maxWidth: 620,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
          const Spacer(),
          PrimaryAction(
            onPressed:
                page == 1 && displayNameError(nameController.text) != null
                ? null
                : _next,
            icon: page == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
            label: page == 2 ? 'Start training' : 'Continue',
          ),
        ],
      ),
    ),
  );

  void _back() => setState(() => page = (page - 1).clamp(0, 2));

  Duration get _motionDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);

  Future<void> _next() async {
    if (page == 1 && displayNameError(nameController.text) != null) {
      setState(() {});
      return;
    }
    if (page < 2) {
      setState(() => page++);
      return;
    }
    if (reminders) {
      await notifications.initialize();
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
      displayName: nameController.text,
      hour: reminder.hour,
      minute: reminder.minute,
      reminders: reminders,
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.brain.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: context.brain.primary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
