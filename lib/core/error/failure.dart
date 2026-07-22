sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'DB 오류']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = '찾을 수 없음']);
}
