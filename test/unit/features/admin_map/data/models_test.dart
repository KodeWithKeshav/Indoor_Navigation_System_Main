import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/data/models/organization_model.dart';
import 'package:indoor_navigation_system/features/admin_map/data/models/map_models.dart';
import 'package:indoor_navigation_system/features/admin_map/data/models/campus_models.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  test('OrganizationModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('organizations').doc('o1');
    await docRef.set({'name': 'Org', 'description': 'Desc'});

    final model = OrganizationModel.fromFirestore(await docRef.get());
    expect(model.id, 'o1');
    expect(model.name, 'Org');
  });

  test('BuildingModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('buildings').doc('b1');
    await docRef.set({'name': 'B', 'description': 'D', 'organizationId': 'o1'});

    final model = BuildingModel.fromFirestore(await docRef.get());
    expect(model.organizationId, 'o1');
  });

  test('FloorModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore
        .collection('buildings')
        .doc('b1')
        .collection('floors')
        .doc('f1');
    await docRef.set({'floorNumber': 2, 'name': 'F2'});

    final model = FloorModel.fromFirestore(await docRef.get(), 'b1');
    expect(model.floorNumber, 2);
    expect(model.buildingId, 'b1');
  });

  test('RoomModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('rooms').doc('r1');
    await docRef.set({
      'name': 'R',
      'x': 1,
      'y': 2,
      'type': 'lab',
      'connectorId': 'c1',
    });

    final model = RoomModel.fromFirestore(await docRef.get(), 'f1');
    expect(model.type, RoomType.lab);
    expect(model.connectorId, 'c1');
  });

  test('CorridorModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('corridors').doc('c1');
    await docRef.set({'startRoomId': 'r1', 'endRoomId': 'r2', 'distance': 3.5});

    final model = CorridorModel.fromFirestore(await docRef.get(), 'f1');
    expect(model.distance, 3.5);
    expect(model.floorId, 'f1');
  });

  test('CampusConnectionModel maps firestore data', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('campus_connections').doc('cc1');
    await docRef.set({
      'fromBuildingId': 'b1',
      'toBuildingId': 'b2',
      'distance': 50.0,
      'bidirectional': false,
    });

    final model = CampusConnectionModel.fromFirestore(await docRef.get());
    expect(model.bidirectional, isFalse);
  });
}
