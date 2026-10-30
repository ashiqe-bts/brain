import 'dart:math';

import '../../core/models/brain_models.dart';

sealed class ResearchVisual {
  const ResearchVisual();
}

class MemoryGridVisual extends ResearchVisual {
  const MemoryGridVisual({required this.before, required this.after});
  final Set<int> before;
  final Set<int> after;
}

class SignalVisual extends ResearchVisual {
  const SignalVisual({required this.stop});
  final bool stop;
}

class PeripheralVisual extends ResearchVisual {
  const PeripheralVisual({required this.shape, required this.direction});
  final int shape;
  final int direction;
}

class PositionVisual extends ResearchVisual {
  const PositionVisual({required this.position, required this.n});
  final int position;
  final int n;
}

class RuleVisual extends ResearchVisual {
  const RuleVisual({
    required this.shape,
    required this.color,
    required this.useShape,
  });
  final int shape;
  final int color;
  final bool useShape;
}

class ArrowVisual extends ResearchVisual {
  const ArrowVisual({required this.right, required this.congruent});
  final bool right;
  final bool congruent;
}

class PairVisual extends ResearchVisual {
  const PairVisual({required this.left, this.partner, required this.recall});
  final int left;
  final int? partner;
  final bool recall;
}

class SymbolKeyVisual extends ResearchVisual {
  const SymbolKeyVisual({required this.values, required this.target});
  final List<int> values;
  final int target;
}

class TrackingVisual extends ResearchVisual {
  const TrackingVisual({required this.targets, required this.movement});
  final List<int> targets;
  final List<int> movement;
}

class TowerVisual extends ResearchVisual {
  const TowerVisual({required this.pegs, required this.target});
  final List<List<int>> pegs;
  final int target;
}

class DualTaskVisual extends ResearchVisual {
  const DualTaskVisual({required this.value, required this.stars});
  final int value;
  final int stars;
}

class SeriesVisual extends ResearchVisual {
  const SeriesVisual({required this.values});
  final List<int> values;
}

class RotationVisual extends ResearchVisual {
  const RotationVisual({required this.same, required this.angle});
  final bool same;
  final int angle;
}

class ResearchTrial {
  const ResearchTrial({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.visual,
    this.cue = '',
    this.condition = 'standard',
    this.exposureMs = 0,
    this.span = 0,
    this.movement = const [],
    this.towerPegs = const [],
    this.towerTarget = -1,
    this.towerMoves = const [],
  });

  final String prompt;
  final String cue;
  final List<String> options;
  final int correctIndex;
  final ResearchVisual visual;
  final String condition;
  final int exposureMs;
  final int span;
  final List<int> movement;
  final List<List<int>> towerPegs;
  final int towerTarget;
  final List<TowerMove> towerMoves;
}

class TowerMove {
  const TowerMove({required this.disk, required this.from, required this.to});

  final int disk;
  final int from;
  final int to;

  String get label => 'Move disk $disk: ${from + 1} → ${to + 1}';
}

class ResearchGameEngine {
  ResearchGameEngine({
    required int seed,
    required this.type,
    required this.difficulty,
  }) : _random = Random(seed);

  final GameType type;
  final int difficulty;
  final Random _random;
  final List<int> _nBackPositions = [];
  final List<(String, String)> _learnedPairs = [];
  List<List<int>> _towerPegs = const [];
  int _towerTarget = -1;
  int _towerMoves = 0;
  int _towerMinimumMoves = 0;
  int towerSolvedTrials = 0;
  int towerExcessMoves = 0;
  int _trialIndex = 0;

  ResearchTrial nextTrial() {
    final trial = switch (type) {
      GameType.memoryTiles => _memoryTiles(),
      GameType.signalStop => _signalStop(),
      GameType.peripheralFocus => _peripheralFocus(),
      GameType.nBackNavigator => _nBack(),
      GameType.ruleSwitch => _ruleSwitch(),
      GameType.arrowGuard => _arrowGuard(),
      GameType.pairLink => _pairLink(),
      GameType.symbolSprint => _symbolSprint(),
      GameType.objectTracker => _objectTracker(),
      GameType.towerPlanner => _towerPlanner(),
      GameType.dualTaskDash => _dualTask(),
      GameType.logicSeries => _logicSeries(),
      GameType.spatialRotation => _spatialRotation(),
      _ => throw ArgumentError('${type.name} is not a research-game engine'),
    };
    _trialIndex++;
    return trial;
  }

  void acceptAnswer(ResearchTrial trial, int selected) {
    if (type != GameType.towerPlanner || trial.towerMoves.isEmpty) return;
    final move = trial.towerMoves[selected];
    if (_towerPegs[move.from].isEmpty ||
        _towerPegs[move.from].last != move.disk) {
      return;
    }
    _towerPegs[move.from].removeLast();
    _towerPegs[move.to].add(move.disk);
    _towerMoves++;
    final diskCount = _towerMinimumMoves.bitLength;
    if (_towerPegs[_towerTarget].length == diskCount) {
      towerSolvedTrials++;
      towerExcessMoves += max(0, _towerMoves - _towerMinimumMoves);
      _towerPegs = const [];
    }
  }

  ResearchTrial _memoryTiles() {
    final gridSize = difficulty >= 7 ? 16 : 9;
    final span = min(gridSize - 1, 2 + difficulty ~/ 2);
    final active = <int>{};
    while (active.length < span) {
      active.add(_random.nextInt(gridSize));
    }
    final changed = _random.nextInt(gridSize);
    final after = {...active};
    after.contains(changed) ? after.remove(changed) : after.add(changed);
    final distractors = <int>{changed};
    while (distractors.length < 4) {
      distractors.add(_random.nextInt(gridSize));
    }
    final options = distractors.toList()..shuffle(_random);
    return ResearchTrial(
      prompt: active.map((item) => '${item + 1}').join(','),
      cue: after.map((item) => '${item + 1}').join(','),
      options: options.map((item) => 'Tile ${item + 1}').toList(),
      correctIndex: options.indexOf(changed),
      visual: MemoryGridVisual(before: active, after: after),
      condition: 'change-detection',
      exposureMs: max(650, 1500 - difficulty * 70),
      span: span,
    );
  }

  ResearchTrial _signalStop() {
    final stop = _trialIndex % 4 == 3;
    return ResearchTrial(
      prompt: stop ? 'STOP' : 'GO',
      cue: stop ? 'Withhold your response' : 'Respond quickly',
      options: const ['TAP', 'WAIT'],
      correctIndex: stop ? 1 : 0,
      visual: SignalVisual(stop: stop),
      condition: stop ? 'stop' : 'go',
      exposureMs: 500 + _random.nextInt(500),
    );
  }

  ResearchTrial _peripheralFocus() {
    const shapes = ['●', '▲', '■', '◆'];
    const directions = ['TOP', 'RIGHT', 'BOTTOM', 'LEFT'];
    final shape = shapes[_random.nextInt(shapes.length)];
    final direction = directions[_random.nextInt(directions.length)];
    final correct = '$shape · $direction';
    final options = <String>{correct};
    while (options.length < 4) {
      options.add(
        '${shapes[_random.nextInt(shapes.length)]} · ${directions[_random.nextInt(directions.length)]}',
      );
    }
    final shuffled = options.toList()..shuffle(_random);
    return ResearchTrial(
      prompt: '$shape|$direction',
      cue: 'Remember the center shape and edge position',
      options: shuffled,
      correctIndex: shuffled.indexOf(correct),
      visual: PeripheralVisual(
        shape: shapes.indexOf(shape),
        direction: directions.indexOf(direction),
      ),
      condition: 'central-peripheral',
      exposureMs: max(450, 1200 - difficulty * 60),
    );
  }

  ResearchTrial _nBack() {
    final n = difficulty >= 7
        ? 3
        : difficulty >= 3
        ? 2
        : 1;
    final canMatch = _nBackPositions.length >= n;
    final shouldMatch = canMatch && _trialIndex.isEven;
    var position = _random.nextInt(9);
    if (shouldMatch) {
      position = _nBackPositions[_nBackPositions.length - n];
    } else if (canMatch &&
        position == _nBackPositions[_nBackPositions.length - n]) {
      position = (position + 1) % 9;
    }
    _nBackPositions.add(position);
    return ResearchTrial(
      prompt: 'Position ${position + 1}',
      cue: '$n-back',
      options: const ['MATCH', 'NEW'],
      correctIndex: shouldMatch ? 0 : 1,
      visual: PositionVisual(position: position, n: n),
      condition: shouldMatch ? 'match' : 'non-match',
      span: n,
    );
  }

  ResearchTrial _ruleSwitch() {
    const shapes = ['CIRCLE', 'TRIANGLE'];
    const colors = ['WARM', 'COOL'];
    final useShape = (_trialIndex ~/ 2).isEven;
    final shape = _random.nextInt(2);
    final color = _random.nextInt(2);
    return ResearchTrial(
      prompt: '${colors[color]} ${shapes[shape]}',
      cue: useShape ? 'RULE: SHAPE' : 'RULE: COLOR',
      options: useShape ? shapes : colors,
      correctIndex: useShape ? shape : color,
      visual: RuleVisual(shape: shape, color: color, useShape: useShape),
      condition: _trialIndex > 0 && _trialIndex % 2 == 0 ? 'switch' : 'repeat',
    );
  }

  ResearchTrial _arrowGuard() {
    final right = _random.nextBool();
    final congruent = _trialIndex.isEven;
    final center = right ? '→' : '←';
    final flank = congruent ? center : (right ? '←' : '→');
    return ResearchTrial(
      prompt: '$flank $flank $center $flank $flank',
      cue: 'Center arrow only',
      options: const ['LEFT', 'RIGHT'],
      correctIndex: right ? 1 : 0,
      visual: ArrowVisual(right: right, congruent: congruent),
      condition: congruent ? 'congruent' : 'incongruent',
    );
  }

  ResearchTrial _pairLink() {
    const symbols = ['★', '●', '▲', '■', '♦', '♥', '☂', '☼'];
    if (_learnedPairs.length >= 2 && _trialIndex % 3 == 2) {
      final pair = _learnedPairs[_learnedPairs.length - 2];
      final options = symbols.sublist(4)..shuffle(_random);
      return ResearchTrial(
        prompt: 'Which symbol was paired with ${pair.$1}?',
        cue: 'Delayed recall',
        options: options,
        correctIndex: options.indexOf(pair.$2),
        visual: PairVisual(left: symbols.indexOf(pair.$1), recall: true),
        condition: 'delayed',
        span: _learnedPairs.length,
      );
    }
    final left = symbols[_random.nextInt(4)];
    final partner = symbols[4 + _random.nextInt(4)];
    _learnedPairs.add((left, partner));
    final options = symbols.sublist(4)..shuffle(_random);
    return ResearchTrial(
      prompt: '$left + $partner',
      cue: 'Which symbol was paired with $left?',
      options: options,
      correctIndex: options.indexOf(partner),
      visual: PairVisual(
        left: symbols.indexOf(left),
        partner: symbols.indexOf(partner),
        recall: false,
      ),
      condition: 'immediate',
      exposureMs: max(800, 1700 - difficulty * 70),
      span: 2 + difficulty ~/ 2,
    );
  }

  ResearchTrial _symbolSprint() {
    const symbols = ['★', '●', '▲', '■'];
    final values = [1, 2, 3, 4]..shuffle(_random);
    final target = _random.nextInt(symbols.length);
    final key = List.generate(
      symbols.length,
      (index) => '${symbols[index]}=${values[index]}',
    ).join('  ');
    return ResearchTrial(
      prompt: symbols[target],
      cue: key,
      options: const ['1', '2', '3', '4'],
      correctIndex: values[target] - 1,
      visual: SymbolKeyVisual(values: values, target: target),
      condition: 'symbol-substitution',
    );
  }

  ResearchTrial _objectTracker() {
    final count = min(4, 1 + difficulty ~/ 3);
    final movement = List.generate(6, (index) => index)..shuffle(_random);
    final targets = List.generate(count, (index) => index);
    final correct = targets
        .map((index) => _slotLabel(movement[index]))
        .join('-');
    final options = <String>{correct};
    while (options.length < 4) {
      final candidate = List.generate(
        count,
        (_) => _slotLabel(_random.nextInt(6)),
      );
      options.add(candidate.join('-'));
    }
    final shuffled = options.toList()..shuffle(_random);
    return ResearchTrial(
      prompt: 'Track objects ${targets.map((index) => index + 1).join('-')}',
      cue: 'Choose their final letter positions',
      options: shuffled,
      correctIndex: shuffled.indexOf(correct),
      visual: TrackingVisual(targets: targets, movement: movement),
      condition: 'multiple-object-tracking',
      exposureMs: max(900, 1900 - difficulty * 70),
      span: count,
      movement: movement,
    );
  }

  ResearchTrial _towerPlanner() {
    if (_towerPegs.isEmpty) {
      final disks = difficulty >= 6 ? 3 : 2;
      final source = _random.nextInt(3);
      _towerTarget = (source + 1 + _random.nextInt(2)) % 3;
      _towerPegs = List.generate(3, (_) => <int>[]);
      _towerPegs[source].addAll([
        for (var disk = disks; disk >= 1; disk--) disk,
      ]);
      _towerMoves = 0;
      _towerMinimumMoves = (1 << disks) - 1;
    }
    final legalMoves = _legalTowerMoves(_towerPegs)..shuffle(_random);
    final optimal = _shortestTowerMove(_towerPegs, _towerTarget);
    return ResearchTrial(
      prompt: 'Move every disk to peg ${_towerTarget + 1}',
      cue: 'Only smaller disks may sit on larger disks',
      options: legalMoves.map((move) => move.label).toList(),
      correctIndex: legalMoves.indexWhere(
        (move) => move.from == optimal.from && move.to == optimal.to,
      ),
      visual: TowerVisual(
        pegs: _towerPegs.map(List<int>.unmodifiable).toList(),
        target: _towerTarget,
      ),
      condition: 'planning',
      span: _towerMinimumMoves.bitLength,
      towerPegs: _towerPegs.map(List<int>.unmodifiable).toList(),
      towerTarget: _towerTarget,
      towerMoves: legalMoves,
    );
  }

  List<TowerMove> _legalTowerMoves(List<List<int>> pegs) {
    final moves = <TowerMove>[];
    for (var from = 0; from < pegs.length; from++) {
      if (pegs[from].isEmpty) continue;
      final disk = pegs[from].last;
      for (var to = 0; to < pegs.length; to++) {
        if (to != from && (pegs[to].isEmpty || pegs[to].last > disk)) {
          moves.add(TowerMove(disk: disk, from: from, to: to));
        }
      }
    }
    return moves;
  }

  TowerMove _shortestTowerMove(List<List<int>> pegs, int target) {
    final diskCount = pegs.fold<int>(0, (sum, peg) => sum + peg.length);
    final start = List<int>.filled(diskCount, 0);
    for (var peg = 0; peg < pegs.length; peg++) {
      for (final disk in pegs[peg]) {
        start[disk - 1] = peg;
      }
    }
    final queue = <List<int>>[start];
    final firstMoves = <int, TowerMove?>{_towerCode(start): null};
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final state = queue[cursor];
      final stateCode = _towerCode(state);
      if (state.every((peg) => peg == target)) {
        return firstMoves[stateCode]!;
      }
      final statePegs = List.generate(3, (_) => <int>[]);
      for (var disk = diskCount; disk >= 1; disk--) {
        statePegs[state[disk - 1]].add(disk);
      }
      for (final move in _legalTowerMoves(statePegs)) {
        final next = [...state]..[move.disk - 1] = move.to;
        final code = _towerCode(next);
        if (firstMoves.containsKey(code)) continue;
        firstMoves[code] = firstMoves[stateCode] ?? move;
        queue.add(next);
      }
    }
    throw StateError('Every valid Tower state must reach its target.');
  }

  int _towerCode(List<int> state) =>
      state.fold<int>(0, (code, peg) => code * 3 + peg);

  ResearchTrial _dualTask() {
    final targetCount = 1 + _random.nextInt(4);
    final value = 2 + _random.nextInt(18);
    final even = value.isEven;
    final correct = '${even ? 'EVEN' : 'ODD'} · $targetCount';
    final options = <String>{correct};
    while (options.length < 4) {
      options.add(
        '${_random.nextBool() ? 'EVEN' : 'ODD'} · ${1 + _random.nextInt(4)}',
      );
    }
    final shuffled = options.toList()..shuffle(_random);
    return ResearchTrial(
      prompt: '$value   ${List.filled(targetCount, '★').join(' ')}',
      cue: 'Classify the number AND count the stars',
      options: shuffled,
      correctIndex: shuffled.indexOf(correct),
      visual: DualTaskVisual(value: value, stars: targetCount),
      condition: 'dual-task',
    );
  }

  ResearchTrial _logicSeries() {
    final step = 1 + _random.nextInt(3 + difficulty ~/ 3);
    final start = 1 + _random.nextInt(8);
    final values = List.generate(4, (index) => start + index * step);
    final answer = start + 4 * step;
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer - 3 + _random.nextInt(7));
    }
    final shuffled = options.toList()..shuffle(_random);
    return ResearchTrial(
      prompt: '${values.join('  →  ')}  →  ?',
      cue: 'Continue the rule',
      options: shuffled.map((value) => '$value').toList(),
      correctIndex: shuffled.indexOf(answer),
      visual: SeriesVisual(values: values),
      condition: 'inductive-reasoning',
    );
  }

  ResearchTrial _spatialRotation() {
    final same = _trialIndex.isEven;
    const rotations = ['.■■/■■.', '■./■■/.■'];
    const mirrors = ['■■./.■■', '.■/■■/■.'];
    final angle = _random.nextBool() ? 90 : 270;
    return ResearchTrial(
      prompt:
          '${rotations.first}     ${same ? rotations.last : mirrors[angle == 90 ? 1 : 0]}',
      cue: 'Can rotation alone make these match? · $angle°',
      options: const ['SAME', 'DIFFERENT'],
      correctIndex: same ? 0 : 1,
      visual: RotationVisual(same: same, angle: angle),
      condition: '${same ? 'same' : 'mirror'}-$angle',
    );
  }

  String _slotLabel(int index) => String.fromCharCode(65 + index);
}
