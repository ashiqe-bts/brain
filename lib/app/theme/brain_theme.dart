import 'package:flutter/material.dart';
import '../../core/models/brain_models.dart';

class BrainPalette {
  const BrainPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.secondary,
    required this.reward,
    required this.success,
    required this.danger,
    required this.text,
  });
  final Color background,
      surface,
      surfaceHigh,
      primary,
      secondary,
      reward,
      success,
      danger,
      text;
}

BrainPalette paletteFor(BrainTheme theme) => switch (theme) {
  BrainTheme.midnight => const BrainPalette(
    background: Color(0xFF0A1023),
    surface: Color(0xFF151D38),
    surfaceHigh: Color(0xFF202B4B),
    primary: Color(0xFF9B6DFF),
    secondary: Color(0xFF37E6D2),
    reward: Color(0xFFFFCE57),
    success: Color(0xFF68E6A5),
    danger: Color(0xFFFF7185),
    text: Color(0xFFF7F5FF),
  ),
  BrainTheme.oled => const BrainPalette(
    background: Colors.black,
    surface: Color(0xFF101014),
    surfaceHigh: Color(0xFF202028),
    primary: Color(0xFFA77BFF),
    secondary: Color(0xFF3CF5E0),
    reward: Color(0xFFFFD257),
    success: Color(0xFF76F1B3),
    danger: Color(0xFFFF7185),
    text: Colors.white,
  ),
  BrainTheme.daydream => const BrainPalette(
    background: Color(0xFFFFF8EE),
    surface: Colors.white,
    surfaceHigh: Color(0xFFF0E9FF),
    primary: Color(0xFF7651D6),
    secondary: Color(0xFF00A99A),
    reward: Color(0xFFE09C00),
    success: Color(0xFF168A57),
    danger: Color(0xFFD8485F),
    text: Color(0xFF29213B),
  ),
  BrainTheme.highContrast => const BrainPalette(
    background: Colors.black,
    surface: Color(0xFF151515),
    surfaceHigh: Color(0xFF292929),
    primary: Color(0xFFFFFF00),
    secondary: Color(0xFF00FFFF),
    reward: Color(0xFFFFC400),
    success: Color(0xFF00FF66),
    danger: Color(0xFFFF4664),
    text: Colors.white,
  ),
};

ThemeData buildBrainTheme(BrainTheme value) {
  final p = paletteFor(value);
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: value == BrainTheme.daydream
        ? Brightness.light
        : Brightness.dark,
    surface: p.surface,
    error: p.danger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme.copyWith(
      primary: p.primary,
      secondary: p.secondary,
      surface: p.surface,
      error: p.danger,
    ),
    scaffoldBackgroundColor: p.background,
    textTheme: Typography.material2021(
      platform: TargetPlatform.android,
    ).white.apply(bodyColor: p.text, displayColor: p.text),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.primary.withValues(alpha: .14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(80, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: .25),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.secondary,
      linearTrackColor: p.surfaceHigh,
    ),
  );
}

extension BrainContext on BuildContext {
  BrainPalette get brain => paletteFor(
    Theme.of(this).brightness == Brightness.light
        ? BrainTheme.daydream
        : BrainTheme.midnight,
  );
}
