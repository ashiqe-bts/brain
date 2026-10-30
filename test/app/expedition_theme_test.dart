import 'package:brainflex/app/theme/expedition_theme.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each expedition region has a distinct visual world', () {
    final specs = ExpeditionRegion.values.map(expeditionRegionVisual).toList();

    expect(specs.map((spec) => spec.accent).toSet(), hasLength(3));
    expect(specs.map((spec) => spec.icon).toSet(), hasLength(3));
    expect(specs.every((spec) => spec.tagline.isNotEmpty), isTrue);
  });

  test('expedition rewards contain no retired character branding', () {
    expect(
      expeditionRewards.every(
        (reward) =>
            !reward.id.toLowerCase().contains('nova') &&
            !reward.title.toLowerCase().contains('nova'),
      ),
      isTrue,
    );
  });
}
