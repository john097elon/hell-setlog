import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/exercise_guide.dart';

final exerciseGuideProvider = FutureProvider<Map<String, ExerciseGuide>>(
  (ref) => ExerciseGuideLoader.load(),
);

/// Loads bundled exercise guides without allowing malformed asset data to fail UI.
class ExerciseGuideLoader {
  const ExerciseGuideLoader._();

  static Map<String, ExerciseGuide>? _cache;

  static Future<Map<String, ExerciseGuide>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final decoded =
          jsonDecode(await rootBundle.loadString('assets/exercise_guide.json'))
              as List<Object?>;
      final guides = <String, ExerciseGuide>{};
      for (final item in decoded) {
        if (item is! Map<String, Object?>) continue;
        final guide = ExerciseGuide.fromJson(item);
        guides[guide.id] = guide;
      }
      return _cache = Map<String, ExerciseGuide>.unmodifiable(guides);
    } on Object {
      return const <String, ExerciseGuide>{};
    }
  }
}
