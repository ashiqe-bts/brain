import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:brainflex/features/progress/progress_screen.dart';
import 'package:brainflex/features/progress/session_result_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BrainRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BrainRepository(database);
  });

  tearDown(() async => repository.close());

  testWidgets('session review exposes graph and curated metrics', (
    tester,
  ) async {
    final result = _result(3, mode: GameMode.relaxed);
    final cubit = BrainCubit(
      repository,
      BrainState(history: [_result(1), _result(2), result]),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _harness(cubit, SessionResultScreen(result: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Round complete'), findsOneWidget);
    expect(find.text('Progress graph'), findsOneWidget);
    expect(
      find.textContaining('excluded from progress trends'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('All measured skills'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('All measured skills'), findsOneWidget);
    expect(find.text('Training level'), findsWidgets);
    expect(find.text('Accuracy'), findsWidgets);
    expect(find.text('Back to Train'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('insights includes combined progress without an overall score', (
    tester,
  ) async {
    final cubit = BrainCubit(
      repository,
      BrainState(history: [_result(1), _result(2), _result(3)]),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit, const ProgressScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Combined progress'), findsOneWidget);
    expect(find.textContaining('does not average'), findsOneWidget);
    expect(find.text('View details'), findsWidgets);
    expect(find.textContaining('overall score'), findsOneWidget);
  });
}

Widget _harness(BrainCubit cubit, Widget home) => BlocProvider.value(
  value: cubit,
  child: MaterialApp(
    theme: buildBrainTheme(BrainTheme.highContrast),
    home: home,
  ),
);

GameResult _result(int day, {GameMode mode = GameMode.standard}) => GameResult(
  type: GameType.colorClash,
  mode: mode,
  score: 80,
  normalized: 80,
  accuracy: .85,
  durationMs: 30000,
  difficulty: 3,
  completedAt: DateTime.utc(2026, 1, day),
  rulesVersion: GameType.colorClash.rulesVersion,
  metrics: const {'medianResponseMs': 650, 'interferenceCostMs': 90},
);
