import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/daily_workout/workout_selection_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('random five selects five unique games and enables start', (
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
    await tester.tap(find.text('Random 5'));
    await tester.pump();

    expect(find.text('5 of 5 selected'), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find
          .ancestor(
            of: find.text('Start selected workout'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          )
          .first,
    );
    expect(start.enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
