import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';

void main() {
  test('getCurrentUser returns null when no user', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: false);
    final dataSource = AuthRemoteDataSourceImpl(firebaseAuth: auth, firestore: firestore);

    final user = await dataSource.getCurrentUser();
    expect(user, isNull);
  });

  test('getCurrentUser returns model from Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'u1@example.com'),
    );

    await firestore.collection('users').doc('u1').set({
      'email': 'u1@example.com',
      'role': 'admin',
      'organizationId': 'org1',
    });

    final dataSource = AuthRemoteDataSourceImpl(firebaseAuth: auth, firestore: firestore);
    final user = await dataSource.getCurrentUser();

    expect(user, isNotNull);
    expect(user!.role, UserRole.admin);
    expect(user.organizationId, 'org1');
  });
}
