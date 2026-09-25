import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/games/game_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BrainRepository repository;
  late BrainCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BrainRepository(database);
    cubit = BrainCubit(
      repository,
      BrainState(onboarded: true, sound: false, haptics: false),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  for (final entry in <GameType, String>{
    GameType.colorClash: 'Tap the INK color, not the word',
    GameType.mathBlitz: 'Is this equation correct?',
    GameType.memoryTiles: 'Remember the glowing tiles',
    GameType.reflexTap: 'WAIT…',
    GameType.visualSearch: 'Find the target',
  }.entries) {
    testWidgets('${entry.key.name} starts with accessible instructions', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: buildBrainTheme(BrainTheme.highContrast),
            home: GameScreen(
              type: entry.key,
              mode: GameMode.relaxed,
              difficulty: 1,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 3100));

      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('visual search exposes target and grid semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.midnight),
          home: const GameScreen(
            type: GameType.visualSearch,
            mode: GameMode.relaxed,
            difficulty: 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3100));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Target symbol',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Search item 1',
      ),
      findsOneWidget,
    );

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
