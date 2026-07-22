import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_sessions_table.dart';
import '../tables/workout_sets_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, WorkoutSets])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<void> insertSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<WorkoutSession?> getActiveSession() =>
      (select(workoutSessions)
            ..where(
              (table) => table.endedAt.isNull() & table.deletedAt.isNull(),
            )
            ..orderBy([(table) => OrderingTerm.desc(table.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<WorkoutSession?> getSessionById(String id) => (select(
    workoutSessions,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<void> updateSession(WorkoutSessionsCompanion session) => (update(
    workoutSessions,
  )..where((table) => table.id.equals(session.id.value))).write(session);

  Future<int> nextSetIndex(String sessionId, String exerciseId) async {
    final count = workoutSets.id.count();
    final row =
        await (selectOnly(workoutSets)
              ..addColumns([count])
              ..where(
                workoutSets.sessionId.equals(sessionId) &
                    workoutSets.exerciseId.equals(exerciseId),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insertSet(WorkoutSetsCompanion set) =>
      into(workoutSets).insert(set);

  Future<WorkoutSet?> getSetById(String id) => (select(
    workoutSets,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<void> updateSet(WorkoutSetsCompanion set) => (update(
    workoutSets,
  )..where((table) => table.id.equals(set.id.value))).write(set);

  Future<List<WorkoutSet>> getSetsBySession(String sessionId) =>
      (select(workoutSets)
            ..where(
              (table) =>
                  table.sessionId.equals(sessionId) & table.deletedAt.isNull(),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.setIndex)]))
          .get();

  Stream<List<WorkoutSet>> watchSets(String sessionId) =>
      (select(workoutSets)
            ..where(
              (table) =>
                  table.sessionId.equals(sessionId) & table.deletedAt.isNull(),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.setIndex)]))
          .watch();
}
