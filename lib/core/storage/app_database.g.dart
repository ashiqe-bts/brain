// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSnapshotsTable extends AppSnapshots
    with TableInfo<$AppSnapshotsTable, AppSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSnapshot(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSnapshotsTable createAlias(String alias) {
    return $AppSnapshotsTable(attachedDatabase, alias);
  }
}

class AppSnapshot extends DataClass implements Insertable<AppSnapshot> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSnapshot({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return AppSnapshotsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSnapshot(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSnapshot copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSnapshot(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSnapshot copyWithCompanion(AppSnapshotsCompanion data) {
    return AppSnapshot(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshot(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSnapshot &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSnapshotsCompanion extends UpdateCompanion<AppSnapshot> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSnapshotsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSnapshotsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSnapshot> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSnapshotsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSnapshotsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshotsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredGameRecordsTable extends StoredGameRecords
    with TableInfo<$StoredGameRecordsTable, StoredGameRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredGameRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMsMeta = const VerificationMeta(
    'playedAtMs',
  );
  @override
  late final GeneratedColumn<int> playedAtMs = GeneratedColumn<int>(
    'played_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameType,
    mode,
    score,
    accuracy,
    playedAtMs,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_game_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredGameRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('played_at_ms')) {
      context.handle(
        _playedAtMsMeta,
        playedAtMs.isAcceptableOrUnknown(
          data['played_at_ms']!,
          _playedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playedAtMsMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredGameRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredGameRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      playedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_at_ms'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredGameRecordsTable createAlias(String alias) {
    return $StoredGameRecordsTable(attachedDatabase, alias);
  }
}

class StoredGameRecord extends DataClass
    implements Insertable<StoredGameRecord> {
  final int id;
  final String gameType;
  final String mode;
  final int score;
  final double accuracy;
  final int playedAtMs;
  final String payload;
  const StoredGameRecord({
    required this.id,
    required this.gameType,
    required this.mode,
    required this.score,
    required this.accuracy,
    required this.playedAtMs,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_type'] = Variable<String>(gameType);
    map['mode'] = Variable<String>(mode);
    map['score'] = Variable<int>(score);
    map['accuracy'] = Variable<double>(accuracy);
    map['played_at_ms'] = Variable<int>(playedAtMs);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredGameRecordsCompanion toCompanion(bool nullToAbsent) {
    return StoredGameRecordsCompanion(
      id: Value(id),
      gameType: Value(gameType),
      mode: Value(mode),
      score: Value(score),
      accuracy: Value(accuracy),
      playedAtMs: Value(playedAtMs),
      payload: Value(payload),
    );
  }

  factory StoredGameRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredGameRecord(
      id: serializer.fromJson<int>(json['id']),
      gameType: serializer.fromJson<String>(json['gameType']),
      mode: serializer.fromJson<String>(json['mode']),
      score: serializer.fromJson<int>(json['score']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      playedAtMs: serializer.fromJson<int>(json['playedAtMs']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameType': serializer.toJson<String>(gameType),
      'mode': serializer.toJson<String>(mode),
      'score': serializer.toJson<int>(score),
      'accuracy': serializer.toJson<double>(accuracy),
      'playedAtMs': serializer.toJson<int>(playedAtMs),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredGameRecord copyWith({
    int? id,
    String? gameType,
    String? mode,
    int? score,
    double? accuracy,
    int? playedAtMs,
    String? payload,
  }) => StoredGameRecord(
    id: id ?? this.id,
    gameType: gameType ?? this.gameType,
    mode: mode ?? this.mode,
    score: score ?? this.score,
    accuracy: accuracy ?? this.accuracy,
    playedAtMs: playedAtMs ?? this.playedAtMs,
    payload: payload ?? this.payload,
  );
  StoredGameRecord copyWithCompanion(StoredGameRecordsCompanion data) {
    return StoredGameRecord(
      id: data.id.present ? data.id.value : this.id,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      mode: data.mode.present ? data.mode.value : this.mode,
      score: data.score.present ? data.score.value : this.score,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      playedAtMs: data.playedAtMs.present
          ? data.playedAtMs.value
          : this.playedAtMs,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredGameRecord(')
          ..write('id: $id, ')
          ..write('gameType: $gameType, ')
          ..write('mode: $mode, ')
          ..write('score: $score, ')
          ..write('accuracy: $accuracy, ')
          ..write('playedAtMs: $playedAtMs, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameType, mode, score, accuracy, playedAtMs, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredGameRecord &&
          other.id == this.id &&
          other.gameType == this.gameType &&
          other.mode == this.mode &&
          other.score == this.score &&
          other.accuracy == this.accuracy &&
          other.playedAtMs == this.playedAtMs &&
          other.payload == this.payload);
}

class StoredGameRecordsCompanion extends UpdateCompanion<StoredGameRecord> {
  final Value<int> id;
  final Value<String> gameType;
  final Value<String> mode;
  final Value<int> score;
  final Value<double> accuracy;
  final Value<int> playedAtMs;
  final Value<String> payload;
  const StoredGameRecordsCompanion({
    this.id = const Value.absent(),
    this.gameType = const Value.absent(),
    this.mode = const Value.absent(),
    this.score = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.playedAtMs = const Value.absent(),
    this.payload = const Value.absent(),
  });
  StoredGameRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String gameType,
    required String mode,
    required int score,
    required double accuracy,
    required int playedAtMs,
    required String payload,
  }) : gameType = Value(gameType),
       mode = Value(mode),
       score = Value(score),
       accuracy = Value(accuracy),
       playedAtMs = Value(playedAtMs),
       payload = Value(payload);
  static Insertable<StoredGameRecord> custom({
    Expression<int>? id,
    Expression<String>? gameType,
    Expression<String>? mode,
    Expression<int>? score,
    Expression<double>? accuracy,
    Expression<int>? playedAtMs,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameType != null) 'game_type': gameType,
      if (mode != null) 'mode': mode,
      if (score != null) 'score': score,
      if (accuracy != null) 'accuracy': accuracy,
      if (playedAtMs != null) 'played_at_ms': playedAtMs,
      if (payload != null) 'payload': payload,
    });
  }

  StoredGameRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? gameType,
    Value<String>? mode,
    Value<int>? score,
    Value<double>? accuracy,
    Value<int>? playedAtMs,
    Value<String>? payload,
  }) {
    return StoredGameRecordsCompanion(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      mode: mode ?? this.mode,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      playedAtMs: playedAtMs ?? this.playedAtMs,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (playedAtMs.present) {
      map['played_at_ms'] = Variable<int>(playedAtMs.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredGameRecordsCompanion(')
          ..write('id: $id, ')
          ..write('gameType: $gameType, ')
          ..write('mode: $mode, ')
          ..write('score: $score, ')
          ..write('accuracy: $accuracy, ')
          ..write('playedAtMs: $playedAtMs, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $StoredDailyRecordsTable extends StoredDailyRecords
    with TableInfo<$StoredDailyRecordsTable, StoredDailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredDailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brainScoreMeta = const VerificationMeta(
    'brainScore',
  );
  @override
  late final GeneratedColumn<int> brainScore = GeneratedColumn<int>(
    'brain_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [localDate, brainScore, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_daily_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredDailyRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('brain_score')) {
      context.handle(
        _brainScoreMeta,
        brainScore.isAcceptableOrUnknown(data['brain_score']!, _brainScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_brainScoreMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDate};
  @override
  StoredDailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredDailyRecord(
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      brainScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brain_score'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredDailyRecordsTable createAlias(String alias) {
    return $StoredDailyRecordsTable(attachedDatabase, alias);
  }
}

class StoredDailyRecord extends DataClass
    implements Insertable<StoredDailyRecord> {
  final String localDate;
  final int brainScore;
  final String payload;
  const StoredDailyRecord({
    required this.localDate,
    required this.brainScore,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_date'] = Variable<String>(localDate);
    map['brain_score'] = Variable<int>(brainScore);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredDailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return StoredDailyRecordsCompanion(
      localDate: Value(localDate),
      brainScore: Value(brainScore),
      payload: Value(payload),
    );
  }

  factory StoredDailyRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredDailyRecord(
      localDate: serializer.fromJson<String>(json['localDate']),
      brainScore: serializer.fromJson<int>(json['brainScore']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localDate': serializer.toJson<String>(localDate),
      'brainScore': serializer.toJson<int>(brainScore),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredDailyRecord copyWith({
    String? localDate,
    int? brainScore,
    String? payload,
  }) => StoredDailyRecord(
    localDate: localDate ?? this.localDate,
    brainScore: brainScore ?? this.brainScore,
    payload: payload ?? this.payload,
  );
  StoredDailyRecord copyWithCompanion(StoredDailyRecordsCompanion data) {
    return StoredDailyRecord(
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      brainScore: data.brainScore.present
          ? data.brainScore.value
          : this.brainScore,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredDailyRecord(')
          ..write('localDate: $localDate, ')
          ..write('brainScore: $brainScore, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localDate, brainScore, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredDailyRecord &&
          other.localDate == this.localDate &&
          other.brainScore == this.brainScore &&
          other.payload == this.payload);
}

class StoredDailyRecordsCompanion extends UpdateCompanion<StoredDailyRecord> {
  final Value<String> localDate;
  final Value<int> brainScore;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredDailyRecordsCompanion({
    this.localDate = const Value.absent(),
    this.brainScore = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredDailyRecordsCompanion.insert({
    required String localDate,
    required int brainScore,
    required String payload,
    this.rowid = const Value.absent(),
  }) : localDate = Value(localDate),
       brainScore = Value(brainScore),
       payload = Value(payload);
  static Insertable<StoredDailyRecord> custom({
    Expression<String>? localDate,
    Expression<int>? brainScore,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDate != null) 'local_date': localDate,
      if (brainScore != null) 'brain_score': brainScore,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredDailyRecordsCompanion copyWith({
    Value<String>? localDate,
    Value<int>? brainScore,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredDailyRecordsCompanion(
      localDate: localDate ?? this.localDate,
      brainScore: brainScore ?? this.brainScore,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (brainScore.present) {
      map['brain_score'] = Variable<int>(brainScore.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredDailyRecordsCompanion(')
          ..write('localDate: $localDate, ')
          ..write('brainScore: $brainScore, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSnapshotsTable appSnapshots = $AppSnapshotsTable(this);
  late final $StoredGameRecordsTable storedGameRecords =
      $StoredGameRecordsTable(this);
  late final $StoredDailyRecordsTable storedDailyRecords =
      $StoredDailyRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSnapshots,
    storedGameRecords,
    storedDailyRecords,
  ];
}

typedef $$AppSnapshotsTableCreateCompanionBuilder =
    AppSnapshotsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSnapshotsTableUpdateCompanionBuilder =
    AppSnapshotsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSnapshotsTable,
          AppSnapshot,
          $$AppSnapshotsTableFilterComposer,
          $$AppSnapshotsTableOrderingComposer,
          $$AppSnapshotsTableAnnotationComposer,
          $$AppSnapshotsTableCreateCompanionBuilder,
          $$AppSnapshotsTableUpdateCompanionBuilder,
          (
            AppSnapshot,
            BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
          ),
          AppSnapshot,
          PrefetchHooks Function()
        > {
  $$AppSnapshotsTableTableManager(_$AppDatabase db, $AppSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSnapshotsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSnapshotsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSnapshotsTable,
      AppSnapshot,
      $$AppSnapshotsTableFilterComposer,
      $$AppSnapshotsTableOrderingComposer,
      $$AppSnapshotsTableAnnotationComposer,
      $$AppSnapshotsTableCreateCompanionBuilder,
      $$AppSnapshotsTableUpdateCompanionBuilder,
      (
        AppSnapshot,
        BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
      ),
      AppSnapshot,
      PrefetchHooks Function()
    >;
typedef $$StoredGameRecordsTableCreateCompanionBuilder =
    StoredGameRecordsCompanion Function({
      Value<int> id,
      required String gameType,
      required String mode,
      required int score,
      required double accuracy,
      required int playedAtMs,
      required String payload,
    });
typedef $$StoredGameRecordsTableUpdateCompanionBuilder =
    StoredGameRecordsCompanion Function({
      Value<int> id,
      Value<String> gameType,
      Value<String> mode,
      Value<int> score,
      Value<double> accuracy,
      Value<int> playedAtMs,
      Value<String> payload,
    });

class $$StoredGameRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredGameRecordsTable> {
  $$StoredGameRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedAtMs => $composableBuilder(
    column: $table.playedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredGameRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredGameRecordsTable> {
  $$StoredGameRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedAtMs => $composableBuilder(
    column: $table.playedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredGameRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredGameRecordsTable> {
  $$StoredGameRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get playedAtMs => $composableBuilder(
    column: $table.playedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$StoredGameRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredGameRecordsTable,
          StoredGameRecord,
          $$StoredGameRecordsTableFilterComposer,
          $$StoredGameRecordsTableOrderingComposer,
          $$StoredGameRecordsTableAnnotationComposer,
          $$StoredGameRecordsTableCreateCompanionBuilder,
          $$StoredGameRecordsTableUpdateCompanionBuilder,
          (
            StoredGameRecord,
            BaseReferences<
              _$AppDatabase,
              $StoredGameRecordsTable,
              StoredGameRecord
            >,
          ),
          StoredGameRecord,
          PrefetchHooks Function()
        > {
  $$StoredGameRecordsTableTableManager(
    _$AppDatabase db,
    $StoredGameRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredGameRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredGameRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredGameRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gameType = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<int> playedAtMs = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => StoredGameRecordsCompanion(
                id: id,
                gameType: gameType,
                mode: mode,
                score: score,
                accuracy: accuracy,
                playedAtMs: playedAtMs,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gameType,
                required String mode,
                required int score,
                required double accuracy,
                required int playedAtMs,
                required String payload,
              }) => StoredGameRecordsCompanion.insert(
                id: id,
                gameType: gameType,
                mode: mode,
                score: score,
                accuracy: accuracy,
                playedAtMs: playedAtMs,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredGameRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredGameRecordsTable,
      StoredGameRecord,
      $$StoredGameRecordsTableFilterComposer,
      $$StoredGameRecordsTableOrderingComposer,
      $$StoredGameRecordsTableAnnotationComposer,
      $$StoredGameRecordsTableCreateCompanionBuilder,
      $$StoredGameRecordsTableUpdateCompanionBuilder,
      (
        StoredGameRecord,
        BaseReferences<
          _$AppDatabase,
          $StoredGameRecordsTable,
          StoredGameRecord
        >,
      ),
      StoredGameRecord,
      PrefetchHooks Function()
    >;
typedef $$StoredDailyRecordsTableCreateCompanionBuilder =
    StoredDailyRecordsCompanion Function({
      required String localDate,
      required int brainScore,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredDailyRecordsTableUpdateCompanionBuilder =
    StoredDailyRecordsCompanion Function({
      Value<String> localDate,
      Value<int> brainScore,
      Value<String> payload,
      Value<int> rowid,
    });

class $$StoredDailyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredDailyRecordsTable> {
  $$StoredDailyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get brainScore => $composableBuilder(
    column: $table.brainScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredDailyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredDailyRecordsTable> {
  $$StoredDailyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get brainScore => $composableBuilder(
    column: $table.brainScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredDailyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredDailyRecordsTable> {
  $$StoredDailyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get brainScore => $composableBuilder(
    column: $table.brainScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$StoredDailyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredDailyRecordsTable,
          StoredDailyRecord,
          $$StoredDailyRecordsTableFilterComposer,
          $$StoredDailyRecordsTableOrderingComposer,
          $$StoredDailyRecordsTableAnnotationComposer,
          $$StoredDailyRecordsTableCreateCompanionBuilder,
          $$StoredDailyRecordsTableUpdateCompanionBuilder,
          (
            StoredDailyRecord,
            BaseReferences<
              _$AppDatabase,
              $StoredDailyRecordsTable,
              StoredDailyRecord
            >,
          ),
          StoredDailyRecord,
          PrefetchHooks Function()
        > {
  $$StoredDailyRecordsTableTableManager(
    _$AppDatabase db,
    $StoredDailyRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredDailyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredDailyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredDailyRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localDate = const Value.absent(),
                Value<int> brainScore = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredDailyRecordsCompanion(
                localDate: localDate,
                brainScore: brainScore,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDate,
                required int brainScore,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredDailyRecordsCompanion.insert(
                localDate: localDate,
                brainScore: brainScore,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredDailyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredDailyRecordsTable,
      StoredDailyRecord,
      $$StoredDailyRecordsTableFilterComposer,
      $$StoredDailyRecordsTableOrderingComposer,
      $$StoredDailyRecordsTableAnnotationComposer,
      $$StoredDailyRecordsTableCreateCompanionBuilder,
      $$StoredDailyRecordsTableUpdateCompanionBuilder,
      (
        StoredDailyRecord,
        BaseReferences<
          _$AppDatabase,
          $StoredDailyRecordsTable,
          StoredDailyRecord
        >,
      ),
      StoredDailyRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSnapshotsTableTableManager get appSnapshots =>
      $$AppSnapshotsTableTableManager(_db, _db.appSnapshots);
  $$StoredGameRecordsTableTableManager get storedGameRecords =>
      $$StoredGameRecordsTableTableManager(_db, _db.storedGameRecords);
  $$StoredDailyRecordsTableTableManager get storedDailyRecords =>
      $$StoredDailyRecordsTableTableManager(_db, _db.storedDailyRecords);
}
