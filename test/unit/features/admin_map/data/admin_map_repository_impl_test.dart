import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/admin_map/data/repositories/admin_map_repository_impl.dart';

void main() {
  test('AdminMapRepositoryImpl adds and fetches organizations', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = AdminMapRepositoryImpl(firestore);

    final addResult = await repo.addOrganization('Org', 'Desc');
    expect(addResult, const Right(null));

    final getResult = await repo.getOrganizations();
    final orgs = getResult.getOrElse((_) => []);
    expect(orgs.length, 1);
    expect(orgs.first.name, 'Org');
  });

  test('AdminMapRepositoryImpl validates floor number uniqueness', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = AdminMapRepositoryImpl(firestore);

    final buildingId = 'b1';
    await firestore.collection('buildings').doc(buildingId).set({
      'name': 'B',
      'description': 'D',
    });

    final first = await repo.addFloor(buildingId, 1, 'F1');
    expect(first.isRight(), isTrue);

    final second = await repo.addFloor(buildingId, 1, 'F1-dup');
    expect(second.isLeft(), isTrue);
  });

  test('AdminMapRepositoryImpl updateRoom no-op returns Right', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = AdminMapRepositoryImpl(firestore);

    final result = await repo.updateRoom('b1', 'f1', 'r1');
    expect(result, const Right(null));
  });
}
