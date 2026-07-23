import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/local_user.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_item.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/routine_repository.dart';
import '../local/app_database.dart' as db;
import '../local/daos/routine_dao.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  RoutineRepositoryImpl(this._dao);
  final RoutineDao _dao;
  static const _uuid = Uuid();
  @override
  Future<Result<Routine, Failure>> createRoutine({
    required String name,
    String? description,
  }) async => _guard(() async {
    final n = DateTime.now();
    final r = Routine(
      id: _uuid.v4(),
      name: name,
      description: description,
      ownerId: kLocalUserId,
      createdAt: n,
      updatedAt: n,
    );
    await _dao.insertRoutine(_r(r));
    return r;
  });
  @override
  Future<Result<List<Routine>, Failure>> getRoutines() async =>
      _guard(() => _dao.getRoutines().then((v) => v.map(_rf).toList()));
  @override
  Future<Result<Routine, Failure>> getRoutine(String id) async {
    try {
      final v = await _dao.getRoutine(id);
      return v == null ? const Err(NotFoundFailure()) : Ok(_rf(v));
    } on Exception catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Routine, Failure>> renameRoutine(
    String id, {
    required String name,
    String? description,
  }) async {
    final old = await getRoutine(id);
    return old.when(
      ok: (r) => _guard(() async {
        final n = r.copyWith(
          name: name,
          description: description,
          updatedAt: DateTime.now(),
        );
        await _dao.updateRoutine(_r(n));
        return n;
      }),
      err: (e) async => Err(e),
    );
  }

  @override
  Future<Result<void, Failure>> deleteRoutine(String id) async {
    try {
      final v = await _dao.getRoutine(id);
      if (v == null) return const Err(NotFoundFailure());
      final n = DateTime.now();
      await _dao.updateRoutine(
        db.RoutinesCompanion(
          id: Value(id),
          deletedAt: Value(n),
          updatedAt: Value(n),
        ),
      );
      await _dao.deleteItems(id, n);
      return const Ok(null);
    } on Exception catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<RoutineItem, Failure>> addItem({
    required String routineId,
    required String exerciseId,
    required int targetSets,
    required int targetReps,
    required double targetWeight,
  }) async => _guard(() async {
    final n = DateTime.now();
    final i = RoutineItem(
      id: _uuid.v4(),
      routineId: routineId,
      exerciseId: exerciseId,
      order: await _dao.nextOrder(routineId),
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      updatedAt: n,
    );
    await _dao.insertItem(_i(i));
    return i;
  });
  @override
  Future<Result<RoutineItem, Failure>> updateItem(RoutineItem item) async =>
      _guard(() async {
        final n = item.copyWith(updatedAt: DateTime.now());
        await _dao.updateItem(_i(n));
        return n;
      });
  @override
  Future<Result<void, Failure>> removeItem(String id) async {
    try {
      final v = await _dao.getItem(id);
      if (v == null) return const Err(NotFoundFailure());
      final n = DateTime.now();
      await _dao.updateItem(
        db.RoutineItemsCompanion(
          id: Value(id),
          deletedAt: Value(n),
          updatedAt: Value(n),
        ),
      );
      return const Ok(null);
    } on Exception catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<RoutineItem>, Failure>> getItems(String id) async =>
      _guard(() => _dao.getItems(id).then((v) => v.map(_if).toList()));
  Future<Result<T, Failure>> _guard<T>(Future<T> Function() f) async {
    try {
      return Ok(await f());
    } on Exception catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }

  db.RoutinesCompanion _r(Routine r) => db.RoutinesCompanion.insert(
    id: r.id,
    name: r.name,
    description: Value(r.description),
    ownerId: r.ownerId,
    isTemplate: Value(r.isTemplate),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: Value(r.deletedAt),
    syncStatus: Value(r.syncStatus.index),
  );
  db.RoutineItemsCompanion _i(RoutineItem i) => db.RoutineItemsCompanion.insert(
    id: i.id,
    routineId: i.routineId,
    exerciseId: i.exerciseId,
    order: i.order,
    targetSets: i.targetSets,
    targetReps: i.targetReps,
    targetWeight: i.targetWeight,
    updatedAt: i.updatedAt,
    deletedAt: Value(i.deletedAt),
    syncStatus: Value(i.syncStatus.index),
  );
  Routine _rf(db.Routine r) => Routine(
    id: r.id,
    name: r.name,
    description: r.description,
    ownerId: r.ownerId,
    isTemplate: r.isTemplate,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
    syncStatus: SyncStatus.values[r.syncStatus],
  );
  RoutineItem _if(db.RoutineItem i) => RoutineItem(
    id: i.id,
    routineId: i.routineId,
    exerciseId: i.exerciseId,
    order: i.order,
    targetSets: i.targetSets,
    targetReps: i.targetReps,
    targetWeight: i.targetWeight,
    updatedAt: i.updatedAt,
    deletedAt: i.deletedAt,
    syncStatus: SyncStatus.values[i.syncStatus],
  );
}
