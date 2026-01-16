import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_map_repository_impl.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/services/graph_service.dart';
import '../../../../core/services/navigation_instruction_service.dart';
import '../../domain/usecases/manage_campus_usecase.dart';
import '../../domain/entities/map_entities.dart';
import '../../domain/repositories/admin_map_repository.dart';
import '../../domain/usecases/admin_map_usecases.dart';
import '../../domain/usecases/add_corridor_usecase.dart';
import '../../domain/usecases/update_room_usecase.dart';
import '../../domain/usecases/get_corridors_usecase.dart';
import '../../domain/usecases/delete_room_usecase.dart';
import '../../domain/usecases/manage_buildings_usecase.dart';
import '../../domain/usecases/manage_floors_usecase.dart';
import '../../domain/usecases/add_organization_usecase.dart';
import '../../domain/usecases/get_organizations_usecase.dart';
import '../../domain/usecases/delete_organization_usecase.dart';
import '../../domain/usecases/update_organization_usecase.dart';

// Repository
final adminMapRepositoryProvider = Provider<AdminMapRepository>((ref) {
  return AdminMapRepositoryImpl(ref.read(firestoreProvider));
});

// Services
final graphServiceProvider = Provider<GraphService>((ref) {
  final repo = ref.read(adminMapRepositoryProvider);
  return GraphService(repo);
});

final navigationInstructionServiceProvider = Provider((ref) => NavigationInstructionService());

// Use Cases - Organization
final addOrganizationUseCaseProvider = Provider((ref) => AddOrganizationUseCase(ref.read(adminMapRepositoryProvider)));
final getOrganizationsUseCaseProvider = Provider((ref) => GetOrganizationsUseCase(ref.read(adminMapRepositoryProvider)));
final deleteOrganizationUseCaseProvider = Provider((ref) => DeleteOrganizationUseCase(ref.read(adminMapRepositoryProvider)));
final updateOrganizationUseCaseProvider = Provider((ref) => UpdateOrganizationUseCase(ref.read(adminMapRepositoryProvider)));

// Use Cases - Campus
final addCampusConnectionUseCaseProvider = Provider((ref) => AddCampusConnectionUseCase(ref.read(adminMapRepositoryProvider)));
final getCampusConnectionsUseCaseProvider = Provider((ref) => GetCampusConnectionsUseCase(ref.read(adminMapRepositoryProvider)));
final deleteCampusConnectionUseCaseProvider = Provider((ref) => DeleteCampusConnectionUseCase(ref.read(adminMapRepositoryProvider)));

// Use Cases - Buildings
final addBuildingUseCaseProvider = Provider((ref) => AddBuildingUseCase(ref.read(adminMapRepositoryProvider)));
final getBuildingsUseCaseProvider = Provider<GetBuildingsUseCase>((ref) {
  return GetBuildingsUseCase(ref.read(adminMapRepositoryProvider));
});
final deleteBuildingUseCaseProvider = Provider((ref) => DeleteBuildingUseCase(ref.read(adminMapRepositoryProvider)));
final updateBuildingUseCaseProvider = Provider((ref) => UpdateBuildingUseCase(ref.read(adminMapRepositoryProvider)));

// Use Cases - Floors
final addFloorUseCaseProvider = Provider((ref) => AddFloorUseCase(ref.read(adminMapRepositoryProvider)));
final getFloorsUseCaseProvider = Provider((ref) => GetFloorsUseCase(ref.read(adminMapRepositoryProvider)));
final deleteFloorUseCaseProvider = Provider((ref) => DeleteFloorUseCase(ref.read(adminMapRepositoryProvider)));
final updateFloorUseCaseProvider = Provider((ref) => UpdateFloorUseCase(ref.read(adminMapRepositoryProvider)));

// Use Cases - Rooms/Corridors
final addRoomUseCaseProvider = Provider((ref) => AddRoomUseCase(ref.read(adminMapRepositoryProvider)));
final getRoomsUseCaseProvider = Provider((ref) => GetRoomsUseCase(ref.read(adminMapRepositoryProvider)));
final updateRoomUseCaseProvider = Provider((ref) => UpdateRoomUseCase(ref.read(adminMapRepositoryProvider)));
final addCorridorUseCaseProvider = Provider((ref) => AddCorridorUseCase(ref.read(adminMapRepositoryProvider)));
final getCorridorsUseCaseProvider = Provider((ref) => GetCorridorsUseCase(ref.read(adminMapRepositoryProvider)));
final deleteRoomUseCaseProvider = Provider((ref) => DeleteRoomUseCase(ref.read(adminMapRepositoryProvider)));


// Notifiers

// 1. Buildings List - Using FutureProvider.family
final buildingsProvider = FutureProvider.family<List<Building>, String?>((ref, organizationId) async {
    final getBuildingsUseCase = ref.read(getBuildingsUseCaseProvider);
    final result = await getBuildingsUseCase(GetBuildingsParams(organizationId: organizationId));
    return result.fold(
      (failure) => throw failure.message,
      (buildings) => buildings,
    );
});

// 2. Campus Connections
final campusConnectionsProvider = FutureProvider<List<CampusConnection>>((ref) async {
    final useCase = ref.read(getCampusConnectionsUseCaseProvider);
    final result = await useCase(NoParams());
    return result.fold(
      (failure) => throw failure.message,
      (connections) => connections,
    );
});
