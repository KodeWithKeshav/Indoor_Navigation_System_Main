import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';

class _EchoUseCase implements UseCase<String, String> {
  @override
  Future<Either<Failure, String>> call(String params) async {
    return Right(params);
  }
}

void main() {
  test('UseCase returns value', () async {
    final useCase = _EchoUseCase();
    final result = await useCase('hello');

    expect(result.getOrElse((_) => ''), 'hello');
  });

  test('NoParams is usable', () {
    final params = NoParams();
    expect(params, isA<NoParams>());
  });
}
