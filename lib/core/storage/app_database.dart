import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class AppSnapshots extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@TableIndex(
  name: 'game_records_type_played_at',
  columns: {#gameType, #playedAtMs},
)
class StoredGameRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameType => text()();
  TextColumn get mode => text()();
  IntColumn get score => integer()();
  RealColumn get accuracy => real()();
  IntColumn get playedAtMs => integer()();
  TextColumn get payload => text()();
}

class StoredDailyRecords extends Table {
  TextColumn get localDate => text()();
  IntColumn get brainScore => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {localDate};
}

class ProfileSnapshots extends Table {
  TextColumn get ownerId => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId};
}

@TableIndex(
  name: 'profile_game_records_owner_played_at',
  columns: {#ownerId, #playedAtMs},
)
class ProfileGameRecords extends Table {
  TextColumn get recordId => text()();
  TextColumn get ownerId => text()();
  TextColumn get gameType => text()();
  IntColumn get playedAtMs => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId, recordId};
}

class ProfileDailyRecords extends Table {
  TextColumn get ownerId => text()();
  TextColumn get localDate => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId, localDate};
}

@DriftDatabase(
  tables: [
    AppSnapshots,
    StoredGameRecords,
    StoredDailyRecords,
    ProfileSnapshots,
    ProfileGameRecords,
    ProfileDailyRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'brainflex',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS game_records_type_played_at '
          'ON stored_game_records (game_type, played_at_ms)',
        );
      }
      if (from < 3) {
        await m.createTable(profileSnapshots);
        await m.createTable(profileGameRecords);
        await m.createTable(profileDailyRecords);
      }
    },
  );
}
