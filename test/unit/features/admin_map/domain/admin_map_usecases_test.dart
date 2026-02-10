import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/admin_map_usecases.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_buildings_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_floors_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/add_corridor_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_corridors_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/delete_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/update_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import '../../../../../../test/test_utils/fakes.dart';

void main() {
  test('Admin map usecases return Right from repository', () async {
    final repo = FakeAdminMapRepository();

    final addBuilding = AddBuildingUseCase(repo);
    final getBuildings = GetBuildingsUseCase(repo);
    final addFloor = AddFloorUseCase(repo);
    final addRoom = AddRoomUseCase(repo);
    final addCorridor = AddCorridorUseCase(repo);
    final getCorridors = GetCorridorsUseCase(repo);
    final deleteRoom = DeleteRoomUseCase(repo);
    final updateRoom = UpdateRoomUseCase(repo);
    final getOrgs = GetOrganizationsUseCase(repo);

    expect(await addBuilding(AddBuildingParams('n', 'd')), const Right(null));
    expect((await getBuildings(GetBuildingsParams())).isRight(), isTrue);
    expect(await addFloor(AddFloorParams('b1', 1, 'F1')), const Right(null));
    expect(await addRoom(AddRoomParams(buildingId: 'b1', floorId: 'f1', name: 'R', x: 0, y: 0)), const Right(null));
    expect(await addCorridor(AddCorridorParams('b1', 'f1', 'r1', 'r2', 1)), const Right(null));
    expect((await getCorridors(GetCorridorsParams('b1', 'f1'))).isRight(), isTrue);
    expect(await deleteRoom(DeleteRoomParams('b1', 'f1', 'r1')), const Right(null));
    expect(await updateRoom(UpdateRoomUseParams(buildingId: 'b1', floorId: 'f1', roomId: 'r1')), const Right(null));
    expect((await getOrgs(NoParams())).isRight(), isTrue);
  });
}
