import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
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
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_campus_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/signup_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/manage_users_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/update_user_org_usecase.dart';
import '../test_utils/fakes.dart';

void main() {
  group('Failure Propagation Integration — Admin Map', () {
    late FakeAdminMapRepository repo;

    setUp(() {
      repo = FakeAdminMapRepository();
      repo.shouldFail = true;
      repo.failureMessage = 'Server error';
    });

    test('AddOrganizationUseCase propagates failure', () async {
      final result = await AddOrganizationUseCase(repo)(
        AddOrganizationParams(name: 'Name', description: 'Desc'),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('GetOrganizationsUseCase propagates failure', () async {
      final result = await GetOrganizationsUseCase(repo)(NoParams());
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('DeleteOrganizationUseCase propagates failure', () async {
      final result = await DeleteOrganizationUseCase(repo)('org-1');
      expect(result.isLeft(), isTrue);
    });

    test('UpdateOrganizationUseCase propagates failure', () async {
      final result = await UpdateOrganizationUseCase(repo)(
        UpdateOrganizationParams('org-1', 'Name', 'Desc'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('AddBuildingUseCase propagates failure', () async {
      final result = await AddBuildingUseCase(repo)(
        AddBuildingParams('Building', 'Desc'),
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f.message, 'Server error');
      }, (_) => fail('Should fail'));
    });

    test('GetBuildingsUseCase propagates failure', () async {
      final result = await GetBuildingsUseCase(repo)(GetBuildingsParams());
      expect(result.isLeft(), isTrue);
    });

    test('DeleteBuildingUseCase propagates failure', () async {
      final result = await DeleteBuildingUseCase(repo)('b-1');
      expect(result.isLeft(), isTrue);
    });

    test('UpdateBuildingUseCase propagates failure', () async {
      final result = await UpdateBuildingUseCase(repo)(
        UpdateBuildingParams('b-1', 'Name', 'Desc'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('AddFloorUseCase propagates failure', () async {
      final result = await AddFloorUseCase(repo)(AddFloorParams('b1', 1, 'F1'));
      expect(result.isLeft(), isTrue);
    });

    test('GetFloorsUseCase propagates failure', () async {
      final result = await GetFloorsUseCase(repo)('b1');
      expect(result.isLeft(), isTrue);
    });

    test('DeleteFloorUseCase propagates failure', () async {
      final result = await DeleteFloorUseCase(repo)(
        DeleteFloorParams('b1', 'f1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('UpdateFloorUseCase propagates failure', () async {
      final result = await UpdateFloorUseCase(repo)(
        UpdateFloorParams('b1', 'f1', 2, 'F2'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('AddRoomUseCase propagates failure', () async {
      final result = await AddRoomUseCase(repo)(
        AddRoomParams(
          buildingId: 'b1',
          floorId: 'f1',
          name: 'Room',
          x: 0,
          y: 0,
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('GetRoomsUseCase propagates failure as ValidationFailure', () async {
      final result = await GetRoomsUseCase(repo)(GetRoomsParams('b1', 'f1'));
      expect(result.isLeft(), isTrue);
      // FakeAdminMapRepository.getRooms returns ValidationFailure
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('DeleteRoomUseCase propagates failure', () async {
      final result = await DeleteRoomUseCase(repo)(
        DeleteRoomParams('b1', 'f1', 'r1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('UpdateRoomUseCase propagates failure', () async {
      final result = await UpdateRoomUseCase(repo)(
        UpdateRoomUseParams(buildingId: 'b1', floorId: 'f1', roomId: 'r1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('AddCorridorUseCase propagates failure', () async {
      final result = await AddCorridorUseCase(repo)(
        AddCorridorParams('b1', 'f1', 'r1', 'r2', 10),
      );
      expect(result.isLeft(), isTrue);
    });

    test('GetCorridorsUseCase propagates failure', () async {
      final result = await GetCorridorsUseCase(repo)(
        GetCorridorsParams('b1', 'f1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('AddCampusConnectionUseCase propagates failure', () async {
      final result = await AddCampusConnectionUseCase(repo)(
        AddCampusConnectionParams('b1', 'b2', 100),
      );
      expect(result.isLeft(), isTrue);
    });

    test('GetCampusConnectionsUseCase propagates failure', () async {
      final result = await GetCampusConnectionsUseCase(repo)(NoParams());
      expect(result.isLeft(), isTrue);
    });

    test('DeleteCampusConnectionUseCase propagates failure', () async {
      final result = await DeleteCampusConnectionUseCase(repo)('cc-1');
      expect(result.isLeft(), isTrue);
    });
  });

  group('Failure Propagation Integration — Auth', () {
    late FakeAuthRepository repo;

    setUp(() {
      repo = FakeAuthRepository();
      repo.shouldFail = true;
      repo.failureMessage = 'Auth server down';
    });

    test('LoginUseCase propagates failure', () async {
      final result = await LoginUseCase(repo)(
        LoginParams(email: 'a@b.com', password: 'pass'),
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f.message, 'Auth server down');
      }, (_) => fail('Should fail'));
    });

    test('SignUpUseCase propagates failure', () async {
      final result = await SignUpUseCase(repo)(
        SignUpParams(email: 'a@b.com', password: 'pass', organizationId: 'o1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('ManageUsersUseCase.getAllUsers propagates failure', () async {
      final result = await ManageUsersUseCase(repo).getAllUsers();
      expect(result.isLeft(), isTrue);
    });

    test('ManageUsersUseCase.updateUserRole propagates failure', () async {
      final result = await ManageUsersUseCase(
        repo,
      ).updateUserRole(uid: 'u1', role: 'admin');
      expect(result.isLeft(), isTrue);
    });

    test('UpdateUserOrgUseCase propagates failure', () async {
      final result = await UpdateUserOrgUseCase(repo)(
        const UpdateUserOrgParams(uid: 'u1', organizationId: 'o1'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('failure message is preserved through use case chain', () async {
      repo.failureMessage = 'Custom error 42';
      final result = await LoginUseCase(repo)(
        LoginParams(email: 'x@y.com', password: 'p'),
      );
      result.fold(
        (f) => expect(f.message, 'Custom error 42'),
        (_) => fail('Should fail'),
      );
    });
  });
}
