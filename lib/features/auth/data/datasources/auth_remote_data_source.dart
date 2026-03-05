import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String organizationId,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Future<List<UserModel>> getAllUsers();

  Future<void> updateUserRole({required String uid, required String role});

  Future<void> updateUserOrganization({
    required String uid,
    required String organizationId,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw const FormatException('User not found');
    }

    // Fetch user role from Firestore
    final doc = await firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    } else {
      // Create a default user entry or return default
      // For now, return default user
      return UserModel(
        id: credential.user!.uid,
        email: email,
        role: UserRole.user,
      );
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String organizationId,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw const FormatException('User creation failed');
    }

    final newUser = UserModel(
      id: credential.user!.uid,
      email: email,
      role: UserRole.user,
      organizationId: organizationId,
    );

    await firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(newUser.toJson());

    return newUser;
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      role: UserRole.user,
    );
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await firestore.collection('users').doc(uid).update({'role': role});
  }

  @override
  Future<void> updateUserOrganization({
    required String uid,
    required String organizationId,
  }) async {
    await firestore.collection('users').doc(uid).update({
      'organizationId': organizationId,
    });
  }
}
