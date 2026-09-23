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
  @override
  int get schemaVersion => 1;
}
