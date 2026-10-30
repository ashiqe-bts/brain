import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_service.dart';
import '../../core/widgets/common.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key, this.allowGuestContinuation = false});

  final bool allowGuestContinuation;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool createAccount = true;
  bool obscure = true;
  bool verificationSent = false;
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('BrainFlex account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: verificationSent ? _verification(auth) : _form(auth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AuthController? auth) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          createAccount ? 'Create your account' : 'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          createAccount
              ? 'Your guest progress stays with you. Verify your email to finish setup.'
              : 'Sign in to restore and merge your saved progress.',
          style: TextStyle(color: context.brain.textMuted),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            return text.contains('@') && text.contains('.')
                ? null
                : 'Enter a valid email address';
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: password,
          obscureText: obscure,
          autofillHints: createAccount
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: (value) =>
              (value?.length ?? 0) < 12 ? 'Use at least 12 characters' : null,
        ),
        if (auth?.error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              auth!.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 22),
        PrimaryAction(
          expanded: true,
          label: auth?.busy == true
              ? 'Please wait…'
              : createAccount
              ? 'Create account'
              : 'Sign in',
          icon: createAccount
              ? Icons.person_add_alt_1_rounded
              : Icons.login_rounded,
          onPressed: auth == null || auth.busy ? null : () => _submit(auth),
        ),
        if (!createAccount)
          TextButton(
            onPressed: auth?.busy == true ? null : () => _resetPassword(auth),
            child: const Text('Forgot password?'),
          ),
        const SizedBox(height: 18),
        const _OrDivider(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: auth == null || auth.busy
                ? null
                : () => _continueWithGoogle(auth),
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: const Text('Continue with Google'),
          ),
        ),
        if (widget.allowGuestContinuation) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue as guest'),
          ),
        ],
        const Divider(height: 28),
        TextButton(
          onPressed: () {
            auth?.clearError();
            setState(() => createAccount = !createAccount);
          },
          child: Text(
            createAccount
                ? 'Already have an account? Sign in'
                : 'New to BrainFlex? Create an account',
          ),
        ),
      ],
    ),
  );

  Widget _verification(AuthController? auth) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(
        Icons.mark_email_read_outlined,
        size: 58,
        color: context.brain.primary,
      ),
      const SizedBox(height: 18),
      Text(
        'Check your email',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'We sent a verification link to ${email.text.trim()}. You can keep training while you verify.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 22),
      PrimaryAction(
        expanded: true,
        label: 'I verified my email',
        icon: Icons.refresh_rounded,
        onPressed: auth == null
            ? null
            : () async {
                final ok = await auth.run(auth.service.refreshVerification);
                if (!mounted || !ok) return;
                if (auth.session.kind == AccountKind.account) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email is not verified yet. Try again after opening the link.',
                      ),
                    ),
                  );
                }
              },
      ),
      TextButton(
        onPressed: auth == null || resendSeconds > 0
            ? null
            : () async {
                final ok = await auth.run(auth.service.sendVerification);
                if (ok && mounted) _startResendCooldown();
              },
        child: Text(
          resendSeconds > 0
              ? 'Resend available in ${resendSeconds}s'
              : 'Resend verification email',
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Continue training'),
      ),
    ],
  );

  Future<void> _submit(AuthController auth) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final ok = await auth.run(
      () => createAccount
          ? auth.service.upgradeWithEmail(email.text, password.text)
          : auth.service.signInWithEmail(email.text, password.text),
    );
    if (!mounted || !ok) return;
    if (createAccount) {
      setState(() => verificationSent = true);
      _startResendCooldown();
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _continueWithGoogle(AuthController auth) async {
    final ok = await auth.run(auth.service.continueWithGoogle);
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _resetPassword(AuthController? auth) async {
    if (auth == null || !email.text.contains('@')) {
      formKey.currentState?.validate();
      return;
    }
    final ok = await auth.run(() => auth.service.sendPasswordReset(email.text));
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
  }

  void _startResendCooldown() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Alternative sign-in options',
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.brain.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}
