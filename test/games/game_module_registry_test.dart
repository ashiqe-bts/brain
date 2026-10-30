import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/features/games/game_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every active game has a typed module without a generic fallback', () {
    final modules = activeGames.map(gameModule).toList();

    expect(modules, hasLength(10));
    expect(modules.map((module) => module.type).toSet(), activeGames.toSet());
    expect(
      modules.every(
        (module) =>
            module.interaction != GameInteraction.genericMultipleChoice &&
            module.rulesVersion == module.type.rulesVersion &&
            module.metricKeys.isNotEmpty &&
            module.accessibilityAlternative.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('archived games are decodable but cannot launch as active modules', () {
    for (final game in archivedGames) {
      expect(() => gameModule(game), throwsUnsupportedError);
    }
  });
}
