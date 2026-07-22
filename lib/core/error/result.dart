sealed class Result<T, F> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  });

  bool get isOk;
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);

  final T value;

  @override
  bool get isOk => true;

  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  }) => ok(value);
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);

  final F failure;

  @override
  bool get isOk => false;

  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  }) => err(failure);
}
