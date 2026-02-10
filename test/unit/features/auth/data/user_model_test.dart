import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/auth/data/models/user_model.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';

void main() {
  test('UserModel fromJson and toJson round-trip', () {
    final model = UserModel.fromJson({
      'id': 'u1',
      'email': 'user@example.com',
      'role': 'admin',
      'organizationId': 'org1',
    });

    expect(model.id, 'u1');
    expect(model.email, 'user@example.com');
    expect(model.role, UserRole.admin);
    expect(model.organizationId, 'org1');

    final json = model.toJson();
    expect(json['role'], 'admin');
  });

  test('UserModel fromFirestore maps fields', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('users').doc('u2');
    await docRef.set({
      'email': 'u2@example.com',
      'role': 'user',
      'organizationId': 'org2',
    });

    final doc = await docRef.get();
    final model = UserModel.fromFirestore(doc);

    expect(model.id, 'u2');
    expect(model.role, UserRole.user);
    expect(model.organizationId, 'org2');
  });
}
