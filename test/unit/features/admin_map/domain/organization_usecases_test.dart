import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/add_organization_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/delete_organization_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/update_organization_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import '../../../../../../test/test_utils/fakes.dart';

void main() {
  late FakeAdminMapRepository repository;

  setUp(() {
    repository = FakeAdminMapRepository();
  });

  group('AddOrganizationUseCase', () {
    test('should return Right when adding organization succeeds', () async {
      final useCase = AddOrganizationUseCase(repository);
      final params = AddOrganizationParams(
        name: 'Test Organization',
        description: 'A test organization',
      );

      final result = await useCase(params);

      expect(result, const Right(null));
    });
  });

  group('GetOrganizationsUseCase', () {
    test('should return Right with list of organizations', () async {
      final useCase = GetOrganizationsUseCase(repository);

      final result = await useCase(NoParams());

      expect(result.isRight(), isTrue);
    });
  });

  group('DeleteOrganizationUseCase', () {
    test('should return Right when deleting organization succeeds', () async {
      final useCase = DeleteOrganizationUseCase(repository);

      final result = await useCase('org-123');

      expect(result, const Right(null));
    });
  });

  group('UpdateOrganizationUseCase', () {
    test('should return Right when updating organization succeeds', () async {
      final useCase = UpdateOrganizationUseCase(repository);
      final params = UpdateOrganizationParams(
        'org-123',
        'Updated Name',
        'Updated Description',
      );

      final result = await useCase(params);

      expect(result, const Right(null));
    });
  });
}
