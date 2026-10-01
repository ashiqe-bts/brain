import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/core/training/game_catalog.dart';
import 'package:brainflex/features/games/game_screen.dart';
import 'package:brainflex/core/widgets/common.dart';
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

  for (final entry in {
    for (final game in activeGames) game: gameDefinition(game).instructions,
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
      expect(find.byType(SessionHud), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('peripheral focus exposes the trial and answer semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmDark),
          home: const GameScreen(
            type: GameType.peripheralFocus,
            mode: GameMode.relaxed,
            difficulty: 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').startsWith('Game stimulus:'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Answer option 1',
      ),
      findsOneWidget,
    );

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('session HUD fits a narrow viewport at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: buildBrainTheme(BrainTheme.highContrast),
            home: const GameScreen(
              type: GameType.colorClash,
              mode: GameMode.relaxed,
              difficulty: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3100));

    expect(find.byType(SessionHud), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
