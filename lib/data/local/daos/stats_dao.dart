import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/personal_records_table.dart';
import '../tables/workout_sessions_table.dart';
import '../tables/workout_sets_table.dart';

part 'stats_dao.g.dart';

@DriftAccessor(
  tables: [Exercises, WorkoutSessions, WorkoutSets, PersonalRecords],
)
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  Future<List<WorkoutSession>> sessionsSince(DateTime since) =>
      (select(workoutSessions)..where(
            (session) =>
                session.deletedAt.isNull() &
                session.startedAt.isBiggerOrEqualValue(since),
          ))
          .get();

  Future<WorkoutSession?> sessionById(String sessionId) =>
      (select(workoutSessions)..where(
            (session) =>
                session.id.equals(sessionId) & session.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  Future<List<WorkoutSet>> setsForSessions(Iterable<String> sessionIds) {
    final ids = sessionIds.toList();
    if (ids.isEmpty) return Future.value(const []);
    return (select(workoutSets)..where((set) => set.sessionId.isIn(ids))).get();
  }

  Future<List<WorkoutSet>> setsForSession(String sessionId) => (select(
    workoutSets,
  )..where((set) => set.sessionId.equals(sessionId))).get();

  Future<List<WorkoutSet>> allSets() => select(workoutSets).get();

  Future<List<Exercise>> exercisesForIds(Iterable<String> exerciseIds) {
    final ids = exerciseIds.toList();
    if (ids.isEmpty) return Future.value(const []);
    return (select(
      exercises,
    )..where((exercise) => exercise.id.isIn(ids))).get();
  }

  Future<List<PersonalRecord>> recordsForExercise(String exerciseId) =>
      (select(personalRecords)..where(
            (record) =>
                record.exerciseId.equals(exerciseId) &
                record.deletedAt.isNull(),
          ))
          .get();

  Future<PersonalRecord?> highestRecord({
    required String userId,
    required String exerciseId,
    required int type,
  }) =>
      (select(personalRecords)
            ..where(
              (record) =>
                  record.userId.equals(userId) &
                  record.exerciseId.equals(exerciseId) &
                  record.type.equals(type) &
                  record.deletedAt.isNull(),
            )
            ..orderBy([(record) => OrderingTerm.desc(record.value)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> insertRecord(PersonalRecordsCompanion record) =>
      into(personalRecords).insert(record);
}
