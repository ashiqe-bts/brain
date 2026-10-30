import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameFeedbackEvent { correct, incorrect, combo, completion, reward }

abstract interface class FeedbackAudioPort {
  Future<void> play(GameFeedbackEvent event);
  Future<void> stop();
  Future<void> dispose();
}

class AudioplayersFeedbackPort implements FeedbackAudioPort {
  AudioplayersFeedbackPort({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(GameFeedbackEvent event) async {
    final (frequency, duration, volume) = switch (event) {
      GameFeedbackEvent.correct => (660.0, 90, .22),
      GameFeedbackEvent.incorrect => (190.0, 120, .18),
      GameFeedbackEvent.combo => (880.0, 105, .22),
      GameFeedbackEvent.completion => (760.0, 240, .2),
      GameFeedbackEvent.reward => (980.0, 310, .2),
    };
    await _player.stop();
    await _player.play(
      BytesSource(_wave(frequency: frequency, durationMs: duration)),
      volume: volume,
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  Uint8List _wave({required double frequency, required int durationMs}) {
    const sampleRate = 16000;
    final samples = sampleRate * durationMs ~/ 1000;
    final bytes = ByteData(44 + samples * 2);
    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    bytes.setUint32(4, 36 + samples * 2, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    bytes
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    text(36, 'data');
    bytes.setUint32(40, samples * 2, Endian.little);
    for (var index = 0; index < samples; index++) {
      final fade = 1 - index / samples;
      final sample =
          math.sin(2 * math.pi * frequency * index / sampleRate) * fade * 9000;
      bytes.setInt16(44 + index * 2, sample.round(), Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

typedef HapticEmitter = Future<void> Function(bool warning);

class GameFeedbackService {
  GameFeedbackService({FeedbackAudioPort? audio, HapticEmitter? haptic})
    : _audio = audio ?? AudioplayersFeedbackPort(),
      _haptic = haptic ?? _platformHaptic;

  final FeedbackAudioPort _audio;
  final HapticEmitter _haptic;

  Future<void> emit(
    GameFeedbackEvent event, {
    required bool soundEnabled,
    required bool hapticsEnabled,
  }) async {
    try {
      await Future.wait([
        if (soundEnabled) _audio.play(event),
        if (hapticsEnabled) _haptic(event == GameFeedbackEvent.incorrect),
      ]);
    } on Object {
      // Platform feedback is optional and must never interrupt gameplay.
    }
  }

  Future<void> stop() => _audio.stop();
  Future<void> dispose() => _audio.dispose();

  static Future<void> _platformHaptic(bool warning) =>
      warning ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
}
