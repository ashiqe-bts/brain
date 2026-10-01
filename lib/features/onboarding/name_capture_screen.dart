import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/brain_models.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/widgets/common.dart';

class NameCaptureScreen extends StatefulWidget {
  const NameCaptureScreen({super.key});

  @override
  State<NameCaptureScreen> createState() => _NameCaptureScreenState();
}

class _NameCaptureScreenState extends State<NameCaptureScreen> {
  final controller = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving || displayNameError(controller.text) != null) {
      setState(() {});
      return;
    }
    setState(() => saving = true);
    await context.read<BrainCubit>().setDisplayName(controller.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSettings.profileCardWidth,
            ),
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 72),
                  const SizedBox(height: 16),
                  Text(
                    AppText.settings.addName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppText.onboarding.returningProfileBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: AppSettings.maximumDisplayNameCharacters,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: AppText.settings.yourName,
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => displayNameError(value ?? ''),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  PrimaryAction(
                    expanded: true,
                    color: context.brain.primary,
                    onPressed: displayNameError(controller.text) == null
                        ? _save
                        : null,
                    icon: Icons.arrow_forward_rounded,
                    label: saving
                        ? AppText.saving
                        : AppText.onboarding.continueLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
