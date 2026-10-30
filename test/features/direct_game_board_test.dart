import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/games/classic_game_board.dart';
import 'package:brainflex/features/games/game_engine.dart';
import 'package:brainflex/features/games/research_game_board.dart';
import 'package:brainflex/features/games/research_game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(ResearchTrial trial, ValueChanged<int> onAnswer) => MaterialApp(
    theme: buildBrainTheme(BrainTheme.calmLight),
    home: Scaffold(
      body: ResearchGameBoard(
        type: switch (trial.visual) {
          MemoryGridVisual() => GameType.memoryTiles,
          TrackingVisual() => GameType.objectTracker,
          _ => GameType.towerPlanner,
        },
        difficulty: 1,
        trial: trial,
        showingStimulus: false,
        trialNumber: 1,
        onAnswer: onAnswer,
      ),
    ),
  );

  testWidgets('Number Forge supports swipe with tap gates still available', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: Scaffold(
          body: MathBlitzBoard(
            trial: const MathTrial(
              left: 2,
              right: 3,
              operator: '+',
              actual: 5,
              shown: 5,
            ),
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    await tester.fling(
      find.byKey(const ValueKey('equation-swipe-card')),
      const Offset(300, 0),
      900,
    );

    expect(answer, isTrue);
    expect(find.text('TRUE'), findsOneWidget);
    expect(find.text('FALSE'), findsOneWidget);
  });

  testWidgets('Glow Garden answers by directly tapping the changed tile', (
    tester,
  ) async {
    var answer = -1;
    const trial = ResearchTrial(
      prompt: '1,2',
      cue: '1,2,5',
      options: ['Tile 2', 'Tile 5', 'Tile 7', 'Tile 8'],
      correctIndex: 1,
      visual: MemoryGridVisual(before: {0, 1}, after: {0, 1, 4}),
    );

    await tester.pumpWidget(host(trial, (value) => answer = value));
    await tester.tap(find.byKey(const ValueKey('memory-tile-5')));

    expect(answer, 1);
    expect(find.text('Tile 5'), findsNothing);
  });

  testWidgets('Firefly Tracker uses direct multi-select and submit', (
    tester,
  ) async {
    var answer = -1;
    const trial = ResearchTrial(
      prompt: 'Track objects 1-2',
      cue: 'Choose their final positions',
      options: ['B-D', 'A-C', 'D-F', 'C-E'],
      correctIndex: 0,
      visual: TrackingVisual(targets: [0, 1], movement: [1, 3, 0, 2, 4, 5]),
      span: 2,
      movement: [1, 3, 0, 2, 4, 5],
    );

    await tester.pumpWidget(host(trial, (value) => answer = value));
    await tester.tap(find.byKey(const ValueKey('firefly-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('firefly-1')));
    await tester.pump();
    await tester.tap(find.text('Confirm fireflies'));

    expect(answer, 0);
    expect(find.text('B-D'), findsNothing);
  });

  testWidgets('Totem Towers moves with source and destination peg taps', (
    tester,
  ) async {
    var answer = -1;
    const move = TowerMove(disk: 1, from: 0, to: 1);
    const trial = ResearchTrial(
      prompt: 'Move every disk to peg 2',
      cue: 'Only smaller disks may sit on larger disks',
      options: ['Move disk 1: 1 → 2'],
      correctIndex: 0,
      visual: TowerVisual(
        pegs: [
          [2, 1],
          [],
          [],
        ],
        target: 1,
      ),
      towerMoves: [move],
    );

    await tester.pumpWidget(host(trial, (value) => answer = value));
    await tester.tap(find.byKey(const ValueKey('tower-peg-0')));
    await tester.tap(find.byKey(const ValueKey('tower-peg-1')));

    expect(answer, 0);
    expect(find.text(move.label), findsNothing);
  });
}
