import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/local_user.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/usecases/calculate_session_volume.dart';
import '../local/app_database.dart' as database;
import '../local/daos/workout_dao.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  WorkoutRepositoryImpl(this._dao);

  final WorkoutDao _dao;
  static const Uuid _uuid = Uuid();

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? routineId,
    String? partyId,
  }) async {
    try {
      final current = await _dao.getActiveSession();
      // 시작 버튼 연타로 활성 세션이 여러 개 만들어지던 자리. 이미 진행 중이면
      // 그 세션을 그대로 돌려준다.
      if (current != null) return Ok(_sessionFromData(current));
      final clock = DateTime.now();
      final nextSecond = current?.startedAt.add(const Duration(seconds: 1));
      final now = nextSecond != null && !clock.isAfter(nextSecond)
          ? nextSecond
          : clock;
      final session = WorkoutSession(
        id: _uuid.v4(),
        userId: kLocalUserId,
        routineId: routineId,
        partyId: partyId,
        startedAt: now,
        updatedAt: now,
      );
      await _dao.insertSession(_sessionCompanion(session));
      return Ok(session);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> getActiveSession() async {
    try {
      final session = await _dao.getActiveSession();
      return session == null
          ? const Err(NotFoundFailure())
          : Ok(_sessionFromData(session));
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> endSession(
    String sessionId, {
    String? memo,
  }) async {
    try {
      final stored = await _dao.getSessionById(sessionId);
      if (stored == null) return const Err(NotFoundFailure());
      final session = _sessionFromData(stored);
      final sets = (await _dao.getSetsBySession(sessionId)).map(_setFromData);
      final now = DateTime.now();
      final ended = session.copyWith(
        endedAt: now,
        memo: memo,
        totalVolume: calculateSessionVolume(sets),
        updatedAt: now,
      );
      await _dao.updateSession(_sessionCompanion(ended));
      return Ok(ended);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<WorkoutSet, Failure>> addSet({
    required String sessionId,
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmup = false,
    int restSeconds = 0,
  }) async {
    try {
      final now = DateTime.now();
      // 인덱스 조회와 삽입 사이에 다른 요청이 끼면 같은 setIndex가 두 번 생긴다.
      final set = await _dao.addSetInTransaction(
        sessionId: sessionId,
        exerciseId: exerciseId,
        build: (index) => _setCompanion(
          WorkoutSet(
            id: _uuid.v4(),
            sessionId: sessionId,
            exerciseId: exerciseId,
            setIndex: index,
            weight: weight,
            reps: reps,
            rpe: rpe,
            isWarmup: isWarmup,
            restSeconds: restSeconds,
            updatedAt: now,
          ),
        ),
      );
      return Ok(_setFromData(set));
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<WorkoutSet, Failure>> updateSet(WorkoutSet set) async {
    try {
      final stored = await _dao.getSetById(set.id);
      if (stored == null) return const Err(NotFoundFailure());
      final updated = set.copyWith(updatedAt: DateTime.now());
      await _dao.updateSet(_setCompanion(updated));
      return Ok(updated);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<WorkoutSet, Failure>> completeSet(
    String setId, {
    bool completed = true,
  }) async {
    try {
      final stored = await _dao.getSetById(setId);
      if (stored == null) return const Err(NotFoundFailure());
      final now = DateTime.now();
      final set = _setFromData(stored).copyWith(
        isCompleted: completed,
        completedAt: completed ? now : stored.completedAt,
        updatedAt: now,
      );
      await _dao.updateSet(_setCompanion(set));
      return Ok(set);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteSet(String setId) async {
    try {
      final stored = await _dao.getSetById(setId);
      if (stored == null) return const Err(NotFoundFailure());
      final set = _setFromData(
        stored,
      ).copyWith(deletedAt: DateTime.now(), updatedAt: DateTime.now());
      await _dao.updateSet(_setCompanion(set));
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Stream<List<WorkoutSet>> watchSets(String sessionId) =>
      _dao.watchSets(sessionId).map((sets) => sets.map(_setFromData).toList());

  database.WorkoutSessionsCompanion _sessionCompanion(WorkoutSession session) =>
      database.WorkoutSessionsCompanion.insert(
        id: session.id,
        userId: session.userId,
        routineId: Value(session.routineId),
        partyId: Value(session.partyId),
        startedAt: session.startedAt,
        endedAt: Value(session.endedAt),
        memo: Value(session.memo),
        totalVolume: Value(session.totalVolume),
        updatedAt: session.updatedAt,
        deletedAt: Value(session.deletedAt),
        syncStatus: Value(session.syncStatus.index),
      );

  database.WorkoutSetsCompanion _setCompanion(WorkoutSet set) =>
      database.WorkoutSetsCompanion.insert(
        id: set.id,
        sessionId: set.sessionId,
        exerciseId: set.exerciseId,
        setIndex: set.setIndex,
        weight: set.weight,
        reps: set.reps,
        rpe: Value(set.rpe),
        isWarmup: Value(set.isWarmup),
        isCompleted: Value(set.isCompleted),
        restSeconds: Value(set.restSeconds),
        completedAt: Value(set.completedAt),
        updatedAt: set.updatedAt,
        deletedAt: Value(set.deletedAt),
        syncStatus: Value(set.syncStatus.index),
      );

  WorkoutSession _sessionFromData(database.WorkoutSession session) =>
      WorkoutSession(
        id: session.id,
        userId: session.userId,
        routineId: session.routineId,
        partyId: session.partyId,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        memo: session.memo,
        totalVolume: session.totalVolume,
        updatedAt: session.updatedAt,
        deletedAt: session.deletedAt,
        syncStatus: SyncStatus.values[session.syncStatus],
      );

  WorkoutSet _setFromData(database.WorkoutSet set) => WorkoutSet(
    id: set.id,
    sessionId: set.sessionId,
    exerciseId: set.exerciseId,
    setIndex: set.setIndex,
    weight: set.weight,
    reps: set.reps,
    rpe: set.rpe,
    isWarmup: set.isWarmup,
    isCompleted: set.isCompleted,
    restSeconds: set.restSeconds,
    completedAt: set.completedAt,
    updatedAt: set.updatedAt,
    deletedAt: set.deletedAt,
    syncStatus: SyncStatus.values[set.syncStatus],
  );
}
