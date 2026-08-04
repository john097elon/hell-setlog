import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/usecases/aggregate_stats.dart';
import '../../domain/usecases/calculate_one_rep_max.dart';
import '../local/app_database.dart' as database;
import 'workout_set_mapper.dart';
import '../local/daos/stats_dao.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._dao);

  final StatsDao _dao;
  static const Uuid _uuid = Uuid();

  @override
  Future<Result<Map<DateTime, double>, Failure>> weeklyVolume({
    int days = 7,
  }) async {
    try {
      final sessions = await _dao.sessionsSince(_cutoff(days));
      final sets = await _dao.setsForSessions(
        sessions.map((session) => session.id),
      );
      return Ok(
        dailyVolume(
          sessions.map(_sessionFromData),
          sets.map(workoutSetFromRow),
          days: days,
        ),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Map<MuscleGroup, double>, Failure>> bodyPartSplit({
    int days = 30,
  }) async {
    try {
      final sessions = await _dao.sessionsSince(_cutoff(days));
      final sets = await _dao.setsForSessions(
        sessions.map((session) => session.id),
      );
      final exercises = await _dao.exercisesForIds(
        sets.map((set) => set.exerciseId),
      );
      return Ok(
        bodyPartVolume(sets.map(workoutSetFromRow), {
          for (final exercise in exercises)
            exercise.id: MuscleGroup.values[exercise.muscleGroup],
        }),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<PersonalRecord>, Failure>> personalRecords(
    String exerciseId,
  ) async {
    try {
      return Ok(
        (await _dao.recordsForExercise(
          exerciseId,
        )).map(_recordFromData).toList(),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<PersonalRecord>, Failure>> updateRecordsForSession(
    String sessionId,
  ) async {
    try {
      final session = await _dao.sessionById(sessionId);
      if (session == null) return const Err(NotFoundFailure());
      final sets = (await _dao.setsForSession(
        sessionId,
      )).map(workoutSetFromRow).where(_isWorkingSet);
      final byExercise = <String, List<WorkoutSet>>{};
      for (final set in sets) {
        byExercise.putIfAbsent(set.exerciseId, () => []).add(set);
      }
      final created = <PersonalRecord>[];
      final exercises = await _dao.exercisesForIds(byExercise.keys);
      final disciplines = <String, Discipline>{
        for (final exercise in exercises)
          exercise.id: Discipline.values[exercise.discipline],
      };
      for (final entry in byExercise.entries) {
        final values = _recordValues(
          disciplines[entry.key] ?? Discipline.strength,
          entry.value,
        );
        if (values.isEmpty) continue;
        for (final value in values.entries) {
          final existing = await _dao.highestRecord(
            userId: session.userId,
            exerciseId: entry.key,
            type: value.key.index,
          );
          if (existing == null || value.value > existing.value) {
            final now = DateTime.now();
            final record = PersonalRecord(
              id: _uuid.v4(),
              userId: session.userId,
              exerciseId: entry.key,
              type: value.key,
              value: value.value,
              achievedAt: session.endedAt ?? session.startedAt,
              sessionId: session.id,
              updatedAt: now,
            );
            await _dao.insertRecord(_recordCompanion(record));
            created.add(record);
          }
        }
      }
      return Ok(created);
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  // 날짜 단위 집계라 자정 기준으로 잘라야 첫날 오전 기록이 빠지지 않는다.
  DateTime _cutoff(int days) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
  }

  double _max(double left, double right) => left > right ? left : right;

  /// 종목이 세울 수 있는 기록만 계산한다. 러닝에 1RM은 의미가 없다.
  Map<PrType, double> _recordValues(
    Discipline discipline,
    List<WorkoutSet> sets,
  ) {
    switch (trackingModeOf(discipline)) {
      case TrackingMode.setsReps:
        return <PrType, double>{
          PrType.oneRm: sets
              .map((set) => calculateOneRepMax(set.weight, set.reps).value)
              .reduce(_max),
          PrType.volume: sets.fold(
            0,
            (volume, set) => volume + set.weight * set.reps,
          ),
          PrType.reps: sets.map((set) => set.reps.toDouble()).reduce(_max),
        };
      case TrackingMode.distanceDuration:
        final distances = sets
            .map((set) => set.distanceMeters ?? 0)
            .where((value) => value > 0);
        final durations = sets
            .map((set) => (set.durationSeconds ?? 0).toDouble())
            .where((value) => value > 0);
        // 페이스는 낮을수록 좋아서 속도로 뒤집어 저장한다.
        final speeds = sets
            .where(
              (set) =>
                  (set.distanceMeters ?? 0) > 0 &&
                  (set.durationSeconds ?? 0) > 0,
            )
            .map((set) => set.distanceMeters! / set.durationSeconds!);
        return <PrType, double>{
          if (distances.isNotEmpty) PrType.distance: distances.reduce(_max),
          if (durations.isNotEmpty) PrType.duration: durations.reduce(_max),
          if (speeds.isNotEmpty) PrType.speed: speeds.reduce(_max),
        };
      case TrackingMode.durationIntensity:
        final durations = sets
            .map((set) => (set.durationSeconds ?? 0).toDouble())
            .where((value) => value > 0);
        return <PrType, double>{
          if (durations.isNotEmpty) PrType.duration: durations.reduce(_max),
        };
    }
  }

  bool _isWorkingSet(WorkoutSet set) =>
      set.isCompleted && !set.isWarmup && set.deletedAt == null;

  database.PersonalRecordsCompanion _recordCompanion(PersonalRecord record) =>
      database.PersonalRecordsCompanion.insert(
        id: record.id,
        userId: record.userId,
        exerciseId: record.exerciseId,
        type: record.type.index,
        value: record.value,
        achievedAt: record.achievedAt,
        sessionId: record.sessionId,
        updatedAt: record.updatedAt,
        deletedAt: Value(record.deletedAt),
        syncStatus: Value(record.syncStatus.index),
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
  PersonalRecord _recordFromData(database.PersonalRecord record) =>
      PersonalRecord(
        id: record.id,
        userId: record.userId,
        exerciseId: record.exerciseId,
        type: PrType.values[record.type],
        value: record.value,
        achievedAt: record.achievedAt,
        sessionId: record.sessionId,
        updatedAt: record.updatedAt,
        deletedAt: record.deletedAt,
        syncStatus: SyncStatus.values[record.syncStatus],
      );
}
