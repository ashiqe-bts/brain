import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'core/state/brain_cubit.dart';
import 'core/storage/app_database.dart';
import 'core/storage/brain_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final repository = BrainRepository(AppDatabase());
  final cubit = BrainCubit(repository, await repository.load());
  await cubit.bootstrap();
  runApp(BlocProvider.value(value: cubit, child: const BrainFlexApp()));
}
