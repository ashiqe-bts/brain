import 'package:brainflex/app/theme/game_visuals.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every active game has a distinct professional icon', () {
    final visuals = activeGames.map(gameVisualFor).toList();

    expect(visuals, hasLength(15));
    expect(
      visuals.map((visual) => visual.icon.codePoint).toSet(),
      hasLength(15),
    );
    expect(visuals.every((visual) => visual.semanticLabel.isNotEmpty), isTrue);
  });
}
