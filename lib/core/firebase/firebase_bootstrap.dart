import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseAvailability {
  const FirebaseAvailability({required this.configured, this.error});
  final bool configured;
  final Object? error;
}

abstract final class FirebaseBootstrap {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _appCheckSiteKey = String.fromEnvironment(
    'FIREBASE_APP_CHECK_SITE_KEY',
  );
  static const _useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  static bool get hasConfiguration =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static Future<FirebaseAvailability> initialize() async {
    if (!hasConfiguration) return const FirebaseAvailability(configured: false);
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          authDomain: _authDomain.isEmpty ? null : _authDomain,
        ),
      );
      if (_useEmulators) {
        final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        FirebaseFunctions.instanceFor(
          region: 'asia-south1',
        ).useFunctionsEmulator(host, 5001);
      } else if (!kIsWeb || _appCheckSiteKey.isNotEmpty) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerWeb: kIsWeb
              ? ReCaptchaEnterpriseProvider(_appCheckSiteKey)
              : null,
        );
      }
      return const FirebaseAvailability(configured: true);
    } catch (error) {
      return FirebaseAvailability(configured: false, error: error);
    }
  }
}
