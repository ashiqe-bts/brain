import 'dart:math';

import 'package:equatable/equatable.dart';

class ColorTrial extends Equatable {
  const ColorTrial({required this.wordIndex, required this.colorIndex});

  final int wordIndex;
  final int colorIndex;
  bool get isCongruent => wordIndex == colorIndex;

  @override
  List<Object> get props => [wordIndex, colorIndex];
}

class MathTrial extends Equatable {
  const MathTrial({
    required this.left,
    required this.right,
    required this.operator,
    required this.actual,
    required this.shown,
  });

  final int left;
  final int right;
  final String operator;
  final int actual;
  final int shown;
  bool get isCorrect => actual == shown;
  String get expression => '$left $operator $right = $shown';

  @override
  List<Object> get props => [left, right, operator, actual, shown];
}

class VisualGlyph extends Equatable {
  const VisualGlyph({
    required this.shape,
    required this.rotation,
    required this.filled,
    required this.colorIndex,
  });

  final int shape;
  final int rotation;
  final bool filled;
  final int colorIndex;

  @override
  List<Object> get props => [shape, rotation, filled, colorIndex];
}

class VisualSearchTrial extends Equatable {
  const VisualSearchTrial({
    required this.target,
    required this.items,
    required this.targetIndex,
  });

  final VisualGlyph target;
  final List<VisualGlyph> items;
  final int targetIndex;

  @override
  List<Object> get props => [target, items, targetIndex];
}

class GameTrialFactory {
  GameTrialFactory(int seed) : _random = Random(seed);

  final Random _random;

  List<ColorTrial> colorTrials(int count) {
    final congruentCount = count ~/ 2;
    final conditions = [
      ...List<bool>.filled(congruentCount, true),
      ...List<bool>.filled(count - congruentCount, false),
    ]..shuffle(_random);
    return conditions.map((isCongruent) {
      final word = _random.nextInt(4);
      var color = word;
      if (!isCongruent) {
        color = (word + 1 + _random.nextInt(3)) % 4;
      }
      return ColorTrial(wordIndex: word, colorIndex: color);
    }).toList();
  }

  List<MathTrial> mathTrials(int difficulty, {required int count}) =>
      List.generate(count, (_) => _mathTrial(difficulty));

  MathTrial _mathTrial(int difficulty) {
    final maxValue = 8 + difficulty * 4;
    var left = 1 + _random.nextInt(maxValue);
    var right = 1 + _random.nextInt(max(2, 6 + difficulty * 2));
    final operators = difficulty < 3
        ? const ['+']
        : difficulty < 6
        ? const ['+', '−']
        : difficulty < 9
        ? const ['+', '−', '×']
        : const ['+', '−', '×', '÷'];
    final operator = operators[_random.nextInt(operators.length)];
    if (operator == '÷') {
      final quotient = 1 + _random.nextInt(12);
      left = right * quotient;
    }
    final actual = switch (operator) {
      '+' => left + right,
      '−' => left - right,
      '×' => left * right,
      _ => left ~/ right,
    };
    final correct = _random.nextBool();
    final offset = 1 + _random.nextInt(max(2, 1 + difficulty ~/ 2));
    final shown = correct
        ? actual
        : actual + (_random.nextBool() ? offset : -offset);
    return MathTrial(
      left: left,
      right: right,
      operator: operator,
      actual: actual,
      shown: shown,
    );
  }

  VisualSearchTrial visualSearch(int difficulty, {required int itemCount}) {
    final target = VisualGlyph(
      shape: _random.nextInt(4),
      rotation: _random.nextInt(4),
      filled: _random.nextBool(),
      colorIndex: _random.nextInt(4),
    );
    final items = List<VisualGlyph>.generate(
      itemCount,
      (_) => _distractor(target, difficulty),
    );
    final targetIndex = _random.nextInt(itemCount);
    items[targetIndex] = target;
    return VisualSearchTrial(
      target: target,
      items: List.unmodifiable(items),
      targetIndex: targetIndex,
    );
  }

  VisualGlyph _distractor(VisualGlyph target, int difficulty) {
    final attribute = _random.nextInt(difficulty >= 6 ? 4 : 3);
    return switch (attribute) {
      0 => VisualGlyph(
        shape: (target.shape + 1 + _random.nextInt(3)) % 4,
        rotation: target.rotation,
        filled: target.filled,
        colorIndex: target.colorIndex,
      ),
      1 => VisualGlyph(
        shape: target.shape,
        rotation: (target.rotation + 1 + _random.nextInt(3)) % 4,
        filled: target.filled,
        colorIndex: target.colorIndex,
      ),
      2 => VisualGlyph(
        shape: target.shape,
        rotation: target.rotation,
        filled: !target.filled,
        colorIndex: target.colorIndex,
      ),
      _ => VisualGlyph(
        shape: target.shape,
        rotation: target.rotation,
        filled: target.filled,
        colorIndex: (target.colorIndex + 1 + _random.nextInt(3)) % 4,
      ),
    };
  }
}

int medianMilliseconds(Iterable<int> values) {
  final sorted = values.where((value) => value >= 0).toList()..sort();
  if (sorted.isEmpty) return 0;
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return ((sorted[middle - 1] + sorted[middle]) / 2).round();
}
