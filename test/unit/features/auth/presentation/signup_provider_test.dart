import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/organization.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/signup_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import '../../../../test_utils/fakes.dart';

class _FakeGetOrganizationsUseCase extends GetOrganizationsUseCase {
  _FakeGetOrganizationsUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, List<Organization>>> call(NoParams params) async {
    return Right([
      const Organization(id: 'o1', name: 'Org', description: 'Desc'),
    ]);
  }
}

void main() {
  test('organizationListProvider returns organizations', () async {
    final container = ProviderContainer(
      overrides: [
        getOrganizationsUseCaseProvider.overrideWithValue(
          _FakeGetOrganizationsUseCase(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final value = await container.read(organizationListProvider.future);
    expect(value.length, 1);
    expect(value.first.id, 'o1');
  });
}
