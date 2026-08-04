import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/row_parse.dart';
import '../../core/supabase/supabase_init.dart';
import '../../domain/repositories/sync_repository.dart';
import '../local/app_database.dart' as local;
import '../../features/exercise_db/application/exercise_providers.dart';

/// Synchronizes the signed-in user's locally stored workout data with Supabase.
class SupabaseSyncRepository implements SyncRepository {
  const SupabaseSyncRepository(this._client, [this._database]);

  final SupabaseClient? _client;
  final local.AppDatabase? _database;

  @override
  Future<void> pullAll() async {
    final client = _client;
    final database = _database;
    final userId = client?.auth.currentUser?.id;
    if (client == null || database == null || userId == null) return;
    try {
      final exercises = await _rows(
        await client.from('exercises').select().eq('user_id', userId),
      );
      final routines = await _rows(
        await client.from('routines').select().eq('user_id', userId),
      );
      final items = await _rows(
        await client.from('routine_items').select().eq('user_id', userId),
      );
      final sessions = await _rows(
        await client.from('workout_sessions').select().eq('user_id', userId),
      );
      final sets = await _rows(
        await client.from('workout_sets').select().eq('user_id', userId),
      );
      await _pullExercises(database, exercises);
      await _pullRoutines(database, routines, userId);
      await _pullItems(database, items);
      await _pullSessions(database, sessions, userId);
      await _pullSets(database, sets);
    } on Exception {
      // Sync is best-effort; local data remains available offline.
    }
  }

  @override
  Future<void> pushAll() async {
    final client = _client;
    final database = _database;
    final userId = client?.auth.currentUser?.id;
    if (client == null || database == null || userId == null) return;
    try {
      final remoteExercises = await _byId(
        await _rows(
          await client.from('exercises').select().eq('user_id', userId),
        ),
      );
      final remoteRoutines = await _byId(
        await _rows(
          await client.from('routines').select().eq('user_id', userId),
        ),
      );
      final remoteItems = await _byId(
        await _rows(
          await client.from('routine_items').select().eq('user_id', userId),
        ),
      );
      final remoteSessions = await _byId(
        await _rows(
          await client.from('workout_sessions').select().eq('user_id', userId),
        ),
      );
      final remoteSets = await _byId(
        await _rows(
          await client.from('workout_sets').select().eq('user_id', userId),
        ),
      );
      await _pushExercises(client, database, userId, remoteExercises);
      await _pushRoutines(client, database, userId, remoteRoutines);
      await _pushItems(client, database, userId, remoteItems);
      await _pushSessions(client, database, userId, remoteSessions);
      await _pushSets(client, database, userId, remoteSets);
    } on Exception {
      // A later sync retries; never let a network failure interrupt a workout.
    }
  }

  Future<void> _pushExercises(
    SupabaseClient client,
    local.AppDatabase database,
    String userId,
    Map<String, Map<String, Object?>> remote,
  ) async {
    final values = await (database.select(
      database.exercises,
    )..where((table) => table.isCustom.equals(true))).get();
    for (final value in values) {
      if (_isNewer(value.updatedAt, remote[value.id])) {
        await client.from('exercises').upsert(_exerciseRow(value, userId));
      }
    }
  }

  Future<void> _pushRoutines(
    SupabaseClient client,
    local.AppDatabase database,
    String userId,
    Map<String, Map<String, Object?>> remote,
  ) async {
    for (final value in await database.select(database.routines).get()) {
      if (_isNewer(value.updatedAt, remote[value.id])) {
        await client.from('routines').upsert(_routineRow(value, userId));
      }
    }
  }

  Future<void> _pushItems(
    SupabaseClient client,
    local.AppDatabase database,
    String userId,
    Map<String, Map<String, Object?>> remote,
  ) async {
    for (final value in await database.select(database.routineItems).get()) {
      if (_isNewer(value.updatedAt, remote[value.id])) {
        await client.from('routine_items').upsert(_itemRow(value, userId));
      }
    }
  }

  Future<void> _pushSessions(
    SupabaseClient client,
    local.AppDatabase database,
    String userId,
    Map<String, Map<String, Object?>> remote,
  ) async {
    for (final value in await database.select(database.workoutSessions).get()) {
      if (_isNewer(value.updatedAt, remote[value.id])) {
        await client
            .from('workout_sessions')
            .upsert(_sessionRow(value, userId));
      }
    }
  }

  Future<void> _pushSets(
    SupabaseClient client,
    local.AppDatabase database,
    String userId,
    Map<String, Map<String, Object?>> remote,
  ) async {
    for (final value in await database.select(database.workoutSets).get()) {
      if (_isNewer(value.updatedAt, remote[value.id])) {
        await client.from('workout_sets').upsert(_setRow(value, userId));
      }
    }
  }

  Future<void> _pullExercises(
    local.AppDatabase database,
    List<Map<String, Object?>> rows,
  ) async {
    for (final row in rows) {
      final old = await _exercise(database, _id(row));
      if (old == null || _rowTime(row).isAfter(old.updatedAt)) {
        await database
            .into(database.exercises)
            .insertOnConflictUpdate(
              local.ExercisesCompanion.insert(
                id: _id(row),
                name: _text(row, 'name'),
                nameKo: _text(row, 'name_ko'),
                muscleGroup: _int(row, 'muscle_group'),
                equipment: _int(row, 'equipment'),
                isCustom: Value(_bool(row, 'is_custom')),
                thumbnailUrl: Value(_nullableText(row, 'thumbnail_url')),
                userId: Value(_nullableText(row, 'user_id')),
                createdAt: Value(_rowTime(row, 'created_at')),
                updatedAt: Value(_rowTime(row)),
                deletedAt: Value(_nullableTime(row, 'deleted_at')),
                syncStatus: const Value(2),
              ),
            );
      }
    }
  }

  Future<void> _pullRoutines(
    local.AppDatabase database,
    List<Map<String, Object?>> rows,
    String userId,
  ) async {
    for (final row in rows) {
      final old = await _routine(database, _id(row));
      if (old == null || _rowTime(row).isAfter(old.updatedAt)) {
        await database
            .into(database.routines)
            .insertOnConflictUpdate(
              local.RoutinesCompanion.insert(
                id: _id(row),
                name: _text(row, 'name'),
                description: Value(_nullableText(row, 'description')),
                ownerId: userId,
                isTemplate: Value(_bool(row, 'is_template')),
                createdAt: _rowTime(row, 'created_at'),
                updatedAt: _rowTime(row),
                deletedAt: Value(_nullableTime(row, 'deleted_at')),
                syncStatus: const Value(2),
              ),
            );
      }
    }
  }

  Future<void> _pullItems(
    local.AppDatabase database,
    List<Map<String, Object?>> rows,
  ) async {
    for (final row in rows) {
      final old = await _item(database, _id(row));
      if (old == null || _rowTime(row).isAfter(old.updatedAt)) {
        await database
            .into(database.routineItems)
            .insertOnConflictUpdate(
              local.RoutineItemsCompanion.insert(
                id: _id(row),
                routineId: _text(row, 'routine_id'),
                exerciseId: _text(row, 'exercise_id'),
                order: _int(row, 'item_order'),
                targetSets: _int(row, 'target_sets'),
                targetReps: _int(row, 'target_reps'),
                targetWeight: _double(row, 'target_weight'),
                updatedAt: _rowTime(row),
                deletedAt: Value(_nullableTime(row, 'deleted_at')),
                syncStatus: const Value(2),
              ),
            );
      }
    }
  }

  Future<void> _pullSessions(
    local.AppDatabase database,
    List<Map<String, Object?>> rows,
    String userId,
  ) async {
    for (final row in rows) {
      final old = await _session(database, _id(row));
      if (old == null || _rowTime(row).isAfter(old.updatedAt)) {
        await database
            .into(database.workoutSessions)
            .insertOnConflictUpdate(
              local.WorkoutSessionsCompanion.insert(
                id: _id(row),
                userId: userId,
                routineId: Value(_nullableText(row, 'routine_id')),
                partyId: Value(_nullableText(row, 'party_id')),
                startedAt: _rowTime(row, 'started_at'),
                endedAt: Value(_nullableTime(row, 'ended_at')),
                memo: Value(_nullableText(row, 'memo')),
                totalVolume: Value(_double(row, 'total_volume')),
                updatedAt: _rowTime(row),
                deletedAt: Value(_nullableTime(row, 'deleted_at')),
                syncStatus: const Value(2),
              ),
            );
      }
    }
  }

  Future<void> _pullSets(
    local.AppDatabase database,
    List<Map<String, Object?>> rows,
  ) async {
    for (final row in rows) {
      final old = await _set(database, _id(row));
      if (old == null || _rowTime(row).isAfter(old.updatedAt)) {
        await database
            .into(database.workoutSets)
            .insertOnConflictUpdate(
              local.WorkoutSetsCompanion.insert(
                id: _id(row),
                sessionId: _text(row, 'session_id'),
                exerciseId: _text(row, 'exercise_id'),
                setIndex: _int(row, 'set_index'),
                weight: _double(row, 'weight'),
                reps: _int(row, 'reps'),
                rpe: Value(_nullableDouble(row, 'rpe')),
                distanceMeters: Value(_nullableDouble(row, 'distance_meters')),
                durationSeconds: Value(rowInt(row, 'duration_seconds')),
                intensity: Value(rowInt(row, 'intensity')),
                isWarmup: Value(_bool(row, 'is_warmup')),
                isCompleted: Value(_bool(row, 'is_completed')),
                restSeconds: Value(_int(row, 'rest_seconds')),
                completedAt: Value(_nullableTime(row, 'completed_at')),
                updatedAt: _rowTime(row),
                deletedAt: Value(_nullableTime(row, 'deleted_at')),
                syncStatus: const Value(2),
              ),
            );
      }
    }
  }

  static Future<List<Map<String, Object?>>> _rows(Object rows) async =>
      (rows as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
  static Future<Map<String, Map<String, Object?>>> _byId(
    List<Map<String, Object?>> rows,
  ) async => {for (final row in rows) _id(row): row};
  static bool _isNewer(DateTime localTime, Map<String, Object?>? remote) =>
      remote == null || localTime.isAfter(_rowTime(remote));
  static String _id(Map<String, Object?> row) => _text(row, 'id');
  static String _text(Map<String, Object?> row, String key) =>
      row[key] as String;
  static String? _nullableText(Map<String, Object?> row, String key) =>
      row[key] as String?;
  static bool _bool(Map<String, Object?> row, String key) =>
      row[key] as bool? ?? false;
  static int _int(Map<String, Object?> row, String key) =>
      (row[key] as num).toInt();
  static double _double(Map<String, Object?> row, String key) =>
      (row[key] as num).toDouble();
  static double? _nullableDouble(Map<String, Object?> row, String key) =>
      rowDouble(row, key);
  static DateTime _rowTime(
    Map<String, Object?> row, [
    String key = 'updated_at',
  ]) => rowDate(row, key);
  static DateTime? _nullableTime(Map<String, Object?> row, String key) =>
      row[key] == null ? null : DateTime.parse(row[key] as String);
  static String _time(DateTime value) => value.toUtc().toIso8601String();

  static Map<String, Object?> _exerciseRow(
    local.Exercise value,
    String userId,
  ) => {
    'id': value.id,
    'user_id': userId,
    'name': value.name,
    'name_ko': value.nameKo,
    'muscle_group': value.muscleGroup,
    'equipment': value.equipment,
    'is_custom': true,
    'thumbnail_url': value.thumbnailUrl,
    'created_at': _time(value.createdAt),
    'updated_at': _time(value.updatedAt),
    'deleted_at': value.deletedAt == null ? null : _time(value.deletedAt!),
    'sync_status': value.syncStatus,
  };
  static Map<String, Object?> _routineRow(local.Routine value, String userId) =>
      {
        'id': value.id,
        'user_id': userId,
        'name': value.name,
        'description': value.description,
        'is_template': value.isTemplate,
        'created_at': _time(value.createdAt),
        'updated_at': _time(value.updatedAt),
        'deleted_at': value.deletedAt == null ? null : _time(value.deletedAt!),
        'sync_status': value.syncStatus,
      };
  static Map<String, Object?> _itemRow(
    local.RoutineItem value,
    String userId,
  ) => {
    'id': value.id,
    'user_id': userId,
    'routine_id': value.routineId,
    'exercise_id': value.exerciseId,
    'item_order': value.order,
    'target_sets': value.targetSets,
    'target_reps': value.targetReps,
    'target_weight': value.targetWeight,
    'updated_at': _time(value.updatedAt),
    'deleted_at': value.deletedAt == null ? null : _time(value.deletedAt!),
    'sync_status': value.syncStatus,
  };
  static Map<String, Object?> _sessionRow(
    local.WorkoutSession value,
    String userId,
  ) => {
    'id': value.id,
    'user_id': userId,
    'routine_id': value.routineId,
    'party_id': value.partyId,
    'started_at': _time(value.startedAt),
    'ended_at': value.endedAt == null ? null : _time(value.endedAt!),
    'memo': value.memo,
    'total_volume': value.totalVolume,
    'updated_at': _time(value.updatedAt),
    'deleted_at': value.deletedAt == null ? null : _time(value.deletedAt!),
    'sync_status': value.syncStatus,
  };
  static Map<String, Object?> _setRow(local.WorkoutSet value, String userId) =>
      {
        'id': value.id,
        'user_id': userId,
        'session_id': value.sessionId,
        'exercise_id': value.exerciseId,
        'set_index': value.setIndex,
        'weight': value.weight,
        'reps': value.reps,
        'rpe': value.rpe,
        'distance_meters': value.distanceMeters,
        'duration_seconds': value.durationSeconds,
        'intensity': value.intensity,
        'is_warmup': value.isWarmup,
        'is_completed': value.isCompleted,
        'rest_seconds': value.restSeconds,
        'completed_at': value.completedAt == null
            ? null
            : _time(value.completedAt!),
        'updated_at': _time(value.updatedAt),
        'deleted_at': value.deletedAt == null ? null : _time(value.deletedAt!),
        'sync_status': value.syncStatus,
      };
  static Future<local.Exercise?> _exercise(local.AppDatabase db, String id) =>
      (db.select(
        db.exercises,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
  static Future<local.Routine?> _routine(local.AppDatabase db, String id) =>
      (db.select(
        db.routines,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
  static Future<local.RoutineItem?> _item(local.AppDatabase db, String id) =>
      (db.select(
        db.routineItems,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
  static Future<local.WorkoutSession?> _session(
    local.AppDatabase db,
    String id,
  ) => (db.select(
    db.workoutSessions,
  )..where((table) => table.id.equals(id))).getSingleOrNull();
  static Future<local.WorkoutSet?> _set(local.AppDatabase db, String id) =>
      (db.select(
        db.workoutSets,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
}

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SupabaseSyncRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  ),
);
