import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.organizationId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      role: _parseRole(data['role']),
      organizationId: data['organizationId'] ?? '',
    );
  }

  // For creating a user locally if needed later
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      organizationId: json['organizationId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'organizationId': organizationId,
    };
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.user; // Default to user
  }
}
