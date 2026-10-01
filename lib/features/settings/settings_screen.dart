import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
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
      appBar: AppBar(title: Text(AppText.navigation.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          PageEyebrow(AppText.settings.eyebrow),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _header(AppText.settings.profile),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(d.displayName ?? AppText.settings.addName),
                  subtitle: Text(AppText.settings.storedLocally),
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
                _header(AppText.settings.appearance),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              (
                                BrainTheme.calmLight,
                                Icons.light_mode_outlined,
                                AppText.settings.light,
                              ),
                              (
                                BrainTheme.calmDark,
                                Icons.dark_mode_outlined,
                                AppText.settings.dark,
                              ),
                              (
                                BrainTheme.highContrast,
                                Icons.contrast_rounded,
                                AppText.settings.highContrast,
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
                  title: Text(AppText.settings.reducedMotion),
                  subtitle: Text(AppText.settings.reducedMotionBody),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header(AppText.settings.feedback),
                _toggle(
                  d.sound,
                  AppText.settings.soundEffects,
                  'sound',
                  Icons.volume_up,
                ),
                _toggle(
                  d.music,
                  AppText.settings.ambientMusic,
                  'music',
                  Icons.music_note,
                ),
                _toggle(
                  d.haptics,
                  AppText.settings.haptics,
                  'haptics',
                  Icons.vibration,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header(AppText.settings.reminders),
                if (kIsWeb)
                  ListTile(
                    leading: Icon(Icons.notifications_off_outlined),
                    title: Text(AppText.onboarding.remindersUnavailable),
                    subtitle: Text(AppText.onboarding.remindersAndroidOnly),
                  )
                else ...[
                  SwitchListTile(
                    value: d.reminderEnabled,
                    onChanged: (v) => _toggleReminder(v, d),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: Text(AppText.onboarding.dailyReminder),
                    subtitle: Text(
                      AppText.reminderSchedule(
                        TimeOfDay(
                          hour: d.reminderHour,
                          minute: d.reminderMinute,
                        ).format(context),
                      ),
                    ),
                  ),
                  ListTile(
                    enabled: d.reminderEnabled,
                    leading: const Icon(Icons.schedule),
                    title: Text(AppText.onboarding.reminderTime),
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
                    title: Text(AppText.settings.streakWording),
                    subtitle: Text(AppText.settings.streakWordingBody),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                _header(AppText.settings.about),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(AppText.settings.privacy),
                  subtitle: Text(AppText.settings.privacySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text(AppText.settings.medicalTitle),
                  subtitle: Text(AppText.settings.medicalBody),
                ),
                AboutListTile(
                  icon: const Icon(Icons.info_outline),
                  applicationName: AppText.appName,
                  applicationVersion: AppText.settings.version,
                  applicationLegalese: AppText.settings.legalese,
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
          title: Text(AppText.settings.editName),
          content: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: AppSettings.maximumDisplayNameCharacters,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: AppText.settings.yourName,
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
              child: Text(AppText.settings.cancel),
            ),
            FilledButton(
              onPressed: displayNameError(controller.text) == null
                  ? () => Navigator.pop(dialogContext, controller.text)
                  : null,
              child: Text(AppText.settings.save),
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
    appBar: AppBar(title: Text(AppText.settings.privacy)),
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
          AppText.settings.privacyTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(AppText.settings.privacyStorage),
        const SizedBox(height: 14),
        Text(AppText.settings.privacySessions),
        const SizedBox(height: 14),
        Text(AppText.settings.privacyNotifications),
        const SizedBox(height: 14),
        Text(AppText.settings.privacyDeletion),
      ],
    ),
  );
}
