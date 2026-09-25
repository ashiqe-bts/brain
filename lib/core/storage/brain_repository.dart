import 'dart:convert';
import 'package:drift/drift.dart';
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
      await db
          .into(db.appSnapshots)
          .insert(
            AppSnapshotsCompanion.insert(
              key: 'state_v1_backup',
              value: row.value,
              updatedAt: row.updatedAt,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final state = BrainState.decode(row.value);
      final sessions = await loadSessions(limit: 500);
      final legacy = state.history.where((result) => result.isLegacy);
      state.history = [...legacy, ...sessions];
      return state;
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
  Future<int> saveGame(GameResult result) {
    final completedAt = result.completedAt ?? DateTime.now();
    final stored = result.copyWith(completedAt: completedAt, isLegacy: false);
    return db
        .into(db.storedGameRecords)
        .insert(
          StoredGameRecordsCompanion.insert(
            gameType: stored.type.name,
            mode: stored.mode.name,
            score: stored.score,
            accuracy: stored.accuracy,
            playedAtMs: completedAt.millisecondsSinceEpoch,
            payload: jsonEncode(stored.toJson()),
          ),
        );
  }

  Future<List<GameResult>> loadSessions({
    int limit = 100,
    GameType? type,
    DateTime? since,
  }) async {
    final query = db.select(db.storedGameRecords)
      ..orderBy([(table) => OrderingTerm.desc(table.playedAtMs)])
      ..limit(limit);
    if (type != null) {
      query.where(
        (table) => table.gameType.isIn([
          type.name,
          if (type == GameType.visualSearch) 'oddOneOut',
        ]),
      );
    }
    if (since != null) {
      query.where(
        (table) =>
            table.playedAtMs.isBiggerOrEqualValue(since.millisecondsSinceEpoch),
      );
    }
    final rows = await query.get();
    return rows.map((row) {
      final decoded = GameResult.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
      );
      return decoded.copyWith(
        id: row.id.toString(),
        completedAt: DateTime.fromMillisecondsSinceEpoch(
          row.playedAtMs,
          isUtc: true,
        ),
        isLegacy: false,
      );
    }).toList();
  }

  Future<bool> hasMigrationBackup() async {
    final row = await (db.select(
      db.appSnapshots,
    )..where((table) => table.key.equals('state_v1_backup'))).getSingleOrNull();
    return row != null;
  }

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
