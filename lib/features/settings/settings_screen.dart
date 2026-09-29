import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/brain_models.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/brain_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final notifications = NotificationService();
  @override
  void initState() {
    super.initState();
    notifications.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<BrainCubit>().state.data;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const PageEyebrow('Your preferences stay on this device'),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _header('Profile'),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(d.displayName ?? 'Add your name'),
                  subtitle: const Text('Stored only on this device'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editName(d.displayName ?? ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header('Appearance'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        const [
                              (
                                BrainTheme.calmLight,
                                Icons.light_mode_outlined,
                                'Light',
                              ),
                              (
                                BrainTheme.calmDark,
                                Icons.dark_mode_outlined,
                                'Dark',
                              ),
                              (
                                BrainTheme.highContrast,
                                Icons.contrast_rounded,
                                'High contrast',
                              ),
                            ]
                            .map(
                              (option) => FilterChip(
                                avatar: Icon(option.$2, size: 18),
                                label: Text(option.$3),
                                selected: d.theme == option.$1,
                                onSelected: (_) => context
                                    .read<BrainCubit>()
                                    .setTheme(option.$1),
                              ),
                            )
                            .toList(),
                  ),
                ),
                SwitchListTile(
                  value: d.reducedMotion,
                  onChanged: (v) =>
                      context.read<BrainCubit>().toggle('reducedMotion', v),
                  secondary: const Icon(Icons.motion_photos_off),
                  title: const Text('Reduced motion'),
                  subtitle: const Text('Use fades instead of large movement'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header('Feedback'),
                _toggle(d.sound, 'Sound effects', 'sound', Icons.volume_up),
                _toggle(d.music, 'Ambient music', 'music', Icons.music_note),
                _toggle(d.haptics, 'Haptics', 'haptics', Icons.vibration),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header('Reminders'),
                if (kIsWeb)
                  const ListTile(
                    leading: Icon(Icons.notifications_off_outlined),
                    title: Text('Reminders unavailable in Chrome'),
                    subtitle: Text(
                      'Daily reminders are supported on Android only.',
                    ),
                  )
                else ...[
                  SwitchListTile(
                    value: d.reminderEnabled,
                    onChanged: (v) => _toggleReminder(v, d),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Daily reminder'),
                    subtitle: Text(
                      '${TimeOfDay(hour: d.reminderHour, minute: d.reminderMinute).format(context)} · at most one per day',
                    ),
                  ),
                  ListTile(
                    enabled: d.reminderEnabled,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Reminder time'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickTime(d),
                  ),
                  SwitchListTile(
                    value: d.streakWarning,
                    onChanged: (v) async {
                      await context.read<BrainCubit>().toggle(
                        'streakWarning',
                        v,
                      );
                      if (d.reminderEnabled) {
                        await notifications.scheduleDaily(
                          hour: d.reminderHour,
                          minute: d.reminderMinute,
                          streakWarning: v,
                        );
                      }
                    },
                    secondary: const Icon(Icons.local_fire_department_outlined),
                    title: const Text('Streak-aware wording'),
                    subtitle: const Text(
                      'Replaces the normal reminder; it does not add another',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header('About'),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('Your progress stays on this device'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Mental exercise, not medicine'),
                  subtitle: Text(
                    'BrainFlex tracks performance in its trained tasks. It does not measure IQ, diagnose conditions, or make health claims.',
                  ),
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline),
                  applicationName: 'BrainFlex',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Private, offline cognitive practice.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
    child: Text(
      text,
      style: TextStyle(
        color: context.brain.textMuted,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _toggle(bool value, String title, String key, IconData icon) =>
      SwitchListTile(
        value: value,
        onChanged: (v) => context.read<BrainCubit>().toggle(key, v),
        secondary: Icon(icon),
        title: Text(title),
      );
  Future<void> _toggleReminder(bool value, BrainState d) async {
    if (value && !await notifications.requestPermission()) return;
    if (!mounted) return;
    await context.read<BrainCubit>().toggle('reminder', value);
    if (value) {
      await notifications.scheduleDaily(
        hour: d.reminderHour,
        minute: d.reminderMinute,
        streakWarning: d.streakWarning,
      );
    } else {
      await notifications.cancelDaily();
    }
  }

  Future<void> _pickTime(BrainState d) async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: d.reminderHour, minute: d.reminderMinute),
    );
    if (value == null || !mounted) return;
    await context.read<BrainCubit>().setReminder(value.hour, value.minute);
    await notifications.scheduleDaily(
      hour: value.hour,
      minute: value.minute,
      streakWarning: d.streakWarning,
    );
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit your name'),
          content: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (text) => displayNameError(text ?? ''),
            onChanged: (_) => setDialogState(() {}),
            onFieldSubmitted: (text) {
              if (displayNameError(text) == null) {
                Navigator.pop(dialogContext, text);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: displayNameError(controller.text) == null
                  ? () => Navigator.pop(dialogContext, controller.text)
                  : null,
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      await context.read<BrainCubit>().setDisplayName(value);
    }
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.lock_person_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 20),
        Text(
          'Your training data stays yours.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'BrainFlex does not require an account. Session history, personal baselines, progress, and settings are stored locally on your device. There is no backend, cloud sync, advertising SDK, product analytics service, or user-generated content.',
        ),
        const SizedBox(height: 14),
        const Text(
          'Standard and daily sessions contribute to personal trends. Relaxed practice is kept separate so it cannot distort measured progress.',
        ),
        const SizedBox(height: 14),
        const Text(
          'Local notification permission is optional. Reminder schedules are managed by your operating system and can be disabled at any time in BrainFlex or system settings.',
        ),
        const SizedBox(height: 14),
        const Text(
          'Deleting the app clears its local BrainFlex data unless your operating system independently restores an app backup.',
        ),
      ],
    ),
  );
}
