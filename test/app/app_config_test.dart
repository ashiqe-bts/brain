import 'package:brainflex/core/config/app_config.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('product settings preserve the established behavior', () {
      expect(AppSettings.workoutGameCount, 5);
      expect(AppSettings.baselineSessionCount, 3);
      expect(AppSettings.trendWindowSize, 3);
      expect(AppSettings.maximumDisplayNameCharacters, 30);
      expect(AppSettings.maximumOverviewGames, 5);
      expect(AppSettings.maximumChartResults, 30);
      expect(AppSettings.maximumRecentSessions, 20);
      expect(AppSettings.minimumDifficulty, 1);
      expect(AppSettings.maximumDifficulty, 10);
    });

    test('settings maintain valid ranges', () {
      expect(
        AppSettings.workoutGameCount,
        inInclusiveRange(1, activeGames.length),
      );
      expect(AppSettings.baselineSessionCount, greaterThanOrEqualTo(1));
      expect(
        AppSettings.maximumDifficulty,
        greaterThan(AppSettings.minimumDifficulty),
      );
      expect(AppSettings.maximumChartResults, greaterThanOrEqualTo(3));
    });
  });

  group('GameContent', () {
    test('covers every active and archived game presentation', () {
      expect(
        gameContent.keys.toSet(),
        GameType.values.map((game) => game.name).toSet(),
      );
      for (final game in GameType.values) {
        final content = gameContent[game.name]!;
        expect(content.title, isNotEmpty, reason: game.name);
        expect(content.domain, isNotEmpty, reason: game.name);
        expect(content.semanticLabel, isNotEmpty, reason: game.name);
      }
    });

    test('covers every game mode label', () {
      expect(
        AppText.gameModeLabels.keys.toSet(),
        GameMode.values.map((mode) => mode.name).toSet(),
      );
      expect(AppText.gameModeLabels.values, everyElement(isNotEmpty));
    });
  });

  test('dynamic copy handles singular and plural values', () {
    expect(AppText.remainingRounds(1), '1 more compatible game round');
    expect(AppText.remainingRounds(2), '2 more compatible game rounds');
    expect(AppText.falseStarts(1), '1 false start');
    expect(AppText.falseStarts(2), '2 false starts');
  });
}
