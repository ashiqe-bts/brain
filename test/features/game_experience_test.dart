import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/app/theme/game_visuals.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/games/game_experience.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every active game has a distinct scene and thumbnail treatment', () {
    final specs = activeGames.map(gameVisualFor).toList();

    expect(
      specs.map((spec) => spec.motif).toSet(),
      hasLength(activeGames.length),
    );
    expect(specs.every((spec) => spec.sceneLabel.isNotEmpty), isTrue);
  });

  testWidgets('game stage exposes a labelled raised play surface', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const GameStage(game: GameType.memoryTiles, child: Text('BOARD'))),
    );

    expect(find.byKey(gameStageKey), findsOneWidget);
    expect(find.text('BOARD'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Memory Tiles game board')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('celebrations identify round and daily variants', (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            CelebrationOverlay(level: CelebrationLevel.round),
            CelebrationOverlay(level: CelebrationLevel.daily),
          ],
        ),
      ),
    );

    expect(find.byKey(roundCelebrationKey), findsOneWidget);
    expect(find.byKey(dailyCelebrationKey), findsOneWidget);
    expect(
      tester.widget<IgnorePointer>(find.byKey(roundCelebrationKey)).ignoring,
      isTrue,
    );
    expect(find.bySemanticsLabel('Round complete'), findsOneWidget);
    expect(find.bySemanticsLabel('Daily workout complete'), findsOneWidget);
  });

  testWidgets('reduced motion celebrations render a still starburst', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: _Themed(
          child: CelebrationOverlay(level: CelebrationLevel.daily),
        ),
      ),
    );

    expect(find.byKey(stillCelebrationKey), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Widget _app(Widget home) => _Themed(child: home);

class _Themed extends StatelessWidget {
  const _Themed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildBrainTheme(BrainTheme.calmLight),
    home: Scaffold(body: child),
  );
}
