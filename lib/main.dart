import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/bootstrap.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_service.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/storage/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final availability = await FirebaseBootstrap.initialize();
  AuthController auth = AuthController(
    availability.configured ? FirebaseAuthService() : OfflineAuthService(),
  );
  try {
    await auth.initialize();
  } catch (_) {
    auth.dispose();
    auth = AuthController(OfflineAuthService());
    await auth.initialize();
  }
  runApp(
    BrainFlexBootstrap(
      auth: auth,
      database: AppDatabase(),
      firebaseConfigured: availability.configured,
    ),
  );
}
