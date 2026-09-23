import 'dart:convert';
import '../models/brain_models.dart';
import 'app_database.dart';

class BrainRepository {
  BrainRepository(this.db);
  final AppDatabase db;
  Future<BrainState> load() async {
    final row = await (db.select(
      db.appSnapshots,
    )..where((t) => t.key.equals('state'))).getSingleOrNull();
    if (row == null) return BrainState();
    try {
      return BrainState.decode(row.value);
    } catch (_) {
      return BrainState();
    }
  }

  Future<void> save(BrainState state) => db
      .into(db.appSnapshots)
      .insertOnConflictUpdate(
        AppSnapshotsCompanion.insert(
          key: 'state',
          value: state.encode(),
          updatedAt: DateTime.now(),
        ),
      );
  Future<void> saveGame(GameResult result) => db
      .into(db.storedGameRecords)
      .insert(
        StoredGameRecordsCompanion.insert(
          gameType: result.type.name,
          mode: result.mode.name,
          score: result.score,
          accuracy: result.accuracy,
          playedAtMs: DateTime.now().millisecondsSinceEpoch,
          payload: jsonEncode(result.toJson()),
        ),
      );
  Future<void> saveDaily(DailySummary result) => db
      .into(db.storedDailyRecords)
      .insertOnConflictUpdate(
        StoredDailyRecordsCompanion.insert(
          localDate: result.date,
          brainScore: result.brainScore,
          payload: jsonEncode(result.toJson()),
        ),
      );
  Future<void> close() => db.close();
}
