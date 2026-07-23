import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/exercise.dart';
import '../entities/personal_record.dart';

abstract class StatsRepository {
  Future<Result<Map<DateTime, double>, Failure>> weeklyVolume({int days = 7});
  Future<Result<Map<MuscleGroup, double>, Failure>> bodyPartSplit({
    int days = 30,
  });
  Future<Result<List<PersonalRecord>, Failure>> personalRecords(
    String exerciseId,
  );
  Future<Result<List<PersonalRecord>, Failure>> updateRecordsForSession(
    String sessionId,
  );
}
