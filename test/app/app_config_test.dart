import 'package:brainflex/core/config/app_config.dart';
import 'package:brainflex/core/models/brain_models.dart';
import 'package:brainflex/core/training/game_catalog.dart';
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
      expect(AppSettings.gameCountdownSeconds, 3);
      expect(AppSettings.defaultTimedSessionSeconds, 30);
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
      expect(
        AppSettings.minimumTrendSessions,
        greaterThanOrEqualTo(AppSettings.trendWindowSize * 2),
      );
      expect(
        AppSettings.maximumRecentSessions,
        lessThanOrEqualTo(AppSettings.maximumChartResults),
      );
      expect(AppSettings.defaultReminderHour, inInclusiveRange(0, 23));
      expect(AppSettings.defaultReminderMinute, inInclusiveRange(0, 59));
    });

    test('display-name validation follows the configured limit', () {
      final valid = 'a' * AppSettings.maximumDisplayNameCharacters;
      final invalid = 'a' * (AppSettings.maximumDisplayNameCharacters + 1);
      expect(displayNameError(valid), isNull);
      expect(displayNameError(invalid), 'Use 30 characters or fewer');
      expect(displayNameError('   '), 'Enter your name');
    });
  });

  group('GameContent', () {
    test('covers every active and archived game presentation', () {
      expect(gameContent.keys.toSet(), GameType.values.toSet());
      for (final game in GameType.values) {
        final content = gameContent[game]!;
        expect(content.title, isNotEmpty, reason: game.name);
        expect(content.domain, isNotEmpty, reason: game.name);
        expect(content.semanticLabel, isNotEmpty, reason: game.name);
        expect(content.instructions, isNotEmpty, reason: game.name);
        expect(content.description, isNotEmpty, reason: game.name);
        expect(content.evidence.summary, isNotEmpty, reason: game.name);
        expect(content.evidence.population, isNotEmpty, reason: game.name);
        expect(content.evidence.limitation, isNotEmpty, reason: game.name);
        expect(content.evidence.reference, isNotEmpty, reason: game.name);
        expect(content.tutorial.intro, isNotEmpty, reason: game.name);
        if (game.isActive) {
          expect(content.tutorial.steps, isNotEmpty, reason: game.name);
        }
        for (final step in content.tutorial.steps) {
          expect(step.title, isNotEmpty, reason: game.name);
          expect(step.instruction, isNotEmpty, reason: game.name);
          expect(step.successMessage, isNotEmpty, reason: game.name);
          expect(step.retryMessage, isNotEmpty, reason: game.name);
        }
        for (final metric in gameMetricDefinitions(game)) {
          expect(
            metric.label,
            isNotEmpty,
            reason: '${game.name}:${metric.key}',
          );
        }
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
