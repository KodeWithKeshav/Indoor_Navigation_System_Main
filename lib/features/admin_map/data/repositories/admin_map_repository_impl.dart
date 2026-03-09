import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/map_entities.dart';
import '../../domain/entities/campus_entities.dart';
import '../../domain/repositories/admin_map_repository.dart';
import '../models/map_models.dart';
import '../models/campus_models.dart';
import '../models/organization_model.dart';

class AdminMapRepositoryImpl implements AdminMapRepository {
  final FirebaseFirestore firestore;

  AdminMapRepositoryImpl(this.firestore);

  // Organizations
  @override
  Future<Either<Failure, void>> addOrganization(
    String name,
    String description,
  ) async {
    try {
      final docRef = firestore.collection('organizations').doc();
      final model = OrganizationModel(
        id: docRef.id,
        name: name,
        description: description,
      );
      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Organization>>> getOrganizations() async {
    try {
      final querySnapshot = await firestore.collection('organizations').get();
      final orgs = querySnapshot.docs
          .map((doc) => OrganizationModel.fromFirestore(doc))
          .toList();
      return Right(orgs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrganization(
    String organizationId,
  ) async {
    try {
      await firestore.collection('organizations').doc(organizationId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrganization(
    String organizationId,
    String name,
    String description,
  ) async {
    try {
      await firestore.collection('organizations').doc(organizationId).update({
        'name': name,
        'description': description,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Buildings
  @override
  Future<Either<Failure, void>> addBuilding(
    String name,
    String description,
    String? organizationId,
  ) async {
    try {
      final docRef = firestore.collection('buildings').doc();
      final model = BuildingModel(
        id: docRef.id,
        name: name,
        description: description,
        organizationId: organizationId,
      );
      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Building>>> getBuildings({
    String? organizationId,
  }) async {
    try {
      Query query = firestore.collection('buildings');

      if (organizationId != null) {
        query = query.where('organizationId', isEqualTo: organizationId);
      }

      final querySnapshot = await query.get();
      final buildings = querySnapshot.docs
          .map((doc) => BuildingModel.fromFirestore(doc))
          .toList();
      return Right(buildings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFloor(
    String buildingId,
    int floorNumber,
    String name,
  ) async {
    try {
      // Validate uniqueness of floor number in building
      final existing = await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .where('floorNumber', isEqualTo: floorNumber)
          .get();

      if (existing.docs.isNotEmpty) {
        return const Left(
          ValidationFailure('Floor number already exists in this building'),
        );
      }

      final docRef = firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc();

      final model = FloorModel(
        id: docRef.id,
        buildingId: buildingId,
        floorNumber: floorNumber,
        name: name,
      );

      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBuilding(String buildingId) async {
    try {
      await firestore.collection('buildings').doc(buildingId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBuilding(
    String buildingId,
    String name,
    String description,
  ) async {
    try {
      await firestore.collection('buildings').doc(buildingId).update({
        'name': name,
        'description': description,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Floor>>> getFloors(String buildingId) async {
    try {
      final querySnapshot = await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .orderBy('floorNumber')
          .get();

      final floors = querySnapshot.docs
          .map((doc) => FloorModel.fromFirestore(doc, buildingId))
          .toList();
      return Right(floors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFloor(
    String buildingId,
    String floorId,
  ) async {
    try {
      await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFloor(
    String buildingId,
    String floorId,
    int floorNumber,
    String name,
  ) async {
    try {
      await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .update({'floorNumber': floorNumber, 'name': name});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addRoom(
    String buildingId,
    String floorId,
    String name,
    double x,
    double y, {
    RoomType type = RoomType.room,
    String? connectorId,
    bool isClosed = false,
  }) async {
    try {
      final docRef = firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc();

      final model = RoomModel(
        id: docRef.id,
        floorId: floorId,
        name: name,
        x: x,
        y: y,
        type: type,
        connectorId: connectorId,
        isClosed: isClosed,
      );

      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRooms(
    String buildingId,
    String floorId,
  ) async {
    try {
      final querySnapshot = await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .get();

      final rooms = querySnapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc, floorId))
          .toList();
      return Right(rooms);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(
    String buildingId,
    String floorId,
    String roomId,
  ) async {
    try {
      await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCorridor(
    String buildingId,
    String floorId,
    String startRoomId,
    String endRoomId,
    double distance,
  ) async {
    try {
      final docRef = firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('corridors')
          .doc();

      final model = CorridorModel(
        id: docRef.id,
        floorId: floorId,
        startRoomId: startRoomId,
        endRoomId: endRoomId,
        distance: distance,
      );

      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Corridor>>> getCorridors(
    String buildingId,
    String floorId,
  ) async {
    try {
      final querySnapshot = await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('corridors')
          .get();

      final corridors = querySnapshot.docs
          .map((doc) => CorridorModel.fromFirestore(doc, floorId))
          .toList();
      return Right(corridors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRoom(
    String buildingId,
    String floorId,
    String roomId, {
    double? x,
    double? y,
    String? name,
    RoomType? type,
    String? connectorId,
    bool? isClosed,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (x != null) updates['x'] = x;
      if (y != null) updates['y'] = y;
      if (name != null) updates['name'] = name;
      if (type != null) updates['type'] = type.name;
      if (connectorId != null) updates['connectorId'] = connectorId;
      if (isClosed != null) updates['isClosed'] = isClosed;

      if (updates.isEmpty) return const Right(null);

      await firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId)
          .update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Campus Connections
  @override
  Future<Either<Failure, void>> addCampusConnection(
    String fromBuildingId,
    String toBuildingId,
    double distance,
  ) async {
    try {
      final docRef = firestore.collection('campus_connections').doc();
      final model = CampusConnectionModel(
        id: docRef.id,
        fromBuildingId: fromBuildingId,
        toBuildingId: toBuildingId,
        distance: distance,
        bidirectional: true,
      );
      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CampusConnection>>> getCampusConnections() async {
    try {
      final querySnapshot = await firestore
          .collection('campus_connections')
          .get();
      final connections = querySnapshot.docs
          .map((doc) => CampusConnectionModel.fromFirestore(doc))
          .toList();
      return Right(connections);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCampusConnection(
    String connectionId,
  ) async {
    try {
      await firestore
          .collection('campus_connections')
          .doc(connectionId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
