import 'package:flutter/material.dart';
import '../../core/models/brain_models.dart';

@immutable
class BrainPalette extends ThemeExtension<BrainPalette> {
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
    required this.outline,
    required this.shadow,
    required this.highlight,
    required this.frame,
    required this.hud,
  });

  final Color background,
      surface,
      surfaceHigh,
      primary,
      secondary,
      reward,
      success,
      danger,
      text,
      outline,
      shadow,
      highlight,
      frame,
      hud;

  @override
  BrainPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? primary,
    Color? secondary,
    Color? reward,
    Color? success,
    Color? danger,
    Color? text,
    Color? outline,
    Color? shadow,
    Color? highlight,
    Color? frame,
    Color? hud,
  }) => BrainPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    reward: reward ?? this.reward,
    success: success ?? this.success,
    danger: danger ?? this.danger,
    text: text ?? this.text,
    outline: outline ?? this.outline,
    shadow: shadow ?? this.shadow,
    highlight: highlight ?? this.highlight,
    frame: frame ?? this.frame,
    hud: hud ?? this.hud,
  );

  @override
  BrainPalette lerp(covariant BrainPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BrainPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceHigh: mix(surfaceHigh, other.surfaceHigh),
      primary: mix(primary, other.primary),
      secondary: mix(secondary, other.secondary),
      reward: mix(reward, other.reward),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      text: mix(text, other.text),
      outline: mix(outline, other.outline),
      shadow: mix(shadow, other.shadow),
      highlight: mix(highlight, other.highlight),
      frame: mix(frame, other.frame),
      hud: mix(hud, other.hud),
    );
  }
}

BrainPalette paletteFor(BrainTheme theme) => switch (theme) {
  BrainTheme.midnight => const BrainPalette(
    background: Color(0xFF11172E),
    surface: Color(0xFF263B52),
    surfaceHigh: Color(0xFF35556D),
    primary: Color(0xFFB33BFF),
    secondary: Color(0xFF38C7FF),
    reward: Color(0xFFFFD83D),
    success: Color(0xFF80D42B),
    danger: Color(0xFFFF4963),
    text: Color(0xFFF9F7EF),
    outline: Color(0xFF142735),
    shadow: Color(0xFF07121A),
    highlight: Color(0xFFFFFFFF),
    frame: Color(0xFF4E6B7B),
    hud: Color(0xFF1C3042),
  ),
  BrainTheme.oled => const BrainPalette(
    background: Colors.black,
    surface: Color(0xFF17171D),
    surfaceHigh: Color(0xFF292A35),
    primary: Color(0xFFC044FF),
    secondary: Color(0xFF35CAFF),
    reward: Color(0xFFFFD83D),
    success: Color(0xFF7ED52D),
    danger: Color(0xFFFF4963),
    text: Colors.white,
    outline: Color(0xFF050505),
    shadow: Colors.black,
    highlight: Color(0xFFFFFFFF),
    frame: Color(0xFF41424F),
    hud: Color(0xFF111116),
  ),
  BrainTheme.daydream => const BrainPalette(
    background: Color(0xFFF0EFEC),
    surface: Color(0xFFFFF4D8),
    surfaceHigh: Color(0xFFFFFFFF),
    primary: Color(0xFF8D2BD1),
    secondary: Color(0xFF087FBC),
    reward: Color(0xFFFFC62E),
    success: Color(0xFF64AD1F),
    danger: Color(0xFFD9324D),
    text: Color(0xFF20333F),
    outline: Color(0xFF1E3440),
    shadow: Color(0xFFA8AFB1),
    highlight: Color(0xFFFFFFFF),
    frame: Color(0xFF9B482B),
    hud: Color(0xFFD8E7ED),
  ),
  BrainTheme.highContrast => const BrainPalette(
    background: Colors.black,
    surface: Color(0xFF101010),
    surfaceHigh: Color(0xFF252525),
    primary: Color(0xFFFFFF00),
    secondary: Color(0xFF00FFFF),
    reward: Color(0xFFFFD000),
    success: Color(0xFF00FF66),
    danger: Color(0xFFFF4664),
    text: Colors.white,
    outline: Colors.white,
    shadow: Colors.black,
    highlight: Colors.white,
    frame: Color(0xFFFFFF00),
    hud: Colors.black,
  ),
};

ThemeData buildBrainTheme(BrainTheme value) {
  final p = paletteFor(value);
  final light = value == BrainTheme.daydream;
  final onPrimary = contrastColorFor(p.primary, p);
  final onSecondary = contrastColorFor(p.secondary, p);
  final onError = contrastColorFor(p.danger, p);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: light ? Brightness.light : Brightness.dark,
        surface: p.surface,
        error: p.danger,
      ).copyWith(
        primary: p.primary,
        onPrimary: onPrimary,
        secondary: p.secondary,
        onSecondary: onSecondary,
        surface: p.surface,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.surface,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surfaceHigh,
        surfaceContainerHighest: p.surfaceHigh,
        onSurface: p.text,
        error: p.danger,
        onError: onError,
        outline: p.outline,
        outlineVariant: p.frame,
      );
  final typography = Typography.material2021(platform: TargetPlatform.android);
  final baseText = (light ? typography.black : typography.white).apply(
    bodyColor: p.text,
    displayColor: p.text,
    fontFamily: 'Nunito',
  );
  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.background,
    canvasColor: p.surface,
    dividerColor: p.outline.withValues(alpha: .28),
    disabledColor: p.text.withValues(alpha: .42),
    fontFamily: 'Nunito',
    iconTheme: IconThemeData(color: p.text),
    textTheme: baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.outline, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 52),
        backgroundColor: p.success,
        foregroundColor: const Color(0xFF162A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: p.outline, width: 3),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: .5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 50),
        foregroundColor: p.text,
        side: BorderSide(color: p.outline, width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.highlight : p.surfaceHigh,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.secondary : p.hud,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.outline),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceHigh,
      labelStyle: TextStyle(color: p.text.withValues(alpha: .72)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.outline, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.primary, width: 3),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.text.withValues(alpha: .78),
      textColor: p.text,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceHigh,
      selectedColor: p.reward,
      labelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w700),
      side: BorderSide(color: p.outline, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.hud,
      contentTextStyle: TextStyle(color: contrastColorFor(p.hud, p)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.outline, width: 2),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.secondary,
      linearTrackColor: p.hud,
      linearMinHeight: 12,
      borderRadius: BorderRadius.circular(8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.outline, width: 4),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: p.outline, width: 4),
      ),
    ),
  );
}

extension BrainContext on BuildContext {
  BrainPalette get brain => Theme.of(this).extension<BrainPalette>()!;
  Color get rewardInk => Theme.of(this).brightness == Brightness.light
      ? const Color(0xFF835C00)
      : brain.reward;
  Color onColor(Color background) => contrastColorFor(background, brain);
  Color gameAccent(GameType type) =>
      _gameAccent(type, light: Theme.of(this).brightness == Brightness.light);
  Color clashColor(int index) {
    final light = Theme.of(this).brightness == Brightness.light;
    const lightColors = [
      Color(0xFFD52E4B),
      Color(0xFF1268B3),
      Color(0xFF32823D),
      Color(0xFF8A6500),
    ];
    const darkColors = [
      Color(0xFFFF4963),
      Color(0xFF438CFA),
      Color(0xFF4CAF50),
      Color(0xFFFFC107),
    ];
    return (light ? lightColors : darkColors)[index];
  }
}

Color contrastColorFor(Color background, BrainPalette palette) {
  final dark = palette.outline;
  const light = Colors.white;
  double contrast(Color a, Color b) {
    final l1 = a.computeLuminance(), l2 = b.computeLuminance();
    return (l1 > l2 ? l1 + .05 : l2 + .05) / (l1 > l2 ? l2 + .05 : l1 + .05);
  }

  return contrast(background, dark) >= contrast(background, light)
      ? dark
      : light;
}

Color _gameAccent(GameType type, {required bool light}) =>
    switch ((type, light)) {
      (GameType.colorClash, true) => const Color(0xFFD52E4B),
      (GameType.mathBlitz, true) => const Color(0xFF1479B8),
      (GameType.memoryTiles, true) => const Color(0xFF8430C2),
      (GameType.reflexTap, true) => const Color(0xFFC86400),
      (GameType.visualSearch, true) => const Color(0xFF4B8F16),
      (GameType.colorClash, false) => const Color(0xFFFF4963),
      (GameType.mathBlitz, false) => const Color(0xFF38B9FF),
      (GameType.memoryTiles, false) => const Color(0xFFB638F3),
      (GameType.reflexTap, false) => const Color(0xFFFF961A),
      (GameType.visualSearch, false) => const Color(0xFF71C72A),
    };
