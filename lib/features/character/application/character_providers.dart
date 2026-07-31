import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/character_identity.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../exercise_db/application/exercise_providers.dart';
import 'character_identity_controller.dart';

/// 마지막으로 사용자에게 보여 준 합산 레벨. 레벨업 축하를 한 번만 띄운다.
const String kSeenCharacterLevelKey = 'character_seen_level';

/// 부위별 누적 볼륨. 준비 세트는 통계와 같은 기준으로 제외한다.
/// 성향에 맞는 반복 구간의 세트는 보너스를 받는다.
final characterVolumesProvider = FutureProvider<Map<MuscleGroup, double>>(
  (ref) => _volumes(ref, since: null),
);

/// 최근 7일 볼륨. 지금 성장 중인지 보여주는 데 쓴다.
final characterWeeklyVolumesProvider = FutureProvider<Map<MuscleGroup, double>>(
  (ref) {
    final now = DateTime.now();
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    return _volumes(ref, since: since);
  },
);

/// 화면이 그대로 쓰는 성장 상태.
final characterGrowthProvider = FutureProvider<CharacterGrowth>((ref) async {
  final total = await ref.watch(characterVolumesProvider.future);
  final weekly = await ref.watch(characterWeeklyVolumesProvider.future);
  return calculateCharacterGrowth(total, weeklyVolumes: weekly);
});

/// 직전에 확인한 합산 레벨. 없으면 null.
final seenCharacterLevelProvider = FutureProvider<int?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(kSeenCharacterLevelKey);
});

/// 레벨업 축하를 본 것으로 표시한다.
Future<void> markCharacterLevelSeen(WidgetRef ref, int level) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kSeenCharacterLevelKey, level);
  ref.invalidate(seenCharacterLevelProvider);
}

Future<Map<MuscleGroup, double>> _volumes(Ref ref, {DateTime? since}) async {
  final identity = await ref.watch(characterIdentityProvider.future);
  final trait = identity?.trait ?? CharacterTrait.balanced;
  final database = ref.watch(appDatabaseProvider);
  final sets = await database.statsDao.allSets();
  final exercises = await database.statsDao.exercisesForIds(
    sets.map((set) => set.exerciseId),
  );
  final muscles = <String, MuscleGroup>{
    for (final exercise in exercises)
      exercise.id: MuscleGroup.values[exercise.muscleGroup],
  };
  final sessionStart = since == null
      ? const <String, DateTime>{}
      : <String, DateTime>{
          for (final session in await database.statsDao.sessionsSince(since))
            session.id: session.startedAt,
        };
  final volumes = <MuscleGroup, double>{};
  for (final set in sets) {
    // 준비 세트는 세션 볼륨 계산과 같은 기준으로 뺀다.
    if (!set.isCompleted || set.isWarmup || set.deletedAt != null) continue;
    final muscle = muscles[set.exerciseId];
    if (muscle == null) continue;
    if (since != null && !sessionStart.containsKey(set.sessionId)) continue;
    final gained = set.weight * set.reps * traitMultiplier(trait, set.reps);
    volumes.update(muscle, (volume) => volume + gained, ifAbsent: () => gained);
  }
  return volumes;
}
