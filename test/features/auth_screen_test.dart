import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/auth/auth_controller.dart';
import 'package:brainflex/core/auth/auth_service.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/auth/email_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('email sign-up validates email and strong password', (
    tester,
  ) async {
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 12 characters'), findsOneWidget);
  });

  testWidgets('successful sign-up presents verification actions', (
    tester,
  ) async {
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'asha@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'a-secure-password',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Continue training'), findsOneWidget);
    expect(find.textContaining('Resend available in'), findsOneWidget);
  });

  testWidgets('guest and Google choices are opt-in gateway actions', (
    tester,
  ) async {
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(allowGuestContinuation: true),
        ),
      ),
    );

    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('account settings version does not offer guest continuation', (
    tester,
  ) async {
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(),
        ),
      ),
    );

    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets('Google failure stays on the gateway with a live error', (
    tester,
  ) async {
    final controller = AuthController(
      _FakeAuthService(googleError: const AuthException('Google unavailable.')),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(allowGuestContinuation: true),
        ),
      ),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(find.text('Google unavailable.'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('gateway fits a narrow viewport at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: AuthScope(
          controller: controller,
          child: MaterialApp(
            theme: buildBrainTheme(BrainTheme.calmLight),
            home: const EmailAuthScreen(allowGuestContinuation: true),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus moves from email to password', (tester) async {
    final controller = AuthController(_FakeAuthService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: controller,
        child: MaterialApp(
          theme: buildBrainTheme(BrainTheme.calmLight),
          home: const EmailAuthScreen(allowGuestContinuation: true),
        ),
      ),
    );

    final fields = find.byType(EditableText);
    await tester.tap(fields.at(0));
    await tester.pump();
    expect(
      tester.widget<EditableText>(fields.at(0)).focusNode.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester.widget<EditableText>(fields.at(1)).focusNode.hasFocus,
      isTrue,
    );
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.googleError});

  final Object? googleError;
  AccountSession session = const AccountSession(
    uid: 'guest',
    kind: AccountKind.guest,
  );

  @override
  AccountSession get current => session;
  @override
  Stream<AccountSession> get sessions => Stream.value(session);
  @override
  Future<void> initialize() async {}
  @override
  Future<void> upgradeWithEmail(String email, String password) async {
    session = AccountSession(
      uid: 'guest',
      kind: AccountKind.verificationPending,
      email: email,
    );
  }

  @override
  Future<void> continueWithGoogle() async {
    if (googleError case final error?) throw error;
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
}
