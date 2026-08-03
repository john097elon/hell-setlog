import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/character_identity.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../../domain/usecases/calculate_effort.dart';
import '../../exercise_db/application/exercise_providers.dart';
import 'character_identity_controller.dart';

/// 마지막으로 사용자에게 보여 준 합산 레벨. 레벨업 축하를 한 번만 띄운다.
const String kSeenCharacterLevelKey = 'character_seen_level';

/// 마지막으로 사용자에게 보여 준 진화 단계.
const String kSeenCharacterEvolutionStageKey = 'character_seen_evolution_stage';

/// 종목별 누적 운동 점수. 준비 세트는 통계와 같은 기준으로 제외하고,
/// 성향에 맞는 기록은 보너스를 받는다.
final characterVolumesProvider = FutureProvider<Map<Discipline, double>>(
  (ref) => _effort(ref, since: null),
);

/// 최근 7일 점수. 지금 성장 중인지 보여주는 데 쓴다.
final characterWeeklyVolumesProvider = FutureProvider<Map<Discipline, double>>(
  (ref) => _effort(ref, since: _daysAgo(6)),
);

/// 최근 30일 점수. 요즘 무슨 운동을 하는지로 칭호를 정한다.
final characterRecentVolumesProvider = FutureProvider<Map<Discipline, double>>(
  (ref) => _effort(ref, since: _daysAgo(29)),
);

/// 화면이 그대로 쓰는 성장 상태.
final characterGrowthProvider = FutureProvider<CharacterGrowth>((ref) async {
  final total = await ref.watch(characterVolumesProvider.future);
  final weekly = await ref.watch(characterWeeklyVolumesProvider.future);
  final recent = await ref.watch(characterRecentVolumesProvider.future);
  return calculateCharacterGrowth(
    total,
    weeklyEffort: weekly,
    recentEffort: recent,
  );
});

DateTime _daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}

/// 직전에 확인한 합산 레벨. 없으면 null.
final seenCharacterLevelProvider = FutureProvider<int?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(kSeenCharacterLevelKey);
});

/// 직전에 확인한 진화 단계. 없으면 null이다.
final seenCharacterEvolutionStageProvider = FutureProvider<int?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(kSeenCharacterEvolutionStageKey);
});

/// 레벨업 축하를 본 것으로 표시한다.
Future<void> markCharacterLevelSeen(WidgetRef ref, int level) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kSeenCharacterLevelKey, level);
  ref.invalidate(seenCharacterLevelProvider);
}

/// 진화와 그 시점의 레벨을 함께 확인한 것으로 표시한다.
Future<void> markCharacterEvolutionSeen(
  WidgetRef ref, {
  required int stage,
  required int level,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kSeenCharacterEvolutionStageKey, stage);
  await prefs.setInt(kSeenCharacterLevelKey, level);
  ref
    ..invalidate(seenCharacterEvolutionStageProvider)
    ..invalidate(seenCharacterLevelProvider);
}

Future<Map<Discipline, double>> _effort(Ref ref, {DateTime? since}) async {
  final identity = await ref.watch(characterIdentityProvider.future);
  final trait = identity?.trait ?? CharacterTrait.balanced;
  final database = ref.watch(appDatabaseProvider);
  final sets = await database.statsDao.allSets();
  final exercises = await database.statsDao.exercisesForIds(
    sets.map((set) => set.exerciseId),
  );
  final disciplines = <String, Discipline>{
    for (final exercise in exercises)
      exercise.id: Discipline.values[exercise.discipline],
  };
  final sessionStart = since == null
      ? const <String, DateTime>{}
      : <String, DateTime>{
          for (final session in await database.statsDao.sessionsSince(since))
            session.id: session.startedAt,
        };
  final effort = <Discipline, double>{};
  for (final set in sets) {
    // 준비 세트는 세션 볼륨 계산과 같은 기준으로 뺀다.
    if (!set.isCompleted || set.isWarmup || set.deletedAt != null) continue;
    final discipline = disciplines[set.exerciseId];
    if (discipline == null) continue;
    if (since != null && !sessionStart.containsKey(set.sessionId)) continue;
    final gained =
        effortPoints(
          discipline: discipline,
          weightKg: set.weight,
          reps: set.reps,
          distanceMeters: set.distanceMeters,
          durationSeconds: set.durationSeconds,
          intensity: set.intensity,
        ) *
        traitMultiplier(trait, set.reps, discipline: discipline);
    if (gained <= 0) continue;
    effort.update(
      discipline,
      (value) => value + gained,
      ifAbsent: () => gained,
    );
  }
  return effort;
}
