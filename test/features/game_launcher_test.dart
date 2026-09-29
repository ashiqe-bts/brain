import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/games/game_launcher.dart';
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
      BrainState(onboarded: true, displayName: 'Asha'),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  testWidgets('first launch is gated and quitting records nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(cubit));
    await tester.tap(find.text('LAUNCH'));
    await tester.pumpAndSettle();

    expect(find.text('Math Blitz tutorial'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(cubit.hasCompletedTutorial(GameType.mathBlitz), isFalse);
    expect(cubit.data.history, isEmpty);
  });

  testWidgets('completed tutorial persists and next launch skips it', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(cubit));
    await tester.tap(find.text('LAUNCH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUE'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('FALSE'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Start playing'));
    await tester.pumpAndSettle();

    expect(cubit.hasCompletedTutorial(GameType.mathBlitz), isTrue);
    expect(find.text('Math Blitz tutorial'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LAUNCH'));
    await tester.pump();

    expect(find.text('Math Blitz tutorial'), findsNothing);
    expect(cubit.data.history, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _harness(BrainCubit cubit) => BlocProvider.value(
  value: cubit,
  child: MaterialApp(
    theme: buildBrainTheme(BrainTheme.calmDark),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => launchGameSession(
              context: context,
              type: GameType.mathBlitz,
              mode: GameMode.relaxed,
              difficulty: 1,
            ),
            child: const Text('LAUNCH'),
          ),
        ),
      ),
    ),
  ),
);
