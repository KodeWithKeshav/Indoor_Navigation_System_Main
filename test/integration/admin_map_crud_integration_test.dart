import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/admin_map_usecases.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_buildings_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_floors_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/add_corridor_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_corridors_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/delete_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/update_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/add_organization_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/delete_organization_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/update_organization_usecase.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import '../test_utils/fakes.dart';

void main() {
  group('Admin Map CRUD Integration', () {
    late FakeAdminMapRepository repo;

    // Organization use cases
    late AddOrganizationUseCase addOrg;
    late GetOrganizationsUseCase getOrgs;
    late UpdateOrganizationUseCase updateOrg;
    late DeleteOrganizationUseCase deleteOrg;

    // Building use cases
    late AddBuildingUseCase addBuilding;
    late GetBuildingsUseCase getBuildings;
    late UpdateBuildingUseCase updateBuilding;
    late DeleteBuildingUseCase deleteBuilding;

    // Floor use cases
    late AddFloorUseCase addFloor;
    late GetFloorsUseCase getFloors;
    late UpdateFloorUseCase updateFloor;
    late DeleteFloorUseCase deleteFloor;

    // Room use cases
    late AddRoomUseCase addRoom;
    late GetRoomsUseCase getRooms;
    late UpdateRoomUseCase updateRoom;
    late DeleteRoomUseCase deleteRoom;

    // Corridor use cases
    late AddCorridorUseCase addCorridor;
    late GetCorridorsUseCase getCorridors;

    setUp(() {
      repo = FakeAdminMapRepository();

      addOrg = AddOrganizationUseCase(repo);
      getOrgs = GetOrganizationsUseCase(repo);
      updateOrg = UpdateOrganizationUseCase(repo);
      deleteOrg = DeleteOrganizationUseCase(repo);

      addBuilding = AddBuildingUseCase(repo);
      getBuildings = GetBuildingsUseCase(repo);
      updateBuilding = UpdateBuildingUseCase(repo);
      deleteBuilding = DeleteBuildingUseCase(repo);

      addFloor = AddFloorUseCase(repo);
      getFloors = GetFloorsUseCase(repo);
      updateFloor = UpdateFloorUseCase(repo);
      deleteFloor = DeleteFloorUseCase(repo);

      addRoom = AddRoomUseCase(repo);
      getRooms = GetRoomsUseCase(repo);
      updateRoom = UpdateRoomUseCase(repo);
      deleteRoom = DeleteRoomUseCase(repo);

      addCorridor = AddCorridorUseCase(repo);
      getCorridors = GetCorridorsUseCase(repo);
    });

    test(
      'full hierarchy: org → building → floor → room → corridor → retrieve all',
      () async {
        // 1. Add organization
        expect(
          await addOrg(
            AddOrganizationParams(name: 'MIT', description: 'University'),
          ),
          const Right(null),
        );

        // Verify org was created
        final orgsResult = await getOrgs(NoParams());
        expect(orgsResult.isRight(), isTrue);
        final orgs = orgsResult.getRight().getOrElse(() => []);
        expect(orgs.length, 1);
        expect(orgs.first.name, 'MIT');

        // 2. Add building under org
        expect(
          await addBuilding(
            AddBuildingParams(
              'Building A',
              'Main hall',
              organizationId: orgs.first.id,
            ),
          ),
          const Right(null),
        );

        final buildingsResult = await getBuildings(
          GetBuildingsParams(organizationId: orgs.first.id),
        );
        expect(buildingsResult.isRight(), isTrue);
        final buildings = buildingsResult.getRight().getOrElse(() => []);
        expect(buildings.length, 1);
        expect(buildings.first.name, 'Building A');

        // 3. Add floor to building
        final buildingId = buildings.first.id;
        expect(
          await addFloor(AddFloorParams(buildingId, 1, 'Ground Floor')),
          const Right(null),
        );

        final floorsResult = await getFloors(buildingId);
        expect(floorsResult.isRight(), isTrue);
        final floors = floorsResult.getRight().getOrElse(() => []);
        expect(floors.length, 1);
        expect(floors.first.name, 'Ground Floor');

        // 4. Add rooms to floor
        final floorId = floors.first.id;
        expect(
          await addRoom(
            AddRoomParams(
              buildingId: buildingId,
              floorId: floorId,
              name: 'Lobby',
              x: 0,
              y: 0,
              type: RoomType.hallway,
            ),
          ),
          const Right(null),
        );
        expect(
          await addRoom(
            AddRoomParams(
              buildingId: buildingId,
              floorId: floorId,
              name: 'Lab 101',
              x: 100,
              y: 0,
              type: RoomType.lab,
            ),
          ),
          const Right(null),
        );

        final roomsResult = await getRooms(GetRoomsParams(buildingId, floorId));
        expect(roomsResult.isRight(), isTrue);
        final rooms = roomsResult.getRight().getOrElse(() => []);
        expect(rooms.length, 2);
        expect(rooms.map((r) => r.name).toList(), ['Lobby', 'Lab 101']);

        // 5. Add corridor between rooms
        expect(
          await addCorridor(
            AddCorridorParams(
              buildingId,
              floorId,
              rooms[0].id,
              rooms[1].id,
              15.0,
            ),
          ),
          const Right(null),
        );

        final corridorsResult = await getCorridors(
          GetCorridorsParams(buildingId, floorId),
        );
        expect(corridorsResult.isRight(), isTrue);
        final corridors = corridorsResult.getRight().getOrElse(() => []);
        expect(corridors.length, 1);
        expect(corridors.first.distance, 15.0);
      },
    );

    test('update building and verify changes persist', () async {
      // Add and get building
      await addBuilding(AddBuildingParams('Old Name', 'Old Desc'));
      final buildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      final buildingId = buildings.first.id;

      // Update building
      expect(
        await updateBuilding(
          UpdateBuildingParams(buildingId, 'New Name', 'New Desc'),
        ),
        const Right(null),
      );

      // Verify update
      final updatedBuildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      expect(updatedBuildings.first.name, 'New Name');
      expect(updatedBuildings.first.description, 'New Desc');
    });

    test('update floor and verify changes persist', () async {
      await addBuilding(AddBuildingParams('B1', 'Desc'));
      final buildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      final buildingId = buildings.first.id;

      await addFloor(AddFloorParams(buildingId, 1, 'Floor 1'));
      final floors = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      final floorId = floors.first.id;

      // Update floor
      expect(
        await updateFloor(UpdateFloorParams(buildingId, floorId, 2, 'Floor 2')),
        const Right(null),
      );

      // Verify
      final updatedFloors = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      expect(updatedFloors.first.name, 'Floor 2');
      expect(updatedFloors.first.floorNumber, 2);
    });

    test('update room name and position', () async {
      await addBuilding(AddBuildingParams('B1', 'Desc'));
      final buildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      final buildingId = buildings.first.id;

      await addFloor(AddFloorParams(buildingId, 1, 'F1'));
      final floors = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      final floorId = floors.first.id;

      await addRoom(
        AddRoomParams(
          buildingId: buildingId,
          floorId: floorId,
          name: 'Old Room',
          x: 10,
          y: 20,
        ),
      );
      final rooms = (await getRooms(
        GetRoomsParams(buildingId, floorId),
      )).getRight().getOrElse(() => []);
      final roomId = rooms.first.id;

      // Update room
      expect(
        await updateRoom(
          UpdateRoomUseParams(
            buildingId: buildingId,
            floorId: floorId,
            roomId: roomId,
            name: 'New Room',
            x: 50,
            y: 60,
          ),
        ),
        const Right(null),
      );

      // Verify
      final updatedRooms = (await getRooms(
        GetRoomsParams(buildingId, floorId),
      )).getRight().getOrElse(() => []);
      expect(updatedRooms.first.name, 'New Room');
      expect(updatedRooms.first.x, 50);
      expect(updatedRooms.first.y, 60);
    });

    test('delete room and verify removal', () async {
      await addBuilding(AddBuildingParams('B1', 'D'));
      final buildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      final buildingId = buildings.first.id;

      await addFloor(AddFloorParams(buildingId, 1, 'F1'));
      final floors = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      final floorId = floors.first.id;

      await addRoom(
        AddRoomParams(
          buildingId: buildingId,
          floorId: floorId,
          name: 'Room X',
          x: 0,
          y: 0,
        ),
      );
      final rooms = (await getRooms(
        GetRoomsParams(buildingId, floorId),
      )).getRight().getOrElse(() => []);
      expect(rooms.length, 1);

      // Delete room
      expect(
        await deleteRoom(DeleteRoomParams(buildingId, floorId, rooms.first.id)),
        const Right(null),
      );

      // Verify deleted
      final afterDelete = (await getRooms(
        GetRoomsParams(buildingId, floorId),
      )).getRight().getOrElse(() => []);
      expect(afterDelete, isEmpty);
    });

    test('organization-scoped building filtering', () async {
      await addOrg(AddOrganizationParams(name: 'Org A', description: 'Desc A'));
      await addOrg(AddOrganizationParams(name: 'Org B', description: 'Desc B'));
      final orgs = (await getOrgs(NoParams())).getRight().getOrElse(() => []);

      // Add buildings to different orgs
      await addBuilding(
        AddBuildingParams('B-A1', 'Desc', organizationId: orgs[0].id),
      );
      await addBuilding(
        AddBuildingParams('B-B1', 'Desc', organizationId: orgs[1].id),
      );
      await addBuilding(
        AddBuildingParams('B-A2', 'Desc', organizationId: orgs[0].id),
      );

      // Filter by org A
      final orgABuildings = (await getBuildings(
        GetBuildingsParams(organizationId: orgs[0].id),
      )).getRight().getOrElse(() => []);
      expect(orgABuildings.length, 2);
      expect(orgABuildings.map((b) => b.name).toList(), ['B-A1', 'B-A2']);

      // Filter by org B
      final orgBBuildings = (await getBuildings(
        GetBuildingsParams(organizationId: orgs[1].id),
      )).getRight().getOrElse(() => []);
      expect(orgBBuildings.length, 1);
      expect(orgBBuildings.first.name, 'B-B1');

      // No filter — all buildings
      final allBuildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      expect(allBuildings.length, 3);
    });

    test('update and delete organization', () async {
      await addOrg(
        AddOrganizationParams(name: 'Original', description: 'Desc'),
      );
      final orgs = (await getOrgs(NoParams())).getRight().getOrElse(() => []);
      final orgId = orgs.first.id;

      // Update
      expect(
        await updateOrg(UpdateOrganizationParams(orgId, 'Updated', 'New Desc')),
        const Right(null),
      );
      final afterUpdate = (await getOrgs(
        NoParams(),
      )).getRight().getOrElse(() => []);
      expect(afterUpdate.first.name, 'Updated');

      // Delete
      expect(await deleteOrg(orgId), const Right(null));
      final afterDelete = (await getOrgs(
        NoParams(),
      )).getRight().getOrElse(() => []);
      expect(afterDelete, isEmpty);
    });

    test('delete floor and verify removal', () async {
      await addBuilding(AddBuildingParams('B1', 'D'));
      final buildings = (await getBuildings(
        GetBuildingsParams(),
      )).getRight().getOrElse(() => []);
      final buildingId = buildings.first.id;

      await addFloor(AddFloorParams(buildingId, 1, 'F1'));
      await addFloor(AddFloorParams(buildingId, 2, 'F2'));

      final floors = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      expect(floors.length, 2);

      // Delete first floor
      await deleteFloor(DeleteFloorParams(buildingId, floors.first.id));

      final afterDelete = (await getFloors(
        buildingId,
      )).getRight().getOrElse(() => []);
      expect(afterDelete.length, 1);
      expect(afterDelete.first.name, 'F2');
    });
  });
}
