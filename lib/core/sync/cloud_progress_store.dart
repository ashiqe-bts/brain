import '../models/brain_models.dart';

abstract interface class CloudProgressStore {
  Future<BrainState?> load();
  Future<void> saveState(BrainState state);
  Future<void> saveGame(GameResult result);
  Future<void> saveDaily(DailySummary summary);
  Future<void> saveAll(BrainState state);
}
