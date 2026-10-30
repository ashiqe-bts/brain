import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/daily_workout/workout_selection_screen.dart';
import 'package:brainflex/app/theme/game_visuals.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('daily route contains one stage per region and a bonus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = BrainRepository(database);
    final cubit = BrainCubit(
      repository,
      BrainState(onboarded: true, displayName: 'Asha'),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const WorkoutSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Focus Frontier'), findsWidgets);
    expect(find.text('Memory Grove'), findsWidgets);
    expect(find.text('Puzzle Peaks'), findsWidgets);
    expect(find.text('Optional bonus'), findsOneWidget);
    expect(find.byKey(const Key('nova-mascot')), findsNothing);
    final start = tester.widget<FilledButton>(
      find
          .ancestor(
            of: find.text('Start expedition'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          )
          .first,
    );
    expect(start.enabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expedition preview uses a persistent mobile action and compact route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = BrainRepository(database);
      final cubit = BrainCubit(
        repository,
        BrainState(onboarded: true, displayName: 'Asha'),
      );
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: buildBrainTheme(BrainTheme.calmLight),
            home: const WorkoutSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Today's route"), findsOneWidget);
      expect(
        find.text('Three short stages, balanced across your map.'),
        findsOneWidget,
      );
      expect(find.text('Start expedition'), findsOneWidget);
      expect(find.byType(GameThumbnail), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
