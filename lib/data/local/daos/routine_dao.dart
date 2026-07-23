import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/routine_items_table.dart';
import '../tables/routines_table.dart';
part 'routine_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineItems])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);
  Future<void> insertRoutine(RoutinesCompanion v) => into(routines).insert(v);
  Future<List<Routine>> getRoutines() =>
      (select(routines)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
  Future<Routine?> getRoutine(String id) => (select(
    routines,
  )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  Future<void> updateRoutine(RoutinesCompanion v) =>
      (update(routines)..where((t) => t.id.equals(v.id.value))).write(v);
  Future<int> nextOrder(String id) async {
    final c = routineItems.id.count();
    final r =
        await (selectOnly(routineItems)
              ..addColumns([c])
              ..where(routineItems.routineId.equals(id)))
            .getSingle();
    return r.read(c) ?? 0;
  }

  Future<void> insertItem(RoutineItemsCompanion v) =>
      into(routineItems).insert(v);
  Future<RoutineItem?> getItem(String id) =>
      (select(routineItems)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> updateItem(RoutineItemsCompanion v) =>
      (update(routineItems)..where((t) => t.id.equals(v.id.value))).write(v);
  Future<List<RoutineItem>> getItems(String id) =>
      (select(routineItems)
            ..where((t) => t.routineId.equals(id) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.order)]))
          .get();
  Future<void> deleteItems(String id, DateTime now) =>
      (update(
        routineItems,
      )..where((t) => t.routineId.equals(id) & t.deletedAt.isNull())).write(
        RoutineItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
}
