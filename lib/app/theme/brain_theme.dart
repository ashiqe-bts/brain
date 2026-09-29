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
    required this.textMuted,
    required this.focus,
    required this.warning,
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
  final Color textMuted, focus, warning;

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
    Color? textMuted,
    Color? focus,
    Color? warning,
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
    textMuted: textMuted ?? this.textMuted,
    focus: focus ?? this.focus,
    warning: warning ?? this.warning,
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
      textMuted: mix(textMuted, other.textMuted),
      focus: mix(focus, other.focus),
      warning: mix(warning, other.warning),
    );
  }
}

BrainPalette paletteFor(BrainTheme theme) => switch (theme) {
  BrainTheme.calmLight => const BrainPalette(
    background: Color(0xFFF4F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE8F0EC),
    primary: Color(0xFF126E68),
    secondary: Color(0xFF315C83),
    reward: Color(0xFFE9A23B),
    success: Color(0xFF2E7D5A),
    danger: Color(0xFFB64A4A),
    text: Color(0xFF172B2A),
    outline: Color(0xFFB7C9C4),
    shadow: Color(0xFF0B2824),
    highlight: Color(0xFFFFFFFF),
    frame: Color(0xFFD5E1DD),
    hud: Color(0xFFEDF3F0),
    textMuted: Color(0xFF536966),
    focus: Color(0xFF315C83),
    warning: Color(0xFF9A650D),
  ),
  BrainTheme.calmDark => const BrainPalette(
    background: Color(0xFF0F1B1C),
    surface: Color(0xFF172728),
    surfaceHigh: Color(0xFF213536),
    primary: Color(0xFF6ED6CA),
    secondary: Color(0xFF8EB8E0),
    reward: Color(0xFFF3BB62),
    success: Color(0xFF78CCA7),
    danger: Color(0xFFFFA3A3),
    text: Color(0xFFF2F7F5),
    outline: Color(0xFF6F8884),
    shadow: Color(0xFF000000),
    highlight: Color(0xFFFFFFFF),
    frame: Color(0xFF334A49),
    hud: Color(0xFF1B2F30),
    textMuted: Color(0xFFB5C8C4),
    focus: Color(0xFFF3BB62),
    warning: Color(0xFFF3BB62),
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
    textMuted: Color(0xFFE4E4E4),
    focus: Color(0xFFFFFF00),
    warning: Color(0xFFFFD000),
  ),
};

ThemeData buildBrainTheme(BrainTheme value) {
  final p = paletteFor(value);
  final light = value == BrainTheme.calmLight;
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
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: p.text,
      ),
    ),
    textTheme: baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 52),
        backgroundColor: p.primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 50),
        foregroundColor: p.text,
        side: BorderSide(color: p.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
        borderSide: BorderSide(color: p.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.focus, width: 2),
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
      side: BorderSide(color: p.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: .14),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.primary
              : p.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? p.primary
              : p.textMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: .14),
      selectedIconTheme: IconThemeData(color: p.primary),
      unselectedIconTheme: IconThemeData(color: p.textMuted),
      selectedLabelTextStyle: TextStyle(
        color: p.primary,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(color: p.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.hud,
      contentTextStyle: TextStyle(color: contrastColorFor(p.hud, p)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.outline),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.secondary,
      linearTrackColor: p.hud,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.outline),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: p.outline),
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
  const dark = Color(0xFF102321);
  const light = Colors.white;
  return contrastRatio(background, dark) >= contrastRatio(background, light)
      ? dark
      : light;
}

double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return (l1 > l2 ? l1 + .05 : l2 + .05) / (l1 > l2 ? l2 + .05 : l1 + .05);
}

Color _gameAccent(GameType type, {required bool light}) =>
    switch ((type, light)) {
      (GameType.colorClash, true) => const Color(0xFFD52E4B),
      (GameType.mathBlitz, true) => const Color(0xFF1479B8),
      (GameType.memoryTiles, true) => const Color(0xFF8430C2),
      (GameType.reflexTap, true) => const Color(0xFFC86400),
      (GameType.visualSearch, true) => const Color(0xFF4B8F16),
      (GameType.signalStop, true) => const Color(0xFFB3261E),
      (GameType.peripheralFocus, true) => const Color(0xFF006B5F),
      (GameType.nBackNavigator, true) => const Color(0xFF6B4FA1),
      (GameType.ruleSwitch, true) => const Color(0xFF7A4D00),
      (GameType.arrowGuard, true) => const Color(0xFF00639A),
      (GameType.pairLink, true) => const Color(0xFF8C3B68),
      (GameType.symbolSprint, true) => const Color(0xFF4E6355),
      (GameType.objectTracker, true) => const Color(0xFF765B00),
      (GameType.towerPlanner, true) => const Color(0xFF5B5F97),
      (GameType.dualTaskDash, true) => const Color(0xFF8A3F00),
      (GameType.logicSeries, true) => const Color(0xFF375A7F),
      (GameType.spatialRotation, true) => const Color(0xFF006874),
      (GameType.colorClash, false) => const Color(0xFFFF4963),
      (GameType.mathBlitz, false) => const Color(0xFF38B9FF),
      (GameType.memoryTiles, false) => const Color(0xFFB638F3),
      (GameType.reflexTap, false) => const Color(0xFFFF961A),
      (GameType.visualSearch, false) => const Color(0xFF71C72A),
      (GameType.signalStop, false) => const Color(0xFFFF6F61),
      (GameType.peripheralFocus, false) => const Color(0xFF4FD8C7),
      (GameType.nBackNavigator, false) => const Color(0xFFC6A7FF),
      (GameType.ruleSwitch, false) => const Color(0xFFFFB95C),
      (GameType.arrowGuard, false) => const Color(0xFF72C7FF),
      (GameType.pairLink, false) => const Color(0xFFFF9CCC),
      (GameType.symbolSprint, false) => const Color(0xFF9DD6B0),
      (GameType.objectTracker, false) => const Color(0xFFFFD35A),
      (GameType.towerPlanner, false) => const Color(0xFFBFC3FF),
      (GameType.dualTaskDash, false) => const Color(0xFFFFA45C),
      (GameType.logicSeries, false) => const Color(0xFF9CCBFF),
      (GameType.spatialRotation, false) => const Color(0xFF72D7E5),
    };
