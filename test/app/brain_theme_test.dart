import 'package:brainflex/app/theme/brain_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calm themes expose the approved brand colors', () {
    expect(
      paletteFor(BrainTheme.calmLight).background,
      const Color(0xFFF4F7F5),
    );
    expect(paletteFor(BrainTheme.calmLight).primary, const Color(0xFF126E68));
    expect(paletteFor(BrainTheme.calmDark).background, const Color(0xFF0F1B1C));
    expect(paletteFor(BrainTheme.calmDark).primary, const Color(0xFF6ED6CA));
  });

  test('core text and action pairs meet WCAG AA contrast', () {
    for (final theme in BrainTheme.values) {
      final palette = paletteFor(theme);
      expect(
        contrastRatio(palette.text, palette.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(palette.text, palette.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(
          contrastColorFor(palette.primary, palette),
          palette.primary,
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
