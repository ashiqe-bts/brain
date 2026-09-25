import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/shell/app_shell.dart';

void main() {
  late AppDatabase database;
  late BrainRepository repository;
  late BrainCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BrainRepository(database);
    cubit = BrainCubit(repository, BrainState(onboarded: true));
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  testWidgets('uses Today, Train, and Insights without mascot or ads', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.midnight),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Lab'), findsNothing);
    expect(find.textContaining('Brain Buddy'), findsNothing);
    expect(find.textContaining('Demo Ad'), findsNothing);

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pumpAndSettle();

    expect(find.text('FIVE-SKILL PROFILE'), findsOneWidget);
    expect(find.text('Baseline 0 of 3'), findsOneWidget);
  });
}
