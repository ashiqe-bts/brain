import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/app/app.dart';
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
    cubit = BrainCubit(
      repository,
      BrainState(onboarded: true, displayName: 'Asha'),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  testWidgets('uses Today, Train, and Insights without retired surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmDark),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Hey, Asha'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Lab'), findsNothing);
    expect(find.textContaining('Demo Ad'), findsNothing);

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Color Clash'), 300);
    expect(find.byTooltip('Tutorial for Color Clash'), findsOneWidget);
    expect(find.text('Challenge My Best'), findsNothing);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Fifteen-game profile'), findsOneWidget);
    expect(find.text('0 of 15 game baselines ready'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.byTooltip('Research basis for Color Clash'), findsOneWidget);
  });

  testWidgets('existing users without a name receive the profile gate', (
    tester,
  ) async {
    final unnamedCubit = BrainCubit(repository, BrainState(onboarded: true));
    addTearDown(unnamedCubit.close);

    await tester.pumpWidget(
      BlocProvider.value(value: unnamedCubit, child: const BrainFlexApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your name'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('supports 200 percent text and high contrast navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: buildBrainTheme(BrainTheme.highContrast),
            home: const AppShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Color Clash'), 300);
    expect(find.byTooltip('Tutorial for Color Clash'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a navigation rail on expanded Chrome layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
