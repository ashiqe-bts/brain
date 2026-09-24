import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Center(child: TitlePlaque('Control board')),
          const SizedBox(height: 20),
          BrainCard(
            style: GamePanelStyle.inset,
            child: Column(
              children: [
                _header('Appearance'),
                SwitchListTile(
                  value: d.theme != BrainTheme.daydream,
                  onChanged: (dark) => context.read<BrainCubit>().setTheme(
                    dark ? BrainTheme.midnight : BrainTheme.daydream,
                  ),
                  secondary: Icon(
                    d.theme == BrainTheme.daydream
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    d.theme == BrainTheme.daydream
                        ? 'Light storybook colors are active'
                        : 'Dark arcade colors are active',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<BrainTheme>(
                    key: ValueKey(d.theme),
                    initialValue: d.theme,
                    decoration: const InputDecoration(
                      labelText: 'Theme style',
                      border: OutlineInputBorder(),
                    ),
                    items: BrainTheme.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(_themeName(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) context.read<BrainCubit>().setTheme(v);
                    },
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
          BrainCard(
            style: GamePanelStyle.inset,
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
          BrainCard(
            style: GamePanelStyle.inset,
            child: Column(
              children: [
                _header('Reminders'),
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
                    await context.read<BrainCubit>().toggle('streakWarning', v);
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
            ),
          ),
          const SizedBox(height: 18),
          BrainCard(
            style: GamePanelStyle.inset,
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
                    'BrainFlex does not measure IQ, diagnose conditions, or make health claims.',
                  ),
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline),
                  applicationName: 'BrainFlex',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'A playful offline brain-training game.',
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
      text.toUpperCase(),
      style: TextStyle(
        color: context.rewardInk,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
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
  String _themeName(BrainTheme t) => switch (t) {
    BrainTheme.midnight => 'Midnight Brain Lab',
    BrainTheme.oled => 'True Black OLED',
    BrainTheme.daydream => 'Daydream Lab',
    BrainTheme.highContrast => 'High Contrast',
  };
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
          'Your brain world stays yours.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'BrainFlex does not require an account. Gameplay history, progress, settings, and cosmetics are stored locally on your device. There is no backend, cloud sync, analytics service, or user-generated content.',
        ),
        const SizedBox(height: 14),
        const Text(
          'The advertising surfaces in this MVP are clearly labeled local demonstrations. They do not contact an ad network, create an advertising identifier, or track you.',
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
