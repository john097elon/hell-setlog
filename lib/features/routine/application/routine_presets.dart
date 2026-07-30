import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routinePresetsProvider = FutureProvider<List<RoutinePreset>>(
  (ref) => RoutinePresets.load(),
);

class RoutinePreset {
  const RoutinePreset({
    required this.name,
    required this.description,
    required this.level,
    required this.items,
  });

  factory RoutinePreset.fromJson(Map<String, Object?> json) => RoutinePreset(
    name: json['name'] as String,
    description: json['description'] as String,
    level: json['level'] as String,
    items: (json['items'] as List<Object?>)
        .map((item) => RoutinePresetItem.fromJson(item as Map<String, Object?>))
        .toList(growable: false),
  );

  final String name;
  final String description;
  final String level;
  final List<RoutinePresetItem> items;
}

class RoutinePresetItem {
  const RoutinePresetItem({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
  });

  factory RoutinePresetItem.fromJson(Map<String, Object?> json) =>
      RoutinePresetItem(
        exerciseId: json['exerciseId'] as String,
        targetSets: json['targetSets'] as int,
        targetReps: json['targetReps'] as int,
        targetWeight: (json['targetWeight'] as num).toDouble(),
      );

  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
}

class RoutinePresets {
  const RoutinePresets._();

  static List<RoutinePreset>? _cache;

  static Future<List<RoutinePreset>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final decoded =
          jsonDecode(await rootBundle.loadString('assets/routine_presets.json'))
              as List<Object?>;
      return _cache = List<RoutinePreset>.unmodifiable(
        decoded.map(
          (item) => RoutinePreset.fromJson(item as Map<String, Object?>),
        ),
      );
    } on Object {
      return const <RoutinePreset>[];
    }
  }
}
