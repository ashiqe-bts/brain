import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts with a value-first welcome before asking for a name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('A calmer way to challenge your focus.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.enabled,
      ),
    );
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('welcome adapts to a wide Chrome-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('Private by design'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
