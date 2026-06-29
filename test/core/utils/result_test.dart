import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';

void main() {
  group('Result', () {
    test('success exposes value', () {
      const result = Result.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('failure exposes failure and null value', () {
      const Result<int> result = Result.failure(UnexpectedFailure('boom'));
      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
    });

    test('fold routes to the matching branch', () {
      const Result<int> ok = Result.success(2);
      const Result<int> bad = Result.failure(UnexpectedFailure('x'));
      expect(ok.fold((v) => v * 2, (f) => -1), 4);
      expect(bad.fold((v) => v * 2, (f) => -1), -1);
    });

    test('map transforms success and passes failure through', () {
      const Result<int> ok = Result.success(3);
      const Result<int> bad = Result.failure(UnexpectedFailure('x'));
      expect(ok.map((v) => 'v$v').valueOrNull, 'v3');
      expect(bad.map((v) => 'v$v').isSuccess, isFalse);
    });

    test('exhaustive switch works over the sealed type', () {
      const Result<int> result = Result.success(1);
      final label = switch (result) {
        Success<int>() => 'success',
        FailureResult<int>() => 'failure',
      };
      expect(label, 'success');
    });
  });
}
