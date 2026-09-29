import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/brain_theme.dart';
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: BrainCard(
              style: GamePanelStyle.inset,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Add your name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your progress is still here. This name stays only on this device.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 30,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => displayNameError(value ?? ''),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  ArcadeButton(
                    expanded: true,
                    color: context.brain.primary,
                    onPressed: displayNameError(controller.text) == null
                        ? _save
                        : null,
                    icon: Icons.arrow_forward_rounded,
                    label: saving ? 'SAVING' : 'CONTINUE',
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
