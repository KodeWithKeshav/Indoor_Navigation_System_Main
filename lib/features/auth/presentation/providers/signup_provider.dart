import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../features/admin_map/domain/entities/organization.dart';
import '../../../../features/admin_map/presentation/providers/admin_map_providers.dart';
import '../providers/auth_providers.dart';
import '../../domain/usecases/signup_usecase.dart';

// Provider to fetch list of organizations
final organizationListProvider = FutureProvider<List<Organization>>((ref) async {
  final getOrgsUseCase = ref.read(getOrganizationsUseCaseProvider);
  final result = await getOrgsUseCase(NoParams());
  return result.fold(
    (failure) => [],
    (orgs) => orgs,
  );
});

final signUpUseCaseProvider = Provider((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});
