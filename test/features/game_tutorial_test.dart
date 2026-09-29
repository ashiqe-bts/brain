import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/training/game_catalog.dart';
import 'package:brainflex/features/games/game_tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final game in activeGames) {
    testWidgets('${game.name} tutorial supports 200% text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrainTheme(BrainTheme.highContrast),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: GameTutorialScreen(type: game),
          ),
        ),
      );

      expect(
        find.text(gameDefinition(game).tutorial.steps.first.title),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('wrong answers explain and retry the same tutorial step', (
    tester,
  ) async {
    final tutorial = gameDefinition(GameType.colorClash).tutorial;
    final first = tutorial.steps.first;
    final wrong = List.generate(
      first.options.length,
      (index) => index,
    ).firstWhere((index) => index != first.correctIndex);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.highContrast),
        home: const GameTutorialScreen(type: GameType.colorClash),
      ),
    );

    await tester.tap(find.text(first.options[wrong]));
    await tester.pump();

    expect(find.text(first.retryMessage), findsOneWidget);
    expect(find.text(first.title), findsOneWidget);
  });

  testWidgets('completing every guided step returns success', (tester) async {
    bool? completed;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmDark),
        home: Builder(
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

    final steps = gameDefinition(GameType.mathBlitz).tutorial.steps;
    for (final step in steps) {
      await tester.tap(find.text(step.options[step.correctIndex]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.tap(find.text('START PLAYING'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets('stop tutorial retries a tap and succeeds by waiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmDark),
        home: const GameTutorialScreen(type: GameType.signalStop),
      ),
    );
    final tutorial = gameDefinition(GameType.signalStop).tutorial;
    await tester.tap(find.text(tutorial.steps.first.options.first));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('TAP'));
    await tester.pump();
    expect(find.text(tutorial.steps[1].retryMessage), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('START PLAYING'), findsOneWidget);
  });
}
