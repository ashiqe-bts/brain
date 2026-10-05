import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/training/game_catalog.dart';
import 'package:brainflex/features/games/classic_game_board.dart';
import 'package:brainflex/features/games/game_tutorial_screen.dart';
import 'package:brainflex/features/games/game_experience.dart';
import 'package:brainflex/features/games/research_game_board.dart';
import 'package:brainflex/features/games/tutorial_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final game in activeGames) {
    testWidgets('${game.name} tutorial uses its production game board', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(GameTutorialScreen(type: game)));

      if (game == GameType.colorClash) {
        expect(find.byType(ColorClashBoard), findsOneWidget);
      } else if (game == GameType.mathBlitz) {
        expect(find.byType(MathBlitzBoard), findsOneWidget);
      } else {
        expect(find.byType(ResearchGameBoard), findsOneWidget);
      }
      expect(find.byType(GameStage), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Game stimulus:')), findsOneWidget);
      expect(find.textContaining('Score '), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('tutorial supports a 320px viewport at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GameTutorialScreen(type: GameType.colorClash),
        ),
      ),
    );

    expect(find.byType(ColorClashBoard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('helper hand appears after actionable inactivity', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GameTutorialScreen(type: GameType.colorClash)),
    );

    expect(find.byKey(tutorialHelperHandKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 2499));
    expect(find.byKey(tutorialHelperHandKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(tutorialHelperHandKey), findsOneWidget);
  });

  testWidgets(
    'wrong answer keeps the trial and reveals the helper immediately',
    (tester) async {
      await tester.pumpWidget(
        _app(const GameTutorialScreen(type: GameType.colorClash)),
      );
      final board = tester.widget<ColorClashBoard>(
        find.byType(ColorClashBoard),
      );
      final wrong = List.generate(
        4,
        (index) => index,
      ).firstWhere((index) => index != board.trial.colorIndex);

      await tester.tap(find.text(colorAnswerLabels[wrong]));
      await tester.pump();

      expect(
        find.text(
          gameDefinition(GameType.colorClash).tutorial.steps.first.retryMessage,
        ),
        findsOneWidget,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byKey(tutorialHelperHandKey), findsOneWidget);
      expect(
        tester.widget<ColorClashBoard>(find.byType(ColorClashBoard)).trial,
        board.trial,
      );
    },
  );

  testWidgets('completing real math trials returns success', (tester) async {
    bool? completed;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              completed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const GameTutorialScreen(type: GameType.mathBlitz),
                ),
              );
            },
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      final board = tester.widget<MathBlitzBoard>(find.byType(MathBlitzBoard));
      await tester.tap(find.text(board.trial.isCorrect ? 'TRUE' : 'FALSE'));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.tap(find.text('Start playing'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets('stop tutorial retries a tap and succeeds by waiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GameTutorialScreen(type: GameType.signalStop)),
    );

    await _finishCurrentResearchStep(tester);
    final stopBoard = tester.widget<ResearchGameBoard>(
      find.byType(ResearchGameBoard),
    );
    expect(stopBoard.trial.condition, 'stop');
    await tester.tap(find.text('TAP'));
    await tester.pump();
    expect(find.byKey(tutorialHelperHandKey), findsOneWidget);
    expect(find.textContaining('do not tap', findRichText: true), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
    final retried = tester.widget<ResearchGameBoard>(
      find.byType(ResearchGameBoard),
    );
    await tester.pump(Duration(milliseconds: retried.trial.exposureMs + 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Start playing'), findsOneWidget);
  });

  for (final game in const [
    GameType.nBackNavigator,
    GameType.pairLink,
    GameType.objectTracker,
    GameType.towerPlanner,
    GameType.dualTaskDash,
  ]) {
    testWidgets('${game.name} preserves real state through completion', (
      tester,
    ) async {
      await tester.pumpWidget(_app(GameTutorialScreen(type: game)));

      for (
        var step = 0;
        step < gameDefinition(game).tutorial.steps.length;
        step++
      ) {
        await _finishCurrentResearchStep(tester);
      }

      expect(find.text('Start playing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget home) =>
    MaterialApp(theme: buildBrainTheme(BrainTheme.highContrast), home: home);

Future<void> _finishCurrentResearchStep(WidgetTester tester) async {
  var board = tester.widget<ResearchGameBoard>(find.byType(ResearchGameBoard));
  if (board.showingStimulus) {
    await tester.pump(Duration(milliseconds: board.trial.exposureMs));
    board = tester.widget<ResearchGameBoard>(find.byType(ResearchGameBoard));
  }
  final answer = find.widgetWithText(
    FilledButton,
    board.trial.options[board.trial.correctIndex],
  );
  await tester.ensureVisible(answer);
  await tester.tap(answer);
  await tester.pump(const Duration(milliseconds: 700));
}
