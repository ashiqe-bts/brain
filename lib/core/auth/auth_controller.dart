import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.service) : _session = service.current;

  final AuthService service;
  AccountSession _session;
  StreamSubscription<AccountSession>? _subscription;
  Timer? _retryTimer;
  bool busy = false;
  String? error;

  AccountSession get session => _session;

  Future<void> initialize() async {
    _subscription = service.sessions.listen((value) {
      _session = value;
      notifyListeners();
    });
    await service.initialize();
    _session = service.current;
    if (_session.kind == AccountKind.offlineGuest &&
        service is! OfflineAuthService) {
      _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        if (_session.kind != AccountKind.offlineGuest) return;
        try {
          await service.initialize();
          _session = service.current;
          notifyListeners();
        } catch (_) {
          // Staying local is expected until connectivity returns.
        }
      });
    }
    notifyListeners();
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      _session = service.current;
      return true;
    } on FirebaseAuthException catch (exception) {
      error = _friendlyAuthError(exception.code);
      return false;
    } on FirebaseFunctionsException catch (exception) {
      error = _friendlyFunctionError(exception.code);
      return false;
    } catch (exception) {
      error = exception is AuthException
          ? exception.message
          : 'Something went wrong. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}

String _friendlyAuthError(String code) => switch (code) {
  'invalid-email' => 'Enter a valid email address.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'The email or password is incorrect.',
  'weak-password' => 'Use at least 12 characters for your password.',
  'too-many-requests' => 'Too many attempts. Please wait and try again.',
  'network-request-failed' =>
    'You appear to be offline. Try again when connected.',
  'popup-closed-by-user' ||
  'canceled-popup-request' => 'Google sign-in was cancelled.',
  'requires-recent-login' =>
    'Please sign in again before deleting your account.',
  _ => 'Authentication failed. Please try again.',
};

String _friendlyFunctionError(String code) => switch (code) {
  'deadline-exceeded' || 'not-found' =>
    'The transfer expired. Your local progress is safe and will sync.',
  'failed-precondition' =>
    'Please sign in again before completing this action.',
  'unavailable' =>
    'Progress sync is temporarily unavailable. Your local progress is safe.',
  _ => 'The account action could not finish. Your local progress is safe.',
};
