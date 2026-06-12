/// In-house result type (guide §6 — no external functional packages).
///
/// Repositories and use cases return `Result<T>` so failures are typed and
/// can never be silently ignored; exhaustive `switch` enforces handling.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;

  /// Returns the value or null — for call sites where absence is fine.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        FailureResult<T>() => null,
      };

  R fold<R>(R Function(T value) onSuccess, R Function(Failure f) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        FailureResult<T>(:final failure) => onFailure(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Result.success(transform(value)),
        FailureResult<T>(:final failure) => Result.failure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}

/// Base failure. Features extend this with their own (typically sealed)
/// subtypes — e.g. `LocationFailure` — so call sites can pattern-match.
abstract base class Failure {
  const Failure(this.message);

  /// Developer-facing description; user-facing text comes from l10n.
  final String message;
}

/// A failure that wraps an unexpected exception.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [this.cause]);

  final Object? cause;
}
