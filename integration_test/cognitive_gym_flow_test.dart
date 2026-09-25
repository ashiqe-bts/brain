import 'package:brainflex/app/app.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/state/brain_cubit.dart';
import 'package:brainflex/core/storage/app_database.dart';
import 'package:brainflex/core/storage/brain_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch and persisted three-workout baseline flow', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = BrainRepository(database);
    final firstCubit = BrainCubit(repository, BrainState());
    addTearDown(() async {
      await firstCubit.close();
      await repository.close();
    });

    await tester.pumpWidget(
      BlocProvider.value(value: firstCubit, child: const BrainFlexApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('A personal cognitive gym'), findsOneWidget);
    expect(find.textContaining('Brain Buddy'), findsNothing);
    expect(find.textContaining('Demo Ad'), findsNothing);

    await repository.save(
      BrainState(
        onboarded: true,
        workouts: 3,
        daily: [
          _summary('2026-09-21'),
          _summary('2026-09-22'),
          _summary('2026-09-23'),
        ],
      ),
    );
    final restoredCubit = BrainCubit(repository, await repository.load());
    addTearDown(restoredCubit.close);

    await tester.pumpWidget(
      BlocProvider.value(value: restoredCubit, child: const BrainFlexApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Personal baseline complete'), findsOneWidget);
    expect(find.text('FIVE-SKILL PROFILE'), findsOneWidget);
  });
}

DailySummary _summary(String date) => DailySummary(
  date: date,
  results: const [],
  skillRatings: const {
    SkillDomain.focus: 2,
    SkillDomain.calculation: 2,
    SkillDomain.memory: 2,
    SkillDomain.reaction: 2,
    SkillDomain.visualSearch: 2,
  },
);
