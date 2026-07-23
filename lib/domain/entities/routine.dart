import 'workout_set.dart';

class Routine {
  const Routine({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  Routine copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => Routine(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    ownerId: ownerId,
    isTemplate: isTemplate,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus,
  );
}
