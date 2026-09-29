import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/models/brain_models.dart';
import '../../core/training/game_catalog.dart';
import '../../core/widgets/common.dart';

class GameTutorialScreen extends StatefulWidget {
  const GameTutorialScreen({
    super.key,
    required this.type,
    this.completionActionLabel = 'START PLAYING',
  });

  final GameType type;
  final String completionActionLabel;

  @override
  State<GameTutorialScreen> createState() => _GameTutorialScreenState();
}

class _GameTutorialScreenState extends State<GameTutorialScreen> {
  late final TutorialDefinition tutorial;
  Timer? timer;
  int stepIndex = 0;
  String? feedback;
  bool advancing = false;

  bool get complete => stepIndex >= tutorial.steps.length;
  TutorialStep get step => tutorial.steps[stepIndex];

  @override
  void initState() {
    super.initState();
    tutorial = gameDefinition(widget.type).tutorial;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleWait());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _scheduleWait() {
    timer?.cancel();
    if (!mounted || complete || !step.isWaitStep) return;
    timer = Timer(Duration(milliseconds: step.waitMilliseconds), () {
      if (!mounted) return;
      setState(() => feedback = step.successMessage);
      _advanceAfterFeedback();
    });
  }

  void _answer(int selected) {
    if (complete || advancing) return;
    if (step.isWaitStep) {
      timer?.cancel();
      setState(() => feedback = step.retryMessage);
      timer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => feedback = null);
        _scheduleWait();
      });
      return;
    }
    if (selected != step.correctIndex) {
      setState(() => feedback = step.retryMessage);
      return;
    }
    setState(() => feedback = step.successMessage);
    _advanceAfterFeedback();
  }

  void _advanceAfterFeedback() {
    advancing = true;
    timer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        stepIndex++;
        feedback = null;
        advancing = false;
      });
      _scheduleWait();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.type.title.toUpperCase()} TUTORIAL')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: complete ? _completeView(context) : _stepView(context),
          ),
        ),
      ),
    ),
  );

  Widget _stepView(BuildContext context) => Column(
    children: [
      Text(
        tutorial.intro,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      ResourceBar(
        label: 'Tutorial progress',
        value: stepIndex / tutorial.steps.length,
        trailing: '${stepIndex + 1} / ${tutorial.steps.length}',
        color: context.gameAccent(widget.type),
      ),
      const SizedBox(height: 18),
      Expanded(
        child: SingleChildScrollView(
          child: BrainCard(
            style: GamePanelStyle.inset,
            child: Column(
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(step.instruction, textAlign: TextAlign.center),
                const SizedBox(height: 22),
                Semantics(
                  label: 'Tutorial stimulus: ${step.stimulus}',
                  child: Text(
                    step.stimulus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    step.options.length,
                    (index) => Semantics(
                      label: step.isWaitStep
                          ? 'Do not press this button'
                          : 'Tutorial answer ${index + 1}',
                      button: true,
                      child: ArcadeButton(
                        color: step.isWaitStep
                            ? context.brain.danger
                            : context.gameAccent(widget.type),
                        onPressed: advancing ? null : () => _answer(index),
                        label: step.options[index],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    feedback ??
                        (step.isWaitStep
                            ? 'Keep waiting…'
                            : 'Choose an answer to continue.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _completeView(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.school_rounded,
        size: 78,
        color: context.gameAccent(widget.type),
      ),
      const SizedBox(height: 16),
      Text(
        '${widget.type.title} tutorial complete',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      const Text(
        'Tutorial practice is unscored and never changes your progress.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      ArcadeButton(
        expanded: true,
        color: context.brain.success,
        onPressed: () => Navigator.pop(context, true),
        icon: Icons.play_arrow_rounded,
        label: widget.completionActionLabel,
      ),
    ],
  );
}
