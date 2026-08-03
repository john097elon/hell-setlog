import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/discipline.dart';
import '../entities/exercise.dart';

/// 운동 종목 조회. 모든 반환은 Result로 감싸며 예외를 throw하지 않는다.
abstract class ExerciseRepository {
  /// 전체 종목.
  Future<Result<List<Exercise>, Failure>> getAll();

  /// 검색과 필터. 모든 인자가 null이면 getAll과 동일하다.
  Future<Result<List<Exercise>, Failure>> search({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  });

  /// id로 한 건을 찾는다.
  Future<Result<Exercise, Failure>> getById(String id);

  /// 사용자가 직접 만든 종목을 저장한다. 목록에 없는 운동을 담기 위한 길이다.
  Future<Result<Exercise, Failure>> createCustom({
    required String nameKo,
    required Discipline discipline,
    MuscleGroup muscleGroup = MuscleGroup.fullBody,
    Equipment equipment = Equipment.other,
  });

  /// 사용자가 만든 종목을 지운다. 기본 종목은 지울 수 없다.
  Future<Result<void, Failure>> deleteCustom(String id);
}
