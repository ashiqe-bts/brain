import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/training/game_catalog.dart';
import '../../core/widgets/common.dart';
import 'classic_game_board.dart';
import 'game_engine.dart';
import 'research_game_board.dart';
import 'research_game_engine.dart';
import 'tutorial_guide.dart';

const tutorialSessionSeed = 240519;

class GameTutorialScreen extends StatefulWidget {
  const GameTutorialScreen({
    super.key,
    required this.type,
    this.completionActionLabel = AppText.startPlaying,
  });

  final GameType type;
  final String completionActionLabel;

  @override
  State<GameTutorialScreen> createState() => _GameTutorialScreenState();
}

class _GameTutorialScreenState extends State<GameTutorialScreen> {
  late final TutorialDefinition tutorial;
  late final ResearchGameEngine? researchEngine;
  Timer? phaseTimer;
  Timer? guideTimer;
  Timer? advanceTimer;
  int stepIndex = 0;
  String? feedback;
  bool advancing = false;
  bool showingStimulus = false;
  bool guideVisible = false;
  ResearchTrial? researchTrial;
  ColorTrial colorTrial = const ColorTrial(wordIndex: 0, colorIndex: 0);
  MathTrial mathTrial = const MathTrial(
    left: 4,
    right: 3,
    operator: '+',
    actual: 7,
    shown: 7,
  );

  int get stepCount => tutorial.steps.length;
  bool get complete => stepIndex >= stepCount;
  TutorialStep get step =>
      tutorial.steps[min(stepIndex, tutorial.steps.length - 1)];
  bool get isClassic =>
      widget.type == GameType.colorClash || widget.type == GameType.mathBlitz;

  @override
  void initState() {
    super.initState();
    tutorial = gameDefinition(widget.type).tutorial;
    researchEngine = isClassic
        ? null
        : ResearchGameEngine(
            seed: tutorialSessionSeed,
            type: widget.type,
            difficulty: 1,
          );
    _prepareStep();
  }

  @override
  void dispose() {
    phaseTimer?.cancel();
    guideTimer?.cancel();
    advanceTimer?.cancel();
    super.dispose();
  }

  void _prepareStep() {
    phaseTimer?.cancel();
    guideTimer?.cancel();
    feedback = null;
    guideVisible = false;
    if (complete) return;

    if (widget.type == GameType.colorClash) {
      colorTrial = stepIndex == 0
          ? const ColorTrial(wordIndex: 0, colorIndex: 0)
          : const ColorTrial(wordIndex: 0, colorIndex: 1);
      showingStimulus = false;
      _scheduleGuide();
      return;
    }
    if (widget.type == GameType.mathBlitz) {
      mathTrial = stepIndex == 0
          ? const MathTrial(
              left: 4,
              right: 3,
              operator: '+',
              actual: 7,
              shown: 7,
            )
          : const MathTrial(
              left: 9,
              right: 4,
              operator: '−',
              actual: 5,
              shown: 6,
            );
      showingStimulus = false;
      _scheduleGuide();
      return;
    }

    researchTrial = _nextMatchingResearchTrial();
    showingStimulus = researchTrial!.exposureMs > 0;
    if (showingStimulus) {
      phaseTimer = Timer(
        Duration(milliseconds: researchTrial!.exposureMs),
        _finishExposure,
      );
    } else {
      _scheduleGuide();
    }
  }

  ResearchTrial _nextMatchingResearchTrial() {
    final wanted = switch (widget.type) {
      GameType.signalStop => stepIndex == 0 ? 'go' : 'stop',
      GameType.nBackNavigator => stepIndex < 2 ? 'non-match' : 'match',
      GameType.ruleSwitch => stepIndex == 0 ? 'repeat' : 'switch',
      GameType.arrowGuard => stepIndex == 0 ? 'congruent' : 'incongruent',
      GameType.pairLink => stepIndex < 2 ? 'immediate' : 'delayed',
      GameType.spatialRotation => stepIndex == 0 ? 'same' : 'mirror',
      _ => null,
    };
    for (var attempt = 0; attempt < 16; attempt++) {
      final candidate = researchEngine!.nextTrial();
      if (wanted == null || candidate.condition.startsWith(wanted)) {
        return candidate;
      }
    }
    throw StateError(AppText.tutorialCreationError(widget.type.name));
  }

  void _finishExposure() {
    if (!mounted || complete || advancing) return;
    setState(() {
      showingStimulus = false;
      guideVisible = researchTrial!.condition == 'stop';
    });
    if (researchTrial!.condition == 'stop') {
      phaseTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted && !advancing) _answerResearch(researchTrial!.correctIndex);
      });
    } else {
      _scheduleGuide();
    }
  }

  void _scheduleGuide() {
    guideTimer?.cancel();
    guideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !complete && !advancing) {
        setState(() => guideVisible = true);
      }
    });
  }

  void _answerColor(int selected) {
    _handleAnswer(selected == colorTrial.colorIndex);
  }

  void _answerMath(bool selected) {
    _handleAnswer(selected == mathTrial.isCorrect);
  }

  void _answerResearch(int selected) {
    if (researchTrial == null || complete || advancing) return;
    if (showingStimulus && researchTrial!.condition != 'stop') return;
    phaseTimer?.cancel();
    final correct = selected == researchTrial!.correctIndex;
    if (correct) researchEngine!.acceptAnswer(researchTrial!, selected);
    _handleAnswer(
      correct,
      restartPassiveTrial: researchTrial!.condition == 'stop',
    );
  }

  void _handleAnswer(bool correct, {bool restartPassiveTrial = false}) {
    if (complete || advancing) return;
    guideTimer?.cancel();
    if (!correct) {
      setState(() {
        feedback = step.retryMessage;
        guideVisible = true;
      });
      if (restartPassiveTrial) {
        phaseTimer = Timer(const Duration(milliseconds: 700), () {
          if (!mounted || advancing) return;
          setState(() {
            feedback = null;
            guideVisible = false;
            showingStimulus = true;
          });
          phaseTimer = Timer(
            Duration(milliseconds: researchTrial!.exposureMs),
            _finishExposure,
          );
        });
      }
      return;
    }

    setState(() {
      feedback = step.successMessage;
      guideVisible = false;
      advancing = true;
    });
    advanceTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        stepIndex++;
        advancing = false;
        feedback = null;
      });
      _prepareStep();
      if (mounted) setState(() {});
    });
  }

  TutorialGuide? get _guide {
    if (!guideVisible || complete) return null;
    if (researchTrial?.condition == 'stop') {
      return const TutorialGuide.passive();
    }
    final answerIndex = switch (widget.type) {
      GameType.colorClash => colorTrial.colorIndex,
      GameType.mathBlitz => mathTrial.isCorrect ? 0 : 1,
      _ => researchTrial!.correctIndex,
    };
    return TutorialGuide.answer(answerIndex);
  }

  String get _coachText {
    if (feedback != null) return feedback!;
    if (researchTrial?.condition == 'stop' && !showingStimulus) {
      return AppText.gameplay.stopGuide;
    }
    if (showingStimulus) {
      return widget.type == GameType.objectTracker
          ? AppText.gameplay.trackingGuide
          : AppText.gameplay.watchGuide;
    }
    return step.instruction;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppText.tutorialTitle(widget.type.title))),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSettings.gameGridBreakpoint,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
      const SizedBox(height: 12),
      ProgressMeter(
        label: AppText.gameplay.tutorialProgress,
        value: stepIndex / stepCount,
        trailing: AppText.tutorialStep(stepIndex + 1, stepCount),
        color: context.gameAccent(widget.type),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: SingleChildScrollView(
          child: AppCard(
            child: Column(
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  label: _coachText,
                  child: Text(
                    _coachText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: feedback == step.retryMessage
                          ? context.brain.danger
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                IgnorePointer(ignoring: advancing, child: _gameBoard()),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _gameBoard() => switch (widget.type) {
    GameType.colorClash => ColorClashBoard(
      trial: colorTrial,
      onAnswer: _answerColor,
      guide: _guide,
    ),
    GameType.mathBlitz => MathBlitzBoard(
      trial: mathTrial,
      onAnswer: _answerMath,
      guide: _guide,
    ),
    _ => ResearchGameBoard(
      type: widget.type,
      difficulty: 1,
      trial: researchTrial!,
      showingStimulus: showingStimulus,
      trialNumber: stepIndex,
      onAnswer: _answerResearch,
      guide: _guide,
    ),
  };

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
        AppText.tutorialComplete(widget.type.title),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      Text(AppText.gameplay.tutorialUnscored, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      PrimaryAction(
        expanded: true,
        color: context.brain.success,
        onPressed: () => Navigator.pop(context, true),
        icon: Icons.play_arrow_rounded,
        label: widget.completionActionLabel,
      ),
    ],
  );
}
