import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/state/brain_cubit.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import 'theme/brain_theme.dart';

class BrainScrollBehavior extends MaterialScrollBehavior {
  const BrainScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class BrainFlexApp extends StatelessWidget {
  const BrainFlexApp({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<BrainCubit, BrainViewState>(
    builder: (context, state) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BrainFlex',
      theme: buildBrainTheme(state.data.theme),
      scrollBehavior: const BrainScrollBehavior(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: .9, maxScaleFactor: 2),
          disableAnimations:
              state.data.reducedMotion ||
              MediaQuery.of(context).disableAnimations,
        ),
        child: child!,
      ),
      home: state.data.onboarded ? const AppShell() : const OnboardingScreen(),
    ),
  );
}
