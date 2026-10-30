import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/auth/auth_controller.dart';
import 'package:brainflex/core/auth/auth_service.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/onboarding/onboarding_screen.dart';
import 'package:brainflex/core/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('get started opens the unified authentication gateway', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('A calmer way to challenge your focus.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with email'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(AppCard), findsNothing);

    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.enabled,
      ),
    );
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('continue as guest advances to the name step', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: const OnboardingScreen(),
      ),
    );

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
  });

  testWidgets('successful Google authentication advances onboarding', (
    tester,
  ) async {
    final service = _FakeAuthService();
    final controller = AuthController(service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const OnboardingScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(service.googleAttempts, 1);
    expect(find.text('What should we call you?'), findsOneWidget);
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

  testWidgets(
    'mobile welcome aligns feature details below the primary action',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const OnboardingScreen(),
        ),
      );

      final featureIcons = [
        find.byIcon(Icons.timer_outlined),
        find.byIcon(Icons.person_outline_rounded),
        find.byIcon(Icons.lock_outline_rounded),
      ];
      final iconLefts = featureIcons
          .map((finder) => tester.getTopLeft(finder).dx)
          .toList();
      expect(iconLefts.toSet(), hasLength(1));

      final getStarted = find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.enabled,
      );
      expect(
        tester.getBottomLeft(getStarted).dy,
        lessThan(tester.getTopLeft(featureIcons.first).dy),
      );
    },
  );

  testWidgets('name continues directly to routine without a color test', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrainTheme(BrainTheme.calmLight),
        home: const OnboardingScreen(),
      ),
    );

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Asha');
    await tester.pump();
    final continueButton = tester.widget<FilledButton>(
      find
          .ancestor(
            of: find.text('Continue'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          )
          .first,
    );
    continueButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Practice on your schedule'), findsOneWidget);
    expect(find.text('Tap the ink color'), findsNothing);
    expect(find.text('2 of 2'), findsOneWidget);
  });
}

class _FakeAuthService implements AuthService {
  AccountSession session = const AccountSession(
    uid: 'guest',
    kind: AccountKind.guest,
  );
  int googleAttempts = 0;

  @override
  AccountSession get current => session;
  @override
  Stream<AccountSession> get sessions => Stream.value(session);
  @override
  Future<void> initialize() async {}
  @override
  Future<void> continueWithGoogle() async {
    googleAttempts++;
    session = const AccountSession(uid: 'account', kind: AccountKind.account);
  }

  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> refreshVerification() async {}
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> sendVerification() async {}
  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signOutToGuest() async {}
  @override
  Future<void> upgradeWithEmail(String email, String password) async {}
}
