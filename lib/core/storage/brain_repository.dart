import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/brain_models.dart';
import '../sync/cloud_progress_store.dart';
import '../sync/progress_merge.dart';
import 'app_database.dart';

class BrainRepository {
  BrainRepository(this.db, {this.profileId = 'local', this.cloud})
    : syncStatus = ValueNotifier(
        cloud == null ? ProgressSyncStatus.disabled : ProgressSyncStatus.synced,
      );

  final AppDatabase db;
  final String profileId;
  final CloudProgressStore? cloud;
  final ValueNotifier<ProgressSyncStatus> syncStatus;
  bool _hasPendingWrites = false;

  Future<BrainState> load() async {
    await _migrateLegacyProfile();
    final row = await (db.select(
      db.profileSnapshots,
    )..where((table) => table.ownerId.equals(profileId))).getSingleOrNull();
    BrainState local;
    try {
      local = row == null ? BrainState() : BrainState.decode(row.value);
    } catch (_) {
      local = BrainState();
    }
    try {
      final sessions = await loadSessions(limit: 500);
      local.history = [
        ...local.history.where((result) => result.isLegacy),
        ...sessions,
      ];
    } catch (_) {
      // Keep the snapshot when indexed history is temporarily unavailable.
    }

    if (cloud == null) return local;
    syncStatus.value = ProgressSyncStatus.syncing;
    try {
      final remote = await cloud!.load();
      if (remote == null) {
        await cloud!.saveAll(local);
        syncStatus.value = ProgressSyncStatus.synced;
        return local;
      }
      final merged = mergeProgress(local: local, cloud: remote);
      await _saveLocal(merged);
      await cloud!.saveAll(merged);
      syncStatus.value = ProgressSyncStatus.synced;
      return merged;
    } catch (_) {
      _markPending();
      return local;
    }
  }

  Future<void> save(BrainState state) async {
    await db
        .into(db.appSnapshots)
        .insert(
          AppSnapshotsCompanion.insert(
            key: 'state_v1_backup',
            value: state.encode(),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _saveLocal(state);
    try {
      if (_hasPendingWrites) {
        await cloud?.saveAll(state);
      } else {
        await cloud?.saveState(state);
      }
      _markSynced();
    } catch (_) {
      _markPending();
    }
  }

  Future<void> importState(BrainState state) async {
    await _saveLocal(state);
    for (final result in state.history.where((item) => !item.isLegacy)) {
      await saveGame(result);
    }
    for (final summary in state.daily) {
      await saveDaily(summary);
    }
    try {
      await cloud?.saveAll(state);
      _markSynced();
    } catch (_) {
      _markPending();
    }
  }

  Future<void> _saveLocal(BrainState state) => db
      .into(db.profileSnapshots)
      .insertOnConflictUpdate(
        ProfileSnapshotsCompanion.insert(
          ownerId: profileId,
          value: state.encode(),
          updatedAt: DateTime.now(),
        ),
      );

  Future<int> saveGame(GameResult result) async {
    final completedAt = result.completedAt ?? DateTime.now();
    final stored = result.copyWith(completedAt: completedAt, isLegacy: false);
    final recordId = stored.id ?? 'local-${completedAt.microsecondsSinceEpoch}';
    final inserted = await db
        .into(db.profileGameRecords)
        .insertOnConflictUpdate(
          ProfileGameRecordsCompanion.insert(
            recordId: recordId,
            ownerId: profileId,
            gameType: stored.type.name,
            playedAtMs: completedAt.millisecondsSinceEpoch,
            payload: jsonEncode(stored.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
    final alreadyPending = _hasPendingWrites;
    try {
      await cloud?.saveGame(stored);
      if (!alreadyPending) _markSynced();
    } catch (_) {
      _markPending();
    }
    return inserted;
  }

  Future<List<GameResult>> loadSessions({
    int limit = 100,
    GameType? type,
    DateTime? since,
  }) async {
    final query = db.select(db.profileGameRecords)
      ..where((table) => table.ownerId.equals(profileId))
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
        id: decoded.id ?? row.recordId,
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

  Future<void> saveDaily(DailySummary result) async {
    await db
        .into(db.profileDailyRecords)
        .insertOnConflictUpdate(
          ProfileDailyRecordsCompanion.insert(
            ownerId: profileId,
            localDate: result.date,
            payload: jsonEncode(result.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
    final alreadyPending = _hasPendingWrites;
    try {
      await cloud?.saveDaily(result);
      if (!alreadyPending) _markSynced();
    } catch (_) {
      _markPending();
    }
  }

  Future<void> _migrateLegacyProfile() async {
    final current = await (db.select(
      db.profileSnapshots,
    )..where((table) => table.ownerId.equals(profileId))).getSingleOrNull();
    if (current != null) return;
    final migrated =
        await (db.select(db.appSnapshots)
              ..where((table) => table.key.equals('profiles_migrated')))
            .getSingleOrNull();
    if (migrated != null) return;
    final legacy = await (db.select(
      db.appSnapshots,
    )..where((table) => table.key.equals('state'))).getSingleOrNull();
    if (legacy == null) return;
    await db
        .into(db.appSnapshots)
        .insert(
          AppSnapshotsCompanion.insert(
            key: 'state_v1_backup',
            value: legacy.value,
            updatedAt: legacy.updatedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await db
        .into(db.profileSnapshots)
        .insert(
          ProfileSnapshotsCompanion.insert(
            ownerId: profileId,
            value: legacy.value,
            updatedAt: legacy.updatedAt,
          ),
        );
    final games = await db.select(db.storedGameRecords).get();
    for (final row in games) {
      final decoded = GameResult.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
      ).copyWith(id: 'legacy-${row.id}');
      await db
          .into(db.profileGameRecords)
          .insertOnConflictUpdate(
            ProfileGameRecordsCompanion.insert(
              recordId: decoded.id!,
              ownerId: profileId,
              gameType: decoded.type.name,
              playedAtMs: row.playedAtMs,
              payload: jsonEncode(decoded.toJson()),
              updatedAt: legacy.updatedAt,
            ),
          );
    }
    await db
        .into(db.appSnapshots)
        .insertOnConflictUpdate(
          AppSnapshotsCompanion.insert(
            key: 'profiles_migrated',
            value: profileId,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteLocalData() async {
    await (db.delete(
      db.profileGameRecords,
    )..where((table) => table.ownerId.equals(profileId))).go();
    await (db.delete(
      db.profileDailyRecords,
    )..where((table) => table.ownerId.equals(profileId))).go();
    await (db.delete(
      db.profileSnapshots,
    )..where((table) => table.ownerId.equals(profileId))).go();
  }

  Future<void> close() => db.close();

  void _markPending() {
    if (cloud == null) return;
    _hasPendingWrites = true;
    syncStatus.value = ProgressSyncStatus.pending;
  }

  void _markSynced() {
    if (cloud == null) return;
    _hasPendingWrites = false;
    syncStatus.value = ProgressSyncStatus.synced;
  }
}

enum ProgressSyncStatus { disabled, syncing, synced, pending }
