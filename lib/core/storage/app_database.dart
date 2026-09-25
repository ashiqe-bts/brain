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

@DriftDatabase(tables: [AppSnapshots, StoredGameRecords, StoredDailyRecords])
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
  int get schemaVersion => 2;

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
    },
  );
}
