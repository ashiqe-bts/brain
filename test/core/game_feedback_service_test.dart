import 'package:brainflex/core/services/game_feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudio implements FeedbackAudioPort {
  final events = <GameFeedbackEvent>[];
  var stops = 0;

  @override
  Future<void> play(GameFeedbackEvent event) async => events.add(event);

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

void main() {
  test('feedback respects sound and haptic settings', () async {
    final audio = _FakeAudio();
    final haptics = <bool>[];
    final feedback = GameFeedbackService(
      audio: audio,
      haptic: (warning) async => haptics.add(warning),
    );

    await feedback.emit(
      GameFeedbackEvent.correct,
      soundEnabled: false,
      hapticsEnabled: true,
    );
    await feedback.emit(
      GameFeedbackEvent.incorrect,
      soundEnabled: true,
      hapticsEnabled: false,
    );

    expect(audio.events, [GameFeedbackEvent.incorrect]);
    expect(haptics, [false]);
  });

  test('background lifecycle stops any active feedback', () async {
    final audio = _FakeAudio();
    final feedback = GameFeedbackService(audio: audio);

    await feedback.stop();

    expect(audio.stops, 1);
  });
}
