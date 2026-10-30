import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AccountKind { offlineGuest, guest, verificationPending, account }

class AccountSession {
  const AccountSession({
    required this.uid,
    required this.kind,
    this.email,
    this.displayName,
  });

  final String uid;
  final AccountKind kind;
  final String? email;
  final String? displayName;

  bool get isGuest =>
      kind == AccountKind.guest || kind == AccountKind.offlineGuest;
}

abstract interface class AuthService {
  Stream<AccountSession> get sessions;
  AccountSession get current;
  Future<void> initialize();
  Future<void> upgradeWithEmail(String email, String password);
  Future<void> signInWithEmail(String email, String password);
  Future<void> continueWithGoogle();
  Future<void> sendVerification();
  Future<void> refreshVerification();
  Future<void> sendPasswordReset(String email);
  Future<void> signOutToGuest();
  Future<void> deleteAccount();
}

class OfflineAuthService implements AuthService {
  OfflineAuthService()
    : _current = const AccountSession(
        uid: 'offline-guest',
        kind: AccountKind.offlineGuest,
      );

  final AccountSession _current;
  @override
  AccountSession get current => _current;
  @override
  Stream<AccountSession> get sessions => Stream.value(_current);
  @override
  Future<void> initialize() async {}

  Never _unavailable() => throw const AuthException(
    'Accounts are unavailable until Firebase is configured and online.',
  );

  @override
  Future<void> continueWithGoogle() async => _unavailable();
  @override
  Future<void> deleteAccount() async => _unavailable();
  @override
  Future<void> refreshVerification() async => _unavailable();
  @override
  Future<void> sendPasswordReset(String email) async => _unavailable();
  @override
  Future<void> sendVerification() async => _unavailable();
  @override
  Future<void> signInWithEmail(String email, String password) async =>
      _unavailable();
  @override
  Future<void> signOutToGuest() async {}
  @override
  Future<void> upgradeWithEmail(String email, String password) async =>
      _unavailable();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFunctions? functions})
    : auth = auth ?? FirebaseAuth.instance,
      functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseAuth auth;
  final FirebaseFunctions functions;
  bool _googleInitialized = false;
  String? _pendingTransferToken;

  @override
  AccountSession get current => _session(auth.currentUser);

  @override
  Stream<AccountSession> get sessions => auth
      .userChanges()
      .where((user) => user != null)
      .map((user) => _session(user));

  @override
  Future<void> initialize() async {
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'network-request-failed') rethrow;
      }
    }
  }

  @override
  Future<void> upgradeWithEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final user = auth.currentUser;
    if (user == null) throw const AuthException('No guest session is active.');
    try {
      final result = await user.linkWithCredential(credential);
      await result.user?.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      if (!_credentialExists(error.code)) rethrow;
      await _transferAndSignIn(() => auth.signInWithCredential(credential));
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await _transferAndSignIn(() => auth.signInWithCredential(credential));
  }

  @override
  Future<void> continueWithGoogle() async {
    AuthCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final currentUser = auth.currentUser;
      try {
        if (currentUser?.isAnonymous ?? false) {
          await currentUser!.linkWithPopup(provider);
        } else {
          await auth.signInWithPopup(provider);
        }
        return;
      } on FirebaseAuthException catch (error) {
        if (!_credentialExists(error.code)) rethrow;
        await _transferAndSignIn(() => auth.signInWithPopup(provider));
        return;
      }
    }
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final token = googleUser.authentication.idToken;
    if (token == null) {
      throw const AuthException('Google did not return an ID token.');
    }
    credential = GoogleAuthProvider.credential(idToken: token);
    final currentUser = auth.currentUser;
    try {
      if (currentUser?.isAnonymous ?? false) {
        await currentUser!.linkWithCredential(credential);
      } else {
        await auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (error) {
      if (!_credentialExists(error.code)) rethrow;
      await _transferAndSignIn(() => auth.signInWithCredential(credential));
    }
  }

  Future<void> _transferAndSignIn(
    Future<UserCredential> Function() signIn,
  ) async {
    var token = _pendingTransferToken;
    if (token == null && (auth.currentUser?.isAnonymous ?? false)) {
      final prepared = await functions
          .httpsCallable('prepareGuestTransfer')
          .call<Map<String, dynamic>>();
      token = prepared.data['token'] as String?;
      _pendingTransferToken = token;
    }
    await signIn();
    if (token != null) {
      try {
        await functions.httpsCallable('completeGuestTransfer').call<void>({
          'token': token,
        });
        _pendingTransferToken = null;
      } on FirebaseFunctionsException catch (error) {
        if (error.code == 'deadline-exceeded' || error.code == 'not-found') {
          _pendingTransferToken = null;
        }
        rethrow;
      }
    }
  }

  @override
  Future<void> sendVerification() async {
    final user = auth.currentUser;
    if (user == null || user.email == null || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<void> refreshVerification() async {
    await auth.currentUser?.reload();
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOutToGuest() async {
    await auth.signOut();
    await auth.signInAnonymously();
  }

  @override
  Future<void> deleteAccount() async {
    await functions.httpsCallable('deleteAccount').call<void>();
    await auth.signOut();
    await auth.signInAnonymously();
  }
}

AccountSession _session(User? user) {
  if (user == null) {
    return const AccountSession(
      uid: 'offline-guest',
      kind: AccountKind.offlineGuest,
    );
  }
  final kind = user.isAnonymous
      ? AccountKind.guest
      : user.email != null && !user.emailVerified
      ? AccountKind.verificationPending
      : AccountKind.account;
  return AccountSession(
    uid: user.uid,
    kind: kind,
    email: user.email,
    displayName: user.displayName,
  );
}

bool _credentialExists(String code) =>
    code == 'credential-already-in-use' ||
    code == 'email-already-in-use' ||
    code == 'account-exists-with-different-credential';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
