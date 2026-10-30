import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/brain_models.dart';
import 'cloud_progress_store.dart';

class FirebaseProgressStore implements CloudProgressStore {
  FirebaseProgressStore(this.uid, {FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get _user =>
      firestore.collection('users').doc(uid);

  @override
  Future<BrainState?> load() async {
    final stateDoc = await _user.collection('state').doc('current').get();
    if (!stateDoc.exists) return null;
    final stateMap = Map<String, dynamic>.from(stateDoc.data()!)
      ..remove('updatedAt')
      ..remove('revision');
    final state = BrainState.decode(jsonEncode(stateMap));
    final sessions = await _user
        .collection('sessions')
        .orderBy('completedAt', descending: true)
        .limit(500)
        .get();
    state.history = sessions.docs.map((doc) {
      final map = Map<String, dynamic>.from(doc.data())..remove('updatedAt');
      return GameResult.fromJson(map).copyWith(id: doc.id, isLegacy: false);
    }).toList();
    final daily = await _user.collection('daily').limit(500).get();
    state.daily = daily.docs.map((doc) {
      final map = Map<String, dynamic>.from(doc.data())..remove('updatedAt');
      return DailySummary.fromJson(map);
    }).toList();
    return state;
  }

  @override
  Future<void> saveState(BrainState state) async {
    final existingProfile = await _user.get();
    final authUser = FirebaseAuth.instance.currentUser;
    final pendingVerification =
        authUser?.email != null && !(authUser?.emailVerified ?? false);
    await _user.set({
      'schemaVersion': 1,
      'displayName': state.displayName,
      'accountStatus': pendingVerification ? 'pendingVerification' : 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existingProfile.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _user.collection('state').doc('current').set({
      ..._cloudState(state),
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveGame(GameResult result) async {
    final id = result.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Stable result ID required');
    }
    await _user.collection('sessions').doc(id).set({
      ...result.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveDaily(DailySummary summary) => _user
      .collection('daily')
      .doc(summary.date)
      .set({...summary.toJson(), 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> saveAll(BrainState state) async {
    await saveState(state);
    for (final result in state.history.where((item) => !item.isLegacy)) {
      await saveGame(result);
    }
    for (final summary in state.daily) {
      await saveDaily(summary);
    }
  }
}

Map<String, dynamic> _cloudState(BrainState state) => {
  'revision': DateTime.now().microsecondsSinceEpoch,
  'onboarded': state.onboarded,
  'displayName': state.displayName,
  'xp': state.xp,
  'level': state.level,
  'currentStreak': state.currentStreak,
  'longestStreak': state.longestStreak,
  'lastCompletedDate': state.lastCompletedDate,
  'workouts': state.workouts,
  'difficulties': state.difficulties,
  'missions': state.missions.map((item) => item.toJson()).toList(),
  'achievements': state.achievements.toList(),
  'completedTutorials': state.completedTutorials.toList(),
  'draft': state.draft?.toJson(),
  'lastMissionDate': state.lastMissionDate,
};
